program main
  implicit none
  type :: stats
    integer :: a
    integer :: b
  end type
  type(stats) :: s
  integer :: i

  s%a = 0
  s%b = 0
  !$acc parallel loop reduction(+:s)
  do i = 1, 100
    s%a = s%a + i
    s%b = s%b + 1
  end do

  if (s%a == 5050 .and. s%b == 100) then
    write(*,*) "OK"
  else
    write(*,*) "Wrong result: ", s%a, s%b
    error stop
  end if
end program
