#!/bin/bash

CASE=lumi_cray

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
make $BUILD_TARGETS

export SUBMIT_COMMAND=\"srun -t 1:00 -p dev-g --gres=gpu:1 --ntasks 1 --account project_465002836\"
export MPI_SUBMIT_COMMAND=\"srun -t 1:00 -p dev-g --gres=gpu:2 --ntasks 2 --account project_465002836\"

make $RUN_TARGETS

ls $CASE
"

mkdir -p $CASE
scp lumi:OpenACC_behaviour/src/$CASE/*out $CASE/
