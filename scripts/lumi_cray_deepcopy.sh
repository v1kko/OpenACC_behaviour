#!/bin/bash

CASE=lumi-cray-deepcopy

ssh lumi "
module load LUMI/25.03
module load PrgEnv-cray/8.6.0
module load partition/G

git clone https://github.com/v1kko/OpenACC_behaviour.git

cd OpenACC_behaviour/src

export COMPILER=\"ftn -g -hacc -hacc_model=deep_copy\"
export CASE=${CASE}
export CRAY_ACC_DEBUG=3

make clean
make

export SUBMIT_COMMAND=\"srun -t 1:00 -p standard-g --gres=gpu:1 --ntasks 1 --account project_465001595\"

make run

ls $CASE
"

mkdir -p $CASE
scp lumi:OpenACC_behaviour/src/$CASE/*out $CASE/
