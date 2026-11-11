#!/bin/bash -l
#SBATCH -A f202500010hpcvlabuminhoa
#SBATCH -p normal-arm
#SBATCH -J md-perf
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=48
#SBATCH --time=01:20:00
#SBATCH --output=/projects/F202500010HPCVLABUMINHO/2026-2027cp/%u/logs/%x-%j.log
#
# Minimal perf job — submit from the repo root:
#   sbatch remote/perf.sbatch
# Report: results/<timestamp>/perf_report.txt

set -eu

RESULTS="results/$(date +%Y-%m-%d--%H-%M)"
mkdir -p "$RESULTS"

ml GCC/15.2.0
# -fopenmp is mandatory; -g so the report has symbols. OMP_NUM_THREADS defaults
# to all 48 cores on the node (context/measured/node.md).
gcc -O3 -fopenmp -g src/MD.cpp -lm -o "$RESULTS/mdprof"

# MD reads inputdata.txt on stdin — the redirect is required.
perf record -g -F 1000 -o "$RESULTS/perf.data" -- "$RESULTS/mdprof" < inputdata.txt

# No TTY in a batch job: --stdio, not the TUI.
perf report -n --stdio -i "$RESULTS/perf.data" > "$RESULTS/perf_report.txt"
