program main
  use openacc
  implicit none
  real :: host_mem(10)

  host_mem = 4
  !$acc enter data copyin(host_mem)
  !$acc enter data copyin(host_mem)
  !$acc exit data delete(host_mem) finalize
  if (acc_is_present(host_mem)) then
    error stop "host_mem still present after finalize"
  endif
  write(*,*) "OK"
end program
