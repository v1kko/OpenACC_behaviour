program main
  implicit none
  type :: container
    integer, pointer :: p(:)
  end type
  type(container) :: c
  integer, pointer :: a(:), b(:)
  integer :: i, res(10)

  allocate(a(10), b(10))
  a = 1
  b = 2

  c%p => a
  !$acc enter data copyin(c)
  !$acc enter data copyin(a) attach(c%p)

  c%p => b
  !$acc enter data copyin(b) attach(c%p)

  res = -1
  !$acc parallel loop present(c)
  do i = 1, 10
    res(i) = c%p(i)
  end do

  if (all(res == 2)) then
    write(*,*) "OK"
  else
    write(*,*) "Wrong result: ", res
    error stop
  end if
end program
