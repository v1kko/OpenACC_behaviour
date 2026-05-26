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
