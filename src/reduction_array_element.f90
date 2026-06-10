program main
  implicit none
  integer :: a(2), i

  a = 0
  !$acc parallel loop reduction(+:a(1))
  do i = 1, 100
    a(1) = a(1) + i
  end do

  if (a(1) == 5050) then
    write(*,*) "OK"
  else
    write(*,*) "Wrong result: ", a(1)
    error stop
  end if
end program
