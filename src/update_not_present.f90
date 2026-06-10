program main
  use openacc
  implicit none
  real :: host_mem(10)

  host_mem = 4
  !$acc update device(host_mem)
  write(*,*) "No runtime error for update of not-present data"
end program
