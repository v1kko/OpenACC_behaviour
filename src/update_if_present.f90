program main
  use openacc
  implicit none
  real :: host_mem(10)

  host_mem = 4
  !$acc update device(host_mem) if_present
  write(*,*) "OK"
end program
