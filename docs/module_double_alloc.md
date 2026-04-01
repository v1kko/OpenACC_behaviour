# Module variable aliasing

Suppose you have two (or more) modules, in which you have variables that have a similar name and that should be used on the device, should these two variable point to the same memory location?

```fortran
module one
  integer :: a(:)
  !$acc declare create(a)
end module
module two
  integer :: a(:)
  !$acc declare create(a)
end module
```
To test this we have written the following program, which does a simple reduction for both variables.

```fortran
--8<-- "src/module_var_aliasing.f90"
```

The OpenACC specification is ambiguous on this and states in section 2.13 (OpenACC 3.3):

!!! info "OpenACC 3.3, section 2.13"

    The associated region is the implicit region associated with the function, subroutine, or program in
    which the directive appears. If the directive appears in the declaration section of a Fortran module
    subprogram, for a Fortran common block, or in a C or C++ global or namespace scope, the associated
    region is the implicit region for the whole program

## Compiler behaviour

**Cray compiler**

According to HPE (Cray compiler) it is allowed according the specification to let these variables point to the same location in device memory. Therefore our example program does not succeed

**Nvidia**

Nvidia treats these variables as separate in device memory. Therefore our example program succeeds.


