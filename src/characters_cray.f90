program main
  implicit none
  character(len=12) :: message = "Success"
  write(*,*) "Checking if characters can be printed in acc nohost subroutine ..."
  call write_message(message)

contains
  subroutine write_message(message)
    !$acc routine seq
    implicit none
    character(len=12), intent(in) :: message
    write(*,*)message
  end subroutine
end program
