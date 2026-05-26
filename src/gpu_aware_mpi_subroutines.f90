program gpu_aware_mpi_subroutines
  use openacc
  use mpi_f08
  use iso_c_binding
  implicit none
  integer, parameter :: n = 128
  integer :: ierr, rank, nprocs, partner, mismatches, gpu_num
  integer :: sentinel
  integer(c_size_t) :: nbytes
  type(c_ptr) :: send_cptr, recv_cptr
  integer, pointer :: send_buf(:), recv_buf(:)
  type(MPI_Status) :: status

  call MPI_Init(ierr)
  call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
  call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)

  call acc_set_device_num(rank, acc_get_device_type())
  gpu_num = acc_get_device_num(acc_get_device_type())
  write(*,*) "Rank", rank, ": GPU", gpu_num

  if (nprocs /= 2) then
    if (rank == 0) write(*,*) "GPU-aware MPI probe: needs exactly 2 ranks, got", nprocs
    call MPI_Finalize(ierr)
    error stop 1
  end if

  partner = 1 - rank

  nbytes = int(n, c_size_t) * c_sizeof(sentinel)
  send_cptr = acc_malloc(nbytes)
  recv_cptr = acc_malloc(nbytes)
  call c_f_pointer(send_cptr, send_buf, [n])
  call c_f_pointer(recv_cptr, recv_buf, [n])

  call init_buffers(send_buf, recv_buf, n, rank)

  call MPI_Sendrecv(send_buf, n, MPI_INTEGER, partner, 0, &
                    recv_buf, n, MPI_INTEGER, partner, 0, &
                    MPI_COMM_WORLD, status, ierr)

  call count_mismatches(recv_buf, n, partner, mismatches)

  if (mismatches /= 0) then
    write(*,*) "Rank", rank, ": mismatch count =", mismatches
    call MPI_Finalize(ierr)
    error stop "GPU-aware MPI: data mismatch"
  end if

  if (rank == 0) write(*,*) "GPU-aware MPI: OK"

  call acc_free(send_cptr)
  call acc_free(recv_cptr)

  call MPI_Finalize(ierr)

contains

  subroutine init_buffers(send_buf, recv_buf, n, rank)
    integer, intent(in) :: n, rank
    integer :: send_buf(n), recv_buf(n)
    integer :: i
    !$acc parallel loop deviceptr(send_buf, recv_buf)
    do i = 1, n
      send_buf(i) = i + rank*1000
      recv_buf(i) = 0
    end do
  end subroutine init_buffers

  subroutine count_mismatches(recv_buf, n, partner, mismatches)
    integer, intent(in) :: n, partner
    integer :: recv_buf(n)
    integer, intent(out) :: mismatches
    integer :: i, expected
    mismatches = 0
    !$acc parallel loop deviceptr(recv_buf) reduction(+:mismatches) private(expected)
    do i = 1, n
      expected = i + partner*1000
      if (recv_buf(i) /= expected) mismatches = mismatches + 1
    end do
  end subroutine count_mismatches

end program gpu_aware_mpi_subroutines
