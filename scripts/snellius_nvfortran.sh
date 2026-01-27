#!/bin/bash

ssh snellius '
module load 2025
module load NVHPC/25.3-CUDA-12.8.0

git clone https://github.com/v1kko/OpenACC_behaviour.git

cd OpenACC_behaviour/src

export COMPILER="nvfortran -Wall -acc=gpu -Minfo=all"
export CASE=snellius-nvfortran

make clean
make

make run

ls $CASE
'
