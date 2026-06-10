program main
  implicit none
  type :: container
    integer, pointer :: p(:)
  end type
  type(container) :: c

  nullify(c%p)
  !$acc enter data copyin(c)
  !$acc exit data detach(c%p)
  !$acc exit data delete(c)
  write(*,*) "OK"
end program
