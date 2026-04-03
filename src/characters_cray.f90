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
    character(len=14) :: new_message
    new_message = message(1:7) // "!"
    write(*,*)new_message
  end subroutine
end program
