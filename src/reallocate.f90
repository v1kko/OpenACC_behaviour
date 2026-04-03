program main
  implicit none
  integer, pointer, dimension(:) :: a, b
  integer :: i, res(10)

  allocate(a(2))
  a(1) = 4
  a(2) = 2
  !$acc enter data copyin(a)

  !$acc parallel loop 
  do i=1,2 
    res(i) = a(i)
  enddo

  if (res(1) == 4 .and. res(2) == 2) then
    write(*,*) "First allocate works"
  else
    error stop "Error with simple loop"
  endif

  allocate(b(10))
  b = (/1,2,3,4,5,6,7,8,9,0/)
  deallocate(a)
  a => b
  !$acc update device(a)

  !$acc parallel loop 
  do i=1,10
    res(i) = a(i)
  enddo

  if (all(res == b)) then
    write(*,*) "Reallocation success!"
  else
    write(*,*) "Something went wrong: ", res
    error stop
  end if
end program
