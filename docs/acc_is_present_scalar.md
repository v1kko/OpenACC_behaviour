# Using `acc_is_present` on a scalar

The runtime routine `acc_is_present` is commonly used to guard data clauses so that a region is
only deleted (or copied) when it is actually present on the device. A natural question is whether
its argument may be a plain scalar variable, or whether it has to be an array (section).

According to the OpenACC 3.3 specification, the Fortran interface for `acc_is_present` declares its
argument as an **assumed-rank** dummy (`dimension(..)`), and the description states that it may be
"a variable":

???+ info "OpenACC 3.3 section 3.2.25"

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

In Fortran an assumed-rank dummy argument (`dimension(..)`) may be associated with an actual
argument of any rank, **including a scalar** (rank 0). Combined with the wording "data_arg is a
variable", this means a scalar argument is conformant: the program below should compile, and
`acc_is_present` should simply return `.false.` (the scalar was never placed on the device), so the
guarded `exit data delete` does nothing and the program prints `OK`.

We tested this with the following program:

???+ note "Code"

    ```fortran
    --8<-- "src/acc_is_present_scalar.f90"
    ```

## Compiler behaviour

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | ✅ OK | Per spec — a scalar is a valid argument | Compiles and runs; `acc_is_present` returns false, the `if` clause skips the `exit data delete`, and `OK` is printed. |
| nvfortran 25.3-0 | ❌ Compile error | Not per spec — rejects a valid scalar argument | The interface declares an array dummy argument instead of the assumed-rank `dimension(..)` required by the spec, so the scalar cannot be associated; the `NVFORTRAN-S-0189` error is shown below. |

The nvfortran compile error:

???+ note "Error"

    ```
    NVFORTRAN-S-0189-Argument number 1 to pgf90_acc_is_present_i8_: association of scalar actual argument to array dummy argument (acc_is_present_scalar.f90: 10)
      0 inform,   0 warnings,   1 severes, 0 fatal for main
    ```
