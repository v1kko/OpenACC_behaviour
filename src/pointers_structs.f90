program main
  implicit none
  type pointer_type
      real, dimension(:), allocatable :: values
  end type
  type value_type
      real :: values(2)
  end type
  real, dimension(:) :: host_mem(2) = (/4,2/)
  type(value_type) :: val
  type(pointer_type) :: indirect

  indirect%values = host_mem

  val%values = (/1,2/)


  write(*,*) "direct values", val
  write(*,*) "pointer values", indirect%values
  
end program
  
