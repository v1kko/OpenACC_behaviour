program main
  implicit none
  real  :: host_mem

  host_mem = (/4/)

  !$acc exit data delete(host_mem)
  write(*,*) "OK"
end program
  
