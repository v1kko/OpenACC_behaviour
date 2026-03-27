module mod1
    implicit none
    private
    integer, parameter :: n = 1000
    integer, allocatable, dimension(:) :: buffer
    !$acc declare create(buffer)

    public :: init1, sum1

    contains

    subroutine init1(val)
        integer, intent(in) :: val
        allocate(buffer(n))
        buffer = val
        !$acc update device(buffer)
    end subroutine init1

    subroutine sum1(val)
        integer, intent(out) :: val
        integer :: i

        val = 0
        !$acc parallel loop reduction(+:val)
        do i=1,n
            val = val + buffer(i)
        end do
    end subroutine sum1

end module mod1

module mod2
    implicit none
    private
    integer, parameter :: n = 1000
    integer, allocatable, dimension(:) :: buffer
    !$acc declare create(buffer)

    public :: init2, sum2

    contains

    subroutine init2(val)
        integer, intent(in) :: val
        allocate(buffer(n))
        buffer = val
        !$acc update device(buffer)
    end subroutine init2

    subroutine sum2(val)
        integer, intent(out) :: val
        integer :: i

        val = 0
        !$acc parallel loop reduction(+:val)
        do i=1,n
            val = val + buffer(i)
        end do
    end subroutine sum2

end module mod2

program aliasing
    use mod1
    use mod2
    implicit none
    integer :: val1, val2

    call init1(1)
    call init2(2)
    call sum1(val1)
    call sum2(val2)
    
    if (val1 == 1000 .and. val2 == 2000) then
      write(*,*) "Success, no aliasing"
    else
      write(*,*) "Fail, val1 and val2 are aliased:", val1, val2
    endif
end program aliasing

