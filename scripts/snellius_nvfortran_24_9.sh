#!/bin/bash

CASE=snellius_nvfortran_24_9

# Optional: pass case names (source basenames without .f90) to build/run only
# those. With no arguments, everything is built and run.
if [ "$#" -gt 0 ]; then
    BUILD_TARGETS=""
    RUN_TARGETS=""
    for c in "$@"; do
        BUILD_TARGETS="$BUILD_TARGETS \$CASE/$c"
        RUN_TARGETS="$RUN_TARGETS \$CASE/$c.run"
    done
else
    BUILD_TARGETS=""
    RUN_TARGETS="run"
fi

ssh snellius_gpu "
module load 2024
module load NVHPC/24.9-CUDA-12.6.0
module load OpenMPI/5.0.3-NVHPC-24.9-CUDA-12.6.0

git clone https://github.com/v1kko/OpenACC_behaviour.git

cd OpenACC_behaviour/src

git pull

export COMPILER=\"mpif90 -Wall -acc=gpu -Minfo=all\"
export CUDA_VISIBLE_DEVICES=\"0,1\"
export MPI_SUBMIT_COMMAND=\"mpirun -n 2\"
export UCX_MEMTYPE_CACHE=n
export CASE=${CASE}
rm -rf $CASE 

make clean
make $BUILD_TARGETS

make $RUN_TARGETS

ls $CASE
"

mkdir -p $CASE
scp snellius_gpu:OpenACC_behaviour/src/$CASE/*out $CASE/
