program main
  implicit none
  type :: stats
    integer :: total
  end type
  type(stats) :: s
  integer :: i

  s%total = 0
  !$acc parallel loop reduction(+:s%total)
  do i = 1, 100
    s%total = s%total + i
  end do

  if (s%total == 5050) then
    write(*,*) "OK (member reduction accepted and correct)"
  else
    write(*,*) "Wrong result: ", s%total
    error stop
  end if
end program
