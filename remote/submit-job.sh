#!/bin/bash

#SBATCH --nodes=1
#SBATCH --exclusive
#SBATCH --time=02:00:00
#SBATCH --partition=normal-arm
#SBATCH --account=f202500010hpcvlabuminhoa
#SBATCH --output=md.out


echo
echo "Loading GCC/15.2.0"

module purge
module load GCC/15.2.0

echo
echo "Compiling the code"

make clean
make

echo
echo "Profiling the code"

echo "Step 1: perf record"
perf record -e cycles:u make run

echo "Step 2: perf stat"
perf stat -d make run > perf.stat

echo
echo "Finished"
