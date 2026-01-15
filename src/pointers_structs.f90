program main

  implicit none
  type pointer_type
      real, dimension(:), allocatable :: values
  end type
  type value_type
      real :: values(2)
  end type

  real, dimension(:) :: host_mem(2) = (/4,2/), res(2)
  integer :: i
  type(value_type) :: val
  type(pointer_type) :: indirect

  indirect%values = host_mem

  val%values = (/1,2/)

  !$acc parallel loop
  do i=1,2 
    res(i) = indirect%values(i)
  enddo
  write(*,*) "pointer values", res

  !$acc parallel loop
  do i=1,2 
    res(i) = val%values(i)
  enddo
  write(*,*) "direct values", res
  
end program
  
