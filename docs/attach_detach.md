# Attaching and detaching pointers

When a derived type with a Fortran `pointer` member is present on the device, the device copy of
the pointer member must be made to point at the *device* copy of its target before it can be
dereferenced in a kernel. OpenACC manages this with **attach** and **detach** actions, governed by
an *attachment counter* per pointer, as defined in the
[OpenACC 3.3 specification](https://www.openacc.org/sites/default/files/inline-images/Specification/OpenACC-3.3-final.pdf):

???+ info "OpenACC 3.3 section 2.6.8"

    ```quote
    Since multiple pointers can target the same address, each pointer in device memory is associated
    with an attachment counter per device. The attachment counter for a pointer is initialized to zero
    when the pointer is allocated in device memory. The attachment counter for a pointer is set to one
    whenever the pointer is attached to new target address, and incremented whenever an attach action
    for that pointer is performed for the same target address. The attachment counter is decremented
    whenever a detach action occurs for the pointer, and the pointer is detached when the attachment
    counter reaches zero.
    ```

In the tables below, the **Correctness** column states whether each compiler's observed behaviour
conforms to the OpenACC specification.

## Re-attaching a pointer after host reassociation

A common pattern in real applications is to swap the buffer a container points to: the host
pointer is reassociated to a new target, and the pointer is attached again. The *Attach Action*
(section 2.7.2) is explicit that a second attach may only increment the counter when the device
pointer **already points to the right target** — otherwise it must repoint the device pointer:

???+ info "OpenACC 3.3 section 2.7.2, Attach Action"

    ```quote
    If the attachment counter for var is nonzero and the pointer in device memory already points to the
    device copy of the data in var, the attachment counter for the pointer var is incremented. Otherwise,
    the pointer in device memory is attached to the device copy of the data by initiating an update for the
    pointer in device memory to point to the device copy of the data and setting the attachment counter
    for the pointer var to one.
    ```

In the program below, `c%p` is first attached to target `a` (all ones), then reassociated to `b`
(all twos) and attached again. Per the specification the kernel must read `b` through `c%p` and
print `OK`:

???+ note "Code"

    ```fortran
    --8<-- "src/attach_reassociate.f90"
    ```

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | 🟡 Wrong result | Not per spec — the second attach is silently skipped | Prints `Wrong result: 10*1`: the kernel reads the *old* target `a` through the stale device pointer. |
| nvfortran 25.3-0 | ✅ OK | Per spec — the device pointer is repointed to `b`'s device copy | Prints `OK`. |

### Why Cray gets this wrong

The Cray runtime trace (`CRAY_ACC_DEBUG=3`) shows both attach operations. The first attach updates
the device pointer and copies the container to the device:

???+ note "Cray trace, first attach"

    ```
    ACC:   attach pointer host 0x407350 (pointee 0x50fb80) to device 14fee6a00000 (pointee 14fee6a01000) for 'c%p'
    ACC:     internal copy host to acc (host 12b52d0 to acc 14fee6a00000) size = 72
    ```

The second attach — after `c%p => b` — is recognised but **skipped**, even though the trace itself
prints the new pointee (`14fee6a02000`, the device copy of `b`) that the device pointer should have
been updated to. No copy to the device follows:

???+ note "Cray trace, second attach"

    ```
    ACC:   already attached pointer host 0x407350 (pointee 0x50fc00) to device 14fee6a00000 (pointee 14fee6a02000) for 'c%p'
    ```

So the Cray runtime decides "already attached" from the attachment counter alone: counter is
nonzero, therefore skip. The specification instead requires *both* conditions — counter nonzero
**and** "the pointer in device memory already points to the device copy of the data" — before the
update may be skipped. Cray never compares the device pointer's current target with the new one,
so the device copy of `c%p` keeps pointing at `a`'s device allocation and the kernel silently
reads stale data.

The [test below](#detach-on-a-never-attached-pointer) corroborates this model from the other side:
when the attachment counter is *not* positive, Cray does perform a full, correct attach. The bug
is therefore precisely the missing target comparison in the counter-positive path.

## `detach` on a never-attached pointer

What happens when a pointer that was never attached is detached? The *Detach Action*
(section 2.7.2) requires this to be a silent no-op:

???+ info "OpenACC 3.3 section 2.7.2, Detach Action"

    ```quote
    If the pointer var is in shared memory or is not present in the current device memory, or if the
    attachment counter for var for the pointer is zero, no action is taken. Otherwise, the attachment
    counter for the pointer var is decremented.
    ```

The program below detaches a nullified, never-attached pointer member, and then performs a real
attach to check that the spurious detach has not corrupted the pointer's bookkeeping. Per the
specification it should print `OK`:

???+ note "Code"

    ```fortran
    --8<-- "src/detach_not_attached.f90"
    ```

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | ✅ OK | Per spec in observable behaviour, but the counter bookkeeping deviates | The runtime performs a real detach action instead of a no-op: the trace shows `detach pointer (ref count -1)`. The subsequent attach still works (see below). |
| nvfortran 25.3-0 | ✅ OK | Per spec — the detach is a no-op and the attach succeeds | Prints `OK`. |

The Cray trace shows the detach decrementing the attachment counter to **-1** instead of taking no
action:

???+ note "Cray trace, spurious detach followed by attach"

    ```
    ACC:   detach pointer (ref count -1) host 0x407308 to device 14ea29800000 for 'c%p'
    ...
    ACC:   attach pointer host 0x407308 (pointee 0x50fb80) to device 14ea29800000 (pointee 14ea29801000) for 'c%p'
    ```

The end result is still correct, but only by virtue of the bug described
[above](#why-cray-gets-this-wrong): because Cray's attach treats any non-positive counter as "not
attached", the -1 counter still takes the full-attach path. The two deviations cancel out here;
programs that mix spurious detaches with genuine re-attachments should not rely on that.
