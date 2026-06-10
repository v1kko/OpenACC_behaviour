program main
  use openacc
  implicit none
  integer :: a(100), i

  a = [(i, i=1,100)]
  !$acc enter data copyin(a(1:50))
  !$acc enter data copyin(a(25:75))
  write(*,*) "No runtime error for partly present data"
end program
