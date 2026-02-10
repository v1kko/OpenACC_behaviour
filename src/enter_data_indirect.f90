program main
  use openacc
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
  
