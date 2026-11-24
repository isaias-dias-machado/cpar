#!/bin/bash

#SBATCH --nodes=1
#SBATCH --exclusive
#SBATCH --time=02:00:00
#SBATCH --partition=normal-arm
#SBATCH --account=f202500010hpcvlabuminhoa

# Configuration
VERSION="${VERSION:-}"
RESULTS="${RESULTS:-results${VERSION}}"
THREADS=${THREADS:-1 2 4 8 12 16 24 32 48 54 60 72}

echo
echo "Loading GCC/15.2.0"

module purge
module load GCC/15.2.0

for thread in $THREADS; do 
  echo "======== Profiling for $thread threads ========"
  echo

  make clean

  echo "Step 1: perf record"
  perf record -e cycles:u -o "perf.data" -- \
      make run OMP_NUM_THREADS="$thread"

  echo "Step 2: perf stat"
  perf stat -d -r 3 -- \
      make run OMP_NUM_THREADS="$thread"

  echo "Step 3: export perf record to text file"
  perf report -n -i "perf.data" --stdio

  echo "Results compared to the baseline result"
  ./scripts/check

  echo
  echo "Finished"
done
