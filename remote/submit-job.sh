#!/bin/bash

#SBATCH --nodes=1
#SBATCH --exclusive
#SBATCH --time=02:00:00
#SBATCH --partition=normal-arm
#SBATCH --account=f202500010hpcvlabuminhoa

# Configuration
VERSION="${VERSION:-}"
RESULTS="${RESULTS:-results${VERSION}}"

echo "Code version: ${VERSION}"
echo "Results directory: ${RESULTS}"

echo
echo "Loading GCC/15.2.0"

module purge
module load GCC/15.2.0

echo
echo "Compiling the code"

make clean VERSION="$VERSION" RESULTS="$RESULTS"
make VERSION="$VERSION" RESULTS="$RESULTS"
make results-dir VERSION="$VERSION" RESULTS="$RESULTS"

echo
echo "Profiling the code"

echo "Step 1: perf record"
perf record -e cycles:u -o "$RESULTS/perf.data" -- \
    make run VERSION="$VERSION" RESULTS="$RESULTS"

echo "Step 2: perf stat"
perf stat -d -o "$RESULTS/perf.stat" -- \
    make run VERSION="$VERSION" RESULTS="$RESULTS"

echo "Step 3: export perf record to text file"
perf report -n -i "$RESULTS/perf.data" --stdio > "$RESULTS/perf.data.txt"

echo
echo "Finished"
