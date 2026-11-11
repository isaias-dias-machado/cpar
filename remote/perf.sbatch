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
# remote/perf.sbatch — profiling job: build a separate -g binary on the node
# and record one call-graph profile of a full run. Submit from the repo root:
#
#     sbatch remote/perf.sbatch
#
# The file is the configuration: edit the constants block below to change the
# experiment. Artefacts land in results/<jobid>-perf/, the log in
# logs/md-perf-<jobid>.log.

set -euo pipefail

# --- edit these --------------------------------------------------------------
FREQ=1000                                                       # perf samples/s
THREADS=48                                  # OMP_NUM_THREADS for the profiled run (whole node)
PROF_OPT="-O3 -fopenmp -march=native -g -fno-omit-frame-pointer" # profiling binary flags
# ------------------------------------------------------------------------------

# Refuse the x86-64 login node: a binary built there dies with
# "Exec format error" on the ARM compute nodes (context/measured/node.md).
if [[ "$(uname -m)" != "aarch64" ]]; then
	echo "!! refusing to run on $(uname -m) — submit instead: sbatch remote/perf.sbatch" >&2
	exit 2
fi

workdir="${SLURM_SUBMIT_DIR:-$PWD}"
cd "$workdir"
results_dir="results/${SLURM_JOB_ID}-perf"
mkdir -p "$results_dir"

module purge
module load GCC/15.2.0

echo "===== provenance ====="
echo "  date      $(date -Is)"
echo "  host      $(hostname) ($(uname -m))"
echo "  job       $SLURM_JOB_ID"
echo "  compiler  $(gcc --version | head -n 1)"

echo "===== build — profiling binary (separate: -g must not contaminate the timed binary) ====="
# shellcheck disable=SC2086  # PROF_OPT is intentionally word-split
gcc $PROF_OPT src/MD.cpp -lm -o "$results_dir/mdprof"

echo "===== perf record — -g -F $FREQ, OMP_NUM_THREADS=$THREADS ====="
# MD scanf's stdin: the < inputdata.txt redirect is required.
# Run inside the results dir so the multi-GB *_traj.xyz lands there.
(cd "$results_dir" && OMP_NUM_THREADS="$THREADS" \
	perf record -g -F "$FREQ" -o perf.data -- "$results_dir/mdprof" \
	< "$workdir/inputdata.txt" > perf-run.log 2>&1)
rm -f "$results_dir"/*_traj.xyz

echo "===== perf report — full report in perf-report.txt (batch jobs have no TTY) ====="
perf report -n --stdio -i "$results_dir/perf.data" > "$results_dir/perf-report.txt"
sed -n '1,40p' "$results_dir/perf-report.txt" | sed 's/^/  /'

echo "===== end ====="
echo "  artefacts in $results_dir"
