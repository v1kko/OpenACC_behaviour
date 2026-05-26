program gpu_aware_mpi
  use openacc
  use mpi_f08
  implicit none

  integer, parameter :: n = 128
  integer :: ierr, rank, nprocs, partner, i, j, mismatches, expected, gpu_num
  integer, allocatable, dimension(:,:) :: send_buf, recv_buf
  !$acc declare device_resident(send_buf, recv_buf)
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

  allocate(send_buf(n,n))
  allocate(recv_buf(n,n))

  !$acc parallel loop collapse(2) present(send_buf, recv_buf)
  do i = 1, n
    do j = 1, n
      send_buf(i,j) = i+j*128+rank*17000 
      recv_buf(i,j) = 0
    end do
  end do

  !$acc host_data use_device(send_buf, recv_buf)
  call MPI_Sendrecv(send_buf(:,6), n, MPI_INTEGER, partner, 0, &
                    recv_buf(:,5), n, MPI_INTEGER, partner, 0, &
                    MPI_COMM_WORLD, status, ierr)
  !$acc end host_data

  mismatches = 0
  !$acc parallel loop present(recv_buf) reduction(+:mismatches) private(expected)
  do i = 1, n
    expected = 6*128 + i + partner*1000
    if (recv_buf(i,5) /= expected) mismatches = mismatches + 1
  end do

  if (mismatches /= 0) then
    write(*,*) "Rank", rank, ": mismatch count =", mismatches
    call MPI_Finalize(ierr)
    error stop "GPU-aware MPI: data mismatch"
  end if

  if (rank == 0) write(*,*) "GPU-aware MPI: OK"

  deallocate(send_buf, recv_buf)

  call MPI_Finalize(ierr)
end program

