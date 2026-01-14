program main
  implicit none
  character(len=12) :: message = "hello world"
  call write_message(message)

contains
  subroutine write_message(message)
    !$acc routine
    implicit none
    character(len=*), intent(in) :: message
    write(*,*)message
  end subroutine
end program
