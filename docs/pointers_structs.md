# Type with allocatables

Types with allocatables are handled differently by compilers when using OpenACC. In C this would be equivalent to a struct with a pointer inside. According to the OpenACC specification it should not be possbile to write a type with allocatables to the gpu in one go. However, we noticed that it worked sometimes and thus we have listed the differences here

???+ info "OpenACC 3.3 section 2.6.4"

    ```quote
    When a data object is copied to device memory, the values are copied exactly. If the data is a data
    structure that includes a pointer, or is just a pointer, the pointer value copied to device memory
    will be the host pointer value. If the pointer target object is also allocated in or copied to device
    memory, the pointer itself needs to be updated with the device address of the target object before
    dereferencing the pointer in device memory
    ```


## Container with "declare create"

??? note "Code"

    ```fortran
    program main
      implicit none
      type container_type
          real, dimension(:), allocatable :: values
      end type
      real, dimension(:) :: host_mem(2) = (/4,2/), res(2)
      integer :: i

      type(container_type) :: container
      !$acc declare create(container)

      allocate(container%values(2))
      container%values = host_mem

      write(*,*) "Checking if allocatable values are copied to device after declare create ..."
      !$acc parallel loop 
      do i=1,2 
        res(i) = container%values(i)
      enddo
      write(*,*) "Success", res
    end program
    ```

**Cray**

Gives a compiler warning and crashes at runtime

**Nvidia**

Gives no warning, crashes at runtime

## Container with "enter data"

??? note "Code with local variable"

    ```fortran
    program main
      implicit none
      type container_type
          real, dimension(:), allocatable :: values
      end type
      real, dimension(:) :: host_mem(2) = (/4,2/), res(2)
      integer :: i

      type(container_type) :: container
      !$acc enter data create(container)

      allocate(container%values(2))
      container%values = host_mem

      write(*,*) "Checking if allocatable values are copied to device after enter data create ..."
      !$acc parallel loop 
      do i=1,2 
        res(i) = container%values(i)
      enddo
      write(*,*) "Success", res
    end program
    ```

??? note "Code with module variable"
    
    ```fortran
    module static
      type container_type
          real, dimension(:), allocatable :: values
      end type

      type(container_type) :: container
    end module

    program main
      use static, only: container
      implicit none

      real, dimension(:) :: host_mem(2) = (/4,2/), res(2)
      integer :: i

      !$acc enter data create(container)

      allocate(container%values(2))
      container%values = host_mem

      write(*,*) "Checking if allocatable values are copied to device after enter data create of a module variable ..."
      !$acc parallel loop
      do i=1,2
        res(i) = container%values(i)
      enddo
      write(*,*) "Success", res
    end program
    ```

??? note "Code with enter data for member variable"

    ```fortran
    program main
      implicit none
      type container_type
          real, dimension(:), allocatable :: values
      end type

      real, dimension(:) :: host_mem(2) = (/4,2/), res(2)
      integer :: i

      type(container_type) :: container
      !$acc enter data create(container)
      !$acc enter data create(container%values)

      allocate(container%values(2))
      container%values = host_mem

      write(*,*) "Checking if allocatable values are copied to device after enter data create ..."
      !$acc parallel loop
      do i=1,2
        res(i) = container%values(i)
      enddo
      write(*,*) "Success", res
    end program
    ```

**Cray** 

All programgs crash at runtime (Memory access fault)

**Nvidia**

Code works and gives the correct result

## Container with no data/declare statement

??? note "Code"

    ``` fortran
    program main
      implicit none
      type pointer_type
          real, dimension(:), allocatable :: values
      end type
      real, dimension(:) :: host_mem(2) = (/4,2/), res(2)
      integer :: i
      type(pointer_type) :: indirect
      allocate(indirect%values(2))

      indirect%values = host_mem

      write(*,*) "Checking if allocatable values are copied to device with !$acc parallel loop ..."
      !$acc parallel loop
      do i=1,2 
        res(i) = indirect%values(i)
      enddo
      write(*,*) "Success", res

    end program
    ```

**Cray**

Does not give a warning, crashes at runtime

**Nvidia**

Code works and gives the correct result
