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
  
