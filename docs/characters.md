Writing and characters in OpenACC subroutines
==============================

Characters are an aggregate variable according to the OpenACC specification

???+ info "OpenACC 3.3 Glossary 6"
    
    ```quote
    Aggregate variables – a variable of any non-scalar datatype, including array or composite variables.
    In Fortran, this includes any variable with allocatable or pointer attribute and character variables.
    ```

Writing while in a device subroutine is not covered in OpenACC. However, there are 
differences between the compilers, we tested everything with the following program


???+ note "Code"

    ```fortran
    program main
      implicit none
      character(len=12) :: message = "Success"
      write(*,*) "Checking if characters can be printed in acc nohost subroutine ..."
      call write_message(message)

    contains
      subroutine write_message(message)
        !$acc routine seq
        implicit none
        character(len=12), intent(in) :: message
        character(len=14) :: new_message
        new_message = message(1:7) // "!"
        write(*,*)new_message
      end subroutine
    end program
    ```

**Nvidia**

Compiles, runs and prints the message

**Cray**

Doesn't compile, characters are not supported at all in device subroutines.
The following error is printed:


???+ note "Code"

    ```
        new_message = message(1:7) // "!"
    ftn-7066 ftn: ERROR WRITE_MESSAGE, File = characters_cray.f90, Line = 13
      Unsupported accelerator code error: Fortran character

        write(*,*)new_message
    ftn-7066 ftn: ERROR WRITE_MESSAGE, File = characters_cray.f90, Line = 14
      Unsupported accelerator code error: Fortran character -- new_message
    ```
