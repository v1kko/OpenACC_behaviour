program main
  implicit none
  type container_type
      real, dimension(:), allocatable :: values
  end type

  real, dimension(:) :: host_mem(2) = (/4,2/), res(2)
  real, dimension(:) :: host_mem2(42), res2(42)
  integer :: i
  type(container_type) :: container
  host_mem2 = 42

  allocate(container%values(2))
  indirect%values = host_mem

  write(*,*) "Checking if allocatable values are copied to device with !$acc parallel loop ..."
  !$acc parallel loop
  do i=1,2 
    res(i) = indirect%values(i)
  enddo
  write(*,*) "Success", res

  deallocate(container%values(2))
  allocate(container%values(42))
  indirect%values = host_mem2

  write(*,*) "Checking if allocatable values are copied to device with !$acc parallel loop ..."
  !$acc parallel loop
  do i=1,42 
    res2(i) = indirect%values(i)
  enddo
  do i = 1,42
    if (res2(i) .ne. host_mem2(i)) then
      write(*,*) "Failure entry: ", i, " has value ", res2(i) " instead of ", host_mem2(i)
    endif
  enddo
  write(*,*) "Success", res

end program
  
