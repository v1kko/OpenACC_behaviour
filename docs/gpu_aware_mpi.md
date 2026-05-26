# GPU-aware MPI probe

Tracks [amrvac/AGILE-experimental#131](https://github.com/amrvac/AGILE-experimental/issues/131).

A small standalone Fortran + OpenACC + MPI program that verifies GPU-aware MPI
works end-to-end: rank 0 and rank 1 each fill a device buffer with a known
integer pattern, exchange them via `MPI_Sendrecv` using device pointers
(`!$acc host_data use_device(...)`), then verify the contents that arrived.

On success, rank 0 prints `GPU-aware MPI: OK` and the program exits 0. On a
mismatch (or if the MPI implementation silently copies through host memory and
corrupts the payload) the program prints a mismatch count and `error stop`s.

## Build & run

The repo Makefile picks up `gpu_aware_mpi.f90` automatically. `ftn` on Cray
already wraps MPI; on non-Cray systems pass an MPI wrapper as `COMPILER`:

```sh
cd src
make CASE=build gpu_aware_mpi                      # compile
make CASE=build SUBMIT_COMMAND='srun -n 2' gpu_aware_mpi.run   # run on 2 ranks
```

Launching with anything other than 2 ranks is a hard error.

## Per-compiler observations

| Compiler | Version | Result | Notes |
|----------|---------|--------|-------|
|          |         |        |       |

## Device-only buffer variant (`acc_malloc` + `deviceptr`)

A second variant skips the host-side arrays entirely: `send_buf` and `recv_buf`
are allocated directly on the device with `acc_malloc`, associated with Fortran
pointers via `c_f_pointer`, and used inside compute regions through the
`deviceptr` clause. Because the Fortran descriptor's data address is already
the device pointer, the `MPI_Sendrecv` call no longer needs to be wrapped in
`!$acc host_data use_device(...)` — GPU-aware MPI receives the device address
straight from the buffer argument.

The OpenACC 3.x spec declares `acc_malloc` as `type(c_ptr) function
acc_malloc(int(c_size_t))` and `acc_free` as taking a `type(c_ptr)`. NVHPC's
`openacc` module deviates and uses `type(c_devptr)` (from CUDA Fortran) for
both, so a plain `c_ptr` call fails to resolve:

```text
NVFORTRAN-S-0148-Reference to TYPE(C_PTR) expression required
NVFORTRAN-S-0155-Could not resolve generic procedure acc_free
```

To stay portable across NVHPC and Cray, this variant bypasses the `openacc`
module's generics and declares its own `bind(C, name='acc_malloc')` /
`bind(C, name='acc_free')` interfaces (named `acc_malloc_c` / `acc_free_c`)
that match the spec's `c_ptr` signature. Both compilers expose those C
symbols from the runtime library.
