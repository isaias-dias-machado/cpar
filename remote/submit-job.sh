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

echo "Code version: ${VERSION}"
echo "Results directory: ${RESULTS}"

echo
echo "Loading GCC/15.2.0"

module purge
module load GCC/15.2.0

for thread in $THREADS; do 
  echo "======== Profiling for $thread threads ========"
  echo
  echo "Compiling the code"

  make clean VERSION="$VERSION" RESULTS="$RESULTS"
  make VERSION="$VERSION" RESULTS="$RESULTS"
  # make results-dir VERSION="$VERSION" RESULTS="$RESULTS" OMP_NUM_THREADS="$thread"

  echo
  echo "Profiling the code"

  echo "Step 1: perf record"
  perf record -e cycles:u -o "$RESULTS/perf.data" -- \
      make run VERSION="$VERSION" RESULTS="$RESULTS" OMP_NUM_THREADS="$thread"

  echo "Step 2: perf stat"
  perf stat -d -r 10 -- \
      make run VERSION="$VERSION" RESULTS="$RESULTS" OMP_NUM_THREADS="$thread"

  echo "Step 3: export perf record to text file"
  perf report -n -i "$RESULTS/perf.data" --stdio

  echo "Results compared to the baseline result"
  ./scripts/check

  echo
  echo "Finished"
done
