---
hide:
  - toc
---

<style>
.quiz-q label:has(input:focus) { outline: 2px solid #2962ff; outline-offset: 2px; border-radius: 3px; }
.quiz-section .md-button:focus { outline: 2px solid #2962ff; outline-offset: 2px; }
</style>

# Quiz: guess the compiler behaviour

For each section, read the relevant part of the OpenACC specification and the test program, then guess
what **Cray Fortran 19.0.0** and **nvfortran 25.3-0** actually do.

Scoring: a correct guess is **+1**, an incorrect guess is **0**, but missing a
**🟡 Wrong result** (the program runs and silently gives a wrong answer) costs **−3**.

<div class="quiz-section" markdown>

## Pointers in structs

??? info "OpenACC 3.3 section 2.6.4"

    ```quote
    When a data object is copied to device memory, the values are copied exactly. If the data is a data
    structure that includes a pointer, or is just a pointer, the pointer value copied to device memory
    will be the host pointer value. If the pointer target object is also allocated in or copied to device
    memory, the pointer itself needs to be updated with the device address of the target object before
    dereferencing the pointer in device memory
    ```

<div class="quiz-q" data-cray="crash" data-nv="crash" data-spec="❌ Crash" markdown>

### `declare create`

```fortran
--8<-- "src/declare_create.f90"
```

<div class="quiz-answer" markdown>

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | ❌ Crash | Per spec — copying the container does not attach `values` | Compiler warning (`Variable "(?)" is used before it is defined`); memory access fault at runtime. |
| nvfortran 25.3-0 | ❌ Crash | Per spec — copying the container does not attach `values` | No warning; `CUDA_ERROR_ILLEGAL_ADDRESS` at runtime. |

</div>

</div>

<div class="quiz-q" data-cray="crash" data-nv="ok" data-spec="❌ Crash" markdown>

### `enter data`, local variable

```fortran
--8<-- "src/enter_data.f90"
```

<div class="quiz-answer" markdown>

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | ❌ Crash | Per spec — `values` is never attached | Memory access fault at runtime. |
| nvfortran 25.3-0 | ✅ OK | Not per spec — relies on a non-portable automatic deep copy | Prints `Success 4.000000 2.000000`. |

</div>

</div>

<div class="quiz-q" data-cray="crash" data-nv="wrong" data-spec="❌ Crash" markdown>

### `enter data`, module variable

```fortran
--8<-- "src/enter_data_module.f90"
```

<div class="quiz-answer" markdown>

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | ❌ Crash | Per spec — `values` is never attached | Memory access fault at runtime. |
| nvfortran 25.3-0 | 🟡 Wrong result | Not per spec — relies on a non-portable automatic deep copy | Prints `Success 4.000000 0.000000`; the second element should be `2.0`. The module variable case silently produces an incorrect value. |

</div>

</div>

<div class="quiz-q" data-cray="ok" data-nv="ok" data-spec="✅ OK" markdown>

### `enter data` for member

```fortran
--8<-- "src/enter_data_members.f90"
```

<div class="quiz-answer" markdown>

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | ✅ OK | Per spec — `values` is allocated, explicitly attached, and copied with `update device` | Prints `Success 4. 2.` (correct). |
| nvfortran 25.3-0 | ✅ OK | Per spec — `values` is allocated, explicitly attached, and copied with `update device` | Prints `Success 4.000000 2.000000` (correct). |

</div>

</div>

<div class="quiz-q" data-cray="crash" data-nv="ok" data-spec="❌ Crash" markdown>

### No data/declare

```fortran
--8<-- "src/type_with_allocatable.f90"
```

<div class="quiz-answer" markdown>

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | ❌ Crash | Per spec — `values` is never attached | No warning at compile time; memory access fault at runtime. |
| nvfortran 25.3-0 | ✅ OK | Not per spec — relies on a non-portable automatic deep copy | Prints `Success 4.000000 2.000000`. |

</div>

</div>

</div>

<div class="quiz-section" markdown>

## Characters in host routines

??? info "OpenACC 3.3 Glossary 6"
    
    ```quote
    Aggregate variables – a variable of any non-scalar datatype, including array or composite variables.
    In Fortran, this includes any variable with allocatable or pointer attribute and character variables.
    ```

<div class="quiz-q" data-cray="crash" data-nv="ok" data-spec="—" markdown>

### Characters in host routines

```fortran
--8<-- "src/characters_cray.f90"
```

<div class="quiz-answer" markdown>

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | ❌ Compile error | Not covered by spec | Characters are not supported at all in device subroutines; the `ftn-7066` error is shown below. |
| nvfortran 25.3-0 | ✅ OK | Not covered by spec | Compiles, runs and prints the message. |

</div>

</div>

</div>

<div class="quiz-section" markdown>

## Module variable aliasing

??? info "OpenACC 3.3, section 2.13"

    The associated region is the implicit region associated with the function, subroutine, or program in
    which the directive appears. If the directive appears in the declaration section of a Fortran module
    subprogram, for a Fortran common block, or in a C or C++ global or namespace scope, the associated
    region is the implicit region for the whole program

<div class="quiz-q" data-cray="wrong" data-nv="ok" data-spec="—" markdown>

### Module variable aliasing

```fortran
--8<-- "src/module_var_aliasing.f90"
```

<div class="quiz-answer" markdown>

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | 🟡 Wrong result | Spec ambiguous | Per HPE, the spec permits both variables to share one device location, so the reduction prints the "wrong" value. |
| nvfortran 25.3-0 | ✅ OK | Spec ambiguous | Treats the variables as separate device allocations, so the program succeeds. |

</div>

</div>

</div>

<div class="quiz-section" markdown>

## GPU-aware MPI

!!! info "OpenACC specification"

    GPU-aware MPI is outside the OpenACC specification.

<div class="quiz-q" data-cray="ok" data-nv="ok" data-spec="—" markdown>

### Without slicing

```fortran
--8<-- "src/gpu_aware_mpi.f90"
```

<div class="quiz-answer" markdown>

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | ✅ OK | Outside OpenACC spec | `MPICH_GPU_SUPPORT_ENABLED=1`; buffer is transferred correctly between ranks. |
| nvfortran 25.3-0 | ✅ OK | Outside OpenACC spec | OpenMPI 5.0.7; buffer is transferred correctly between ranks. |

</div>

</div>

<div class="quiz-q" data-cray="ok" data-nv="wrong" data-spec="—" markdown>

### With slicing

```fortran
--8<-- "src/gpu_aware_mpi_slicing.f90"
```

<div class="quiz-answer" markdown>

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | ✅ OK | Outside OpenACC spec | `MPICH_GPU_SUPPORT_ENABLED=1`; sliced buffer is transferred correctly. |
| nvfortran 25.3-0 | 🟡 Wrong result | Outside OpenACC spec | CUDA 12.8, OpenMPI 5.0.7; data mismatch on all 128 elements. |

</div>

</div>

</div>

<div class="quiz-section" markdown>

## Using `acc_is_present` on a scalar

??? info "OpenACC 3.3 section 3.2.25"

    ```quote
    Fortran:
    logical function acc_is_present(data_arg)
    logical function acc_is_present(data_arg, bytes)
    type(*), dimension(..) :: data_arg
    integer :: bytes
    ```

    ```quote
    The acc_is_present routine tests whether the specified host data is accessible from the current
    device. [...] In Fortran, two forms are supported. In the first, data_arg is a variable or
    contiguous array section. In the second, data_arg is a variable or array element and bytes is the
    length in bytes.
    ```

<div class="quiz-q" data-cray="ok" data-nv="crash" data-spec="✅ OK" markdown>

### `acc_is_present` on a scalar

```fortran
--8<-- "src/acc_is_present_scalar.f90"
```

<div class="quiz-answer" markdown>

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | ✅ OK | Per spec — a scalar is a valid argument | Compiles and runs; `acc_is_present` returns false, the `if` clause skips the `exit data delete`, and `OK` is printed. |
| nvfortran 25.3-0 | ❌ Compile error | Not per spec — rejects a valid scalar argument | The interface declares an array dummy argument instead of the assumed-rank `dimension(..)` required by the spec, so the scalar cannot be associated; the `NVFORTRAN-S-0189` error is shown below. |

</div>

</div>

</div>

<div class="quiz-section" markdown>

## Using `exit data delete` on absent data

??? info "OpenACC 3.3 section 2.7.11"

    ```quote
    For each var in var-list, if var is in shared memory, no action is taken; if var is not in shared
    memory, the delete clause behaves as follows:
    • If the dynamic reference counter for var is zero, no action is taken.
    • Otherwise, a detach action is performed if var is a pointer reference, and the dynamic
      reference counter is updated if var is not a null pointer:
      – On an exit data directive with a finalize clause, the dynamic reference counter is set to zero.
      – Otherwise, a present decrement action with the dynamic reference counter is performed.
    If both structured and dynamic reference counters are zero, a delete action is performed.
    ```

<div class="quiz-q" data-cray="crash" data-nv="crash" data-spec="✅ OK" markdown>

### Never present

```fortran
--8<-- "src/exit_data_not_present.f90"
```

<div class="quiz-answer" markdown>

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | ❌ Crash | Not per spec — should be a no-op | Runtime abort: `CRAY_ACC_ERROR - Variable not found in present table`; exits with code 1. |
| nvfortran 25.3-0 | ❌ Crash | Not per spec — should be a no-op | Segmentation fault in `__pgi_uacc_dataexitstart2`. nvfortran 24.9 behaves identically. |

</div>

</div>

<div class="quiz-q" data-cray="crash" data-nv="ok" data-spec="✅ OK" markdown>

### Twice

```fortran
--8<-- "src/exit_data_double.f90"
```

<div class="quiz-answer" markdown>

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | ❌ Crash | Not per spec — the second `delete` should be a no-op | First `delete` frees the data; the second aborts with `CRAY_ACC_ERROR - Variable not found in present table` at line 9. |
| nvfortran 25.3-0 | ✅ OK | Per spec — the second `delete` is correctly a no-op | Prints `OK`. |

</div>

</div>

</div>

<div class="quiz-section" markdown>

## Attaching and detaching pointers

??? info "OpenACC 3.3 section 2.6.8"

    ```quote
    Since multiple pointers can target the same address, each pointer in device memory is associated
    with an attachment counter per device. The attachment counter for a pointer is initialized to zero
    when the pointer is allocated in device memory. The attachment counter for a pointer is set to one
    whenever the pointer is attached to new target address, and incremented whenever an attach action
    for that pointer is performed for the same target address. The attachment counter is decremented
    whenever a detach action occurs for the pointer, and the pointer is detached when the attachment
    counter reaches zero.
    ```

??? info "OpenACC 3.3 section 2.7.2, Attach Action"

    ```quote
    If the attachment counter for var is nonzero and the pointer in device memory already points to the
    device copy of the data in var, the attachment counter for the pointer var is incremented. Otherwise,
    the pointer in device memory is attached to the device copy of the data by initiating an update for the
    pointer in device memory to point to the device copy of the data and setting the attachment counter
    for the pointer var to one.
    ```

??? info "OpenACC 3.3 section 2.7.2, Detach Action"

    ```quote
    If the pointer var is in shared memory or is not present in the current device memory, or if the
    attachment counter for var for the pointer is zero, no action is taken. Otherwise, the attachment
    counter for the pointer var is decremented.
    ```

<div class="quiz-q" data-cray="wrong" data-nv="ok" data-spec="✅ OK" markdown>

### Pointer re-attach after host reassociation

```fortran
--8<-- "src/attach_reassociate.f90"
```

<div class="quiz-answer" markdown>

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | 🟡 Wrong result | Not per spec — the second attach is silently skipped | Prints `Wrong result: 10*1`: the kernel reads the *old* target `a` through the stale device pointer. |
| nvfortran 25.3-0 | ✅ OK | Per spec — the device pointer is repointed to `b`'s device copy | Prints `OK`. |

</div>

</div>

<div class="quiz-q" data-cray="ok" data-nv="ok" data-spec="✅ OK" markdown>

### `detach` of never-attached pointer, then attach

```fortran
--8<-- "src/detach_not_attached.f90"
```

<div class="quiz-answer" markdown>

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | ✅ OK | Per spec in observable behaviour, but the counter bookkeeping deviates | The runtime performs a real detach action instead of a no-op: the trace shows `detach pointer (ref count -1)`. The subsequent attach still works (see below). |
| nvfortran 25.3-0 | ✅ OK | Per spec — the detach is a no-op and the attach succeeds | Prints `OK`. |

</div>

</div>

</div>

<div class="quiz-section" markdown>

## Reduction variables

??? info "OpenACC 3.3 section 2.5.15, Restrictions"

    ```quote
    • A var in a reduction clause must be a scalar variable name, an aggregate variable name,
      an array element, or a subarray (refer to Section 2.7.1).
    • If the reduction var is an array element or a subarray, accessing the elements of the array
      outside the specified index range results in unspecified behavior.
    • The reduction var may not be a member of a composite variable.
    • If the reduction var is a composite variable, each member of the composite variable must be
      a supported datatype for the reduction operation.
    ```

??? info "OpenACC 3.3 section 2.9.11"

    ```quote
    If the reduction var is an array or subarray, the reduction operation is logically equivalent to
    applying that reduction operation to each array element of the array or subarray individually. If the
    reduction var is a composite variable, the reduction operation is logically equivalent to applying that
    reduction operation to each member of the composite variable individually.
    ```

<div class="quiz-q" data-cray="crash" data-nv="crash" data-spec="❌ Compile error" markdown>

### Reduction on a composite member

```fortran
--8<-- "src/reduction_member.f90"
```

<div class="quiz-answer" markdown>

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | ❌ Compile error | Per spec — member reductions are invalid | `ftn-802`: "Variable subobjects are not allowed as arguments for this clause or directive." |
| nvfortran 25.3-0 | ❌ Compile error | Per spec — member reductions are invalid | `NVFORTRAN-S-0155-Reduction variable must be a scalar or array variable - total` |

</div>

</div>

<div class="quiz-q" data-cray="crash" data-nv="crash" data-spec="✅ OK" markdown>

### Reduction on a whole composite variable

```fortran
--8<-- "src/reduction_composite.f90"
```

<div class="quiz-answer" markdown>

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | ❌ Compile error | Not per spec — rejects a valid aggregate reduction var | `ftn-689`: "The operator "+" has not been declared as a user defined reduction." The message suggests Cray only supports derived-type reductions through a user-declared reduction, not the implicit member-wise semantics the specification requires. |
| nvfortran 25.3-0 | ❌ Compile error | Not per spec — rejects a valid aggregate reduction var | `NVFORTRAN-S-0155-Reduction variable must be of intrinsic type - s` |

</div>

</div>

<div class="quiz-q" data-cray="crash" data-nv="ok" data-spec="✅ OK" markdown>

### Reduction on an array element

```fortran
--8<-- "src/reduction_array_element.f90"
```

<div class="quiz-answer" markdown>

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | ❌ Compile error | Not per spec — rejects a valid array-element reduction var | `ftn-802`: "Variable subobjects are not allowed as arguments for this clause or directive." — the same blanket subobject ban that (correctly) rejects the member case above, here over-restricting a valid form. |
| nvfortran 25.3-0 | ✅ OK | Per spec | The compile log shows the element being handled as the subarray `a(:1)` (`Generating reduction(+:a(:1))`); the program runs and prints `OK`. |

</div>

</div>

</div>
