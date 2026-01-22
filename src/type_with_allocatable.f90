program main

  implicit none
  type pointer_type
      real, dimension(:), allocatable :: values
  end type

  real, dimension(:) :: host_mem(2) = (/4,2/), res(2)
  integer :: i
  type(pointer_type) :: indirect

  indirect%values = host_mem

  write(*,*) "Checking if allocatable values are copied to device with !$acc parallel loop ..."
  !$acc parallel loop
  do i=1,2 
    res(i) = indirect%values(i)
  enddo
  write(*,*) "Success", res

end program
  
