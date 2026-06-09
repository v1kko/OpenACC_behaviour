program main
  use openacc
  implicit none
  real, allocatable :: host_mem
  integer :: i


  host_mem = 4

  !$acc exit data delete(host_mem) if(acc_is_present(host_mem))
  write(*,*) "OK"
end program
  
