# Reduction variables: members, composites, and array elements

What is a `reduction` variable allowed to be? Most code reduces into a plain scalar, but the
[OpenACC 3.3 specification](https://www.openacc.org/sites/default/files/inline-images/Specification/OpenACC-3.3-final.pdf)
permits more than that — and explicitly forbids one form that looks natural. The restrictions in
section 2.5.15 are:

???+ info "OpenACC 3.3 section 2.5.15, Restrictions"

    ```quote
    • A var in a reduction clause must be a scalar variable name, an aggregate variable name,
      an array element, or a subarray (refer to Section 2.7.1).
    • If the reduction var is an array element or a subarray, accessing the elements of the array
      outside the specified index range results in unspecified behavior.
    • The reduction var may not be a member of a composite variable.
    • If the reduction var is a composite variable, each member of the composite variable must be
      a supported datatype for the reduction operation.
    ```

So a *whole* derived-type variable and an array element are valid reduction vars, while a *member*
of a derived-type variable is not. For aggregates the semantics are member-wise/element-wise
(section 2.9.11):

???+ info "OpenACC 3.3 section 2.9.11"

    ```quote
    If the reduction var is an array or subarray, the reduction operation is logically equivalent to
    applying that reduction operation to each array element of the array or subarray individually. If the
    reduction var is a composite variable, the reduction operation is logically equivalent to applying that
    reduction operation to each member of the composite variable individually.
    ```

We tested all three forms. In the tables below, the **Correctness** column states whether each
compiler's observed behaviour conforms to the OpenACC specification.

## Reduction on a member of a composite variable

`reduction(+:s%total)` is **invalid** per the specification ("The reduction var may not be a member
of a composite variable"), so a compile-time diagnostic is the expected outcome:

???+ note "Code"

    ```fortran
    --8<-- "src/reduction_member.f90"
    ```

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | ❌ Compile error | Per spec — member reductions are invalid | `ftn-802`: "Variable subobjects are not allowed as arguments for this clause or directive." |
| nvfortran 25.3-0 | ❌ Compile error | Per spec — member reductions are invalid | `NVFORTRAN-S-0155-Reduction variable must be a scalar or array variable - total` |

## Reduction on a whole composite variable

`reduction(+:s)`, where `s` is a derived-type variable with two integer members, is **valid** per
the specification: the reduction applies to each member individually, so the program should compile
and print `OK`:

???+ note "Code"

    ```fortran
    --8<-- "src/reduction_composite.f90"
    ```

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | ❌ Compile error | Not per spec — rejects a valid aggregate reduction var | `ftn-689`: "The operator "+" has not been declared as a user defined reduction." The message suggests Cray only supports derived-type reductions through a user-declared reduction, not the implicit member-wise semantics the specification requires. |
| nvfortran 25.3-0 | ❌ Compile error | Not per spec — rejects a valid aggregate reduction var | `NVFORTRAN-S-0155-Reduction variable must be of intrinsic type - s` |

This is a rare case where both compilers agree with each other *against* the specification: neither
implements member-wise reductions on derived-type variables.

## Reduction on an array element

`reduction(+:a(1))` is also **valid** per the specification (an "array element"), with the
restriction that the loop must not touch elements outside the specified index range — which the
program below respects. It should compile and print `OK`:

???+ note "Code"

    ```fortran
    --8<-- "src/reduction_array_element.f90"
    ```

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | ❌ Compile error | Not per spec — rejects a valid array-element reduction var | `ftn-802`: "Variable subobjects are not allowed as arguments for this clause or directive." — the same blanket subobject ban that (correctly) rejects the member case above, here over-restricting a valid form. |
| nvfortran 25.3-0 | ✅ OK | Per spec | The compile log shows the element being handled as the subarray `a(:1)` (`Generating reduction(+:a(:1))`); the program runs and prints `OK`. |
