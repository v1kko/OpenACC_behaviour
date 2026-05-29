# GPU-aware MPI

GPU-aware MPI is supported by some vendors (at least Cray and Nvidia). This is not in the OpenACC spec, however, vital for performance in some HPC applications.

We have create the folowing scripts to test this communication: 

??? info "Test program no slicing"

    ```fortran
    --8<-- "src/gpu_aware_mpi.f90"
    ```

??? info "Test program with slicing"

    ```fortran
    --8<-- "src/gpu_aware_mpi_slicing.f90"
    ```

Slicing is an important feature, as it can avoid an unnecessary memcopy before transferring 

## Per-compiler observations

### Without slicing

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | ✅ OK | Outside OpenACC spec | `MPICH_GPU_SUPPORT_ENABLED=1`; contiguous buffer is transferred correctly between ranks. |
| nvfortran 25.3-0 | ✅ OK | Outside OpenACC spec | OpenMPI 5.0.7; contiguous buffer is transferred correctly between ranks. |

### With slicing

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray Fortran 19.0.0 | ✅ OK | Outside OpenACC spec | `MPICH_GPU_SUPPORT_ENABLED=1`; sliced (non-contiguous) buffer is transferred correctly. |
| nvfortran 25.3-0 | 🟡 Wrong result | Outside OpenACC spec | CUDA 12.8, OpenMPI 5.0.7; data mismatch on all 128 elements. |
