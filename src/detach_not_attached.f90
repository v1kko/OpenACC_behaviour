program main
  implicit none
  type :: container
    integer, pointer :: p(:)
  end type
  type(container) :: c
  integer, pointer :: a(:)
  integer :: i, res(10)

  allocate(a(10))
  a = 1

  nullify(c%p)
  !$acc enter data copyin(c)
  !$acc exit data detach(c%p)

  c%p => a
  !$acc enter data copyin(a) attach(c%p)

  res = -1
  !$acc parallel loop present(c)
  do i = 1, 10
    res(i) = c%p(i)
  end do

  if (all(res == 1)) then
    write(*,*) "OK"
  else
    write(*,*) "Wrong result: ", res
    error stop
  end if
end program
