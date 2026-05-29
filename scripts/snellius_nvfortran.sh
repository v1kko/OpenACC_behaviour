#!/bin/bash

CASE=snellius_nvfortran

ssh snellius_gpu "
module load 2025
module load NVHPC/25.3-CUDA-12.8.0
module load OpenMPI/5.0.7-NVHPC-25.3-CUDA-12.8.0

git clone https://github.com/v1kko/OpenACC_behaviour.git

cd OpenACC_behaviour/src

git pull

export COMPILER=\"mpif90 -Wall -acc=gpu -Minfo=all\"
export CUDA_VISIBLE_DEVICES=\"0,1\"
export MPI_SUBMIT_COMMAND=\"mpirun -n 2\"
export CASE=${CASE}
rm -rf $CASE 

make clean
make

make run

ls $CASE
"

mkdir -p $CASE
scp snellius_gpu:OpenACC_behaviour/src/$CASE/*out $CASE/
