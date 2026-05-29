#!/bin/bash

CASE=lumi_cray

ssh lumi "
module load LUMI/25.03
module load partition/G

git clone https://github.com/v1kko/OpenACC_behaviour.git

cd OpenACC_behaviour/src

git pull

export COMPILER=\"ftn -g -hacc\"
export CASE=${CASE}
export CRAY_ACC_DEBUG=3
export MPICH_GPU_SUPPORT_ENABLED=1

make clean
make

export SUBMIT_COMMAND=\"srun -t 1:00 -p dev-g --gres=gpu:1 --ntasks 1 --account project_465002836\"
export MPI_SUBMIT_COMMAND=\"srun -t 1:00 -p dev-g --gres=gpu:2 --ntasks 2 --account project_465002836\"

make run

ls $CASE
"

mkdir -p $CASE
scp lumi:OpenACC_behaviour/src/$CASE/*out $CASE/
