#!/bin/bash

ssh lumi '
module load LUMI/25.03
module load PrgEnv-cray/8.6.0
module load partition/G

git clone https://github.com/v1kko/OpenACC_behaviour.git

cd OpenACC_behaviour/src

export COMPILER="ftn -g -hacc"
export CASE=lumi-cray
export CRAY_ACC_DEBUG=3

make clean
make

export SUBMIT_COMMAND="srun -t 1:00 -p standard-g --gres=gpu:1 --ntasks 1 --account project_465001595"

make run

ls $CASE
'
