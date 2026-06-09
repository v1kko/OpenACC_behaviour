program main
  use openacc
  implicit none
  real :: host_mem

  host_mem = 4
  !$acc enter data copyin(host_mem)
  !$acc exit data delete(host_mem)
  !$acc exit data delete(host_mem)
  write(*,*) "OK"
end program
  
