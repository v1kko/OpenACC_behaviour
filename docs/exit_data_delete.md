# `exit data delete` on data that is not present

A common pattern is to tear down device data with `!$acc exit data delete(var)`. But what should
happen if `var` is **not present** on the device at the point of the `delete` — either because it
was never copied in, or because a previous `delete` already removed it?

The OpenACC 3.3 specification answers this in the definition of the
[`delete` clause (section 2.7.11)](https://www.openacc.org/sites/default/files/inline-images/Specification/OpenACC-3.3-final.pdf):

???+ info "OpenACC 3.3 section 2.7.11"

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

If `var` was never placed on the device, its dynamic reference counter is **zero**, so the rule is
explicit: **"no action is taken."** The `delete` is a silent no-op. This is reinforced by the
*Delete Action* definition, which states *"A delete action for a var occurs only when var is present
in device memory."*

The data clause errors in section 2.7.3 confirm that there is **no not-present error** for `delete`:
`acc_error_not_present` is only issued for a var in a `present` clause, never for `delete`. So per
the specification, both programs below should run to completion and print `OK`.

## `exit data delete` on never-present data

Here `host_mem` is never copied to the device, yet it is immediately deleted:

???+ note "Code"

    ```fortran
    --8<-- "src/exit_data_not_present.f90"
    ```

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | ❌ Crash | Not per spec — should be a no-op | Runtime abort: `CRAY_ACC_ERROR - Variable not found in present table`; exits with code 1. |
| nvfortran 25.3-0 | ❌ Crash | Not per spec — should be a no-op | Segmentation fault in `__pgi_uacc_dataexitstart2`. nvfortran 24.9 behaves identically. |

The Cray runtime error:

???+ note "Error"

    ```
    ACC:            find_in_present_table failed for 'host_mem' (...) from exit_data_not_present.f90:7
    ACC: libcrayacc/acc_runtime.c:890 CRAY_ACC_ERROR - Variable not found in present table
    ```

## Double `exit data delete`

Here `host_mem` is copied in once, then deleted **twice**. The first `delete` brings the dynamic
reference counter to zero and frees the device copy; the second `delete` then sees a reference
counter of zero and should take no action:

???+ note "Code"

    ```fortran
    --8<-- "src/exit_data_double.f90"
    ```

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | ❌ Crash | Not per spec — the second `delete` should be a no-op | First `delete` frees the data; the second aborts with `CRAY_ACC_ERROR - Variable not found in present table` at line 9. |
| nvfortran 25.3-0 | ✅ OK | Per spec — the second `delete` is correctly a no-op | Prints `OK`. |

Note the inconsistency: nvfortran tolerates deleting an already-deleted variable (where it was present
at least once), but crashes when the variable was *never* present. Cray aborts whenever a `delete`
targets a variable that is absent from the present table, in either scenario.
