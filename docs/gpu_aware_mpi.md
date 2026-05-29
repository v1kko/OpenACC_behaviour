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

| Compiler | Version | Result | Notes |
|----------|---------|--------|-------|
|          |         |        |       |
