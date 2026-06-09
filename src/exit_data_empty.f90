program main
  implicit none
  real, dimension(:), allocatable :: host_mem
  integer :: i


  allocate(host_mem(2))
  host_mem = (/4,2/)

  !$acc exit data delete(host_mem)
  write(*,*) "OK"
end program
  
