#!/bin/bash -l
#SBATCH -A f202500010hpcvlabuminhoa
#SBATCH -p normal-arm
#SBATCH -J md-perf
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=48
#SBATCH --time=00:20:00
#SBATCH --output=/projects/F202500010HPCVLABUMINHO/2026-2027cp/%u/logs/%x-%j.log
#
# remote/perf.sbatch — minimal perf job: one A64FX node, one profiling build,
# `perf record`, then the full `perf report -n --stdio` saved to a file.
#
#   sbatch remote/perf.sbatch                                  # from the repo root
#   sbatch --export=ALL,FREQ=500,THREADS=24 remote/perf.sbatch
#
# Artefacts: results/<jobid>-perf/{mdprof, perf.data, perf-report.txt}
# (results/ is gitignored; the logs/ dir in --output must exist — README.md)

set -euo pipefail

FREQ="${FREQ:-1000}"      # perf samples per second
THREADS="${THREADS:-48}"  # OMP_NUM_THREADS; 48 = whole node (measured/node.md)
KEEP_TRAJ="${KEEP_TRAJ:-0}"  # 1 = keep the multi-GB *_traj.xyz
# -fopenmp is mandatory (WA1); -g -fno-omit-frame-pointer for attribution.
OPT="${OPT:--O3 -fopenmp -march=native -g -fno-omit-frame-pointer}"

# Never build on a login node: its ISA is x86-64 and the binary would not run
# on cna* (measured/node.md). Submit this file; do not execute it directly.
if [[ "$(uname -m)" != "aarch64" ]]; then
	echo "!! not aarch64 — submit with sbatch on normal-arm, never run on ln*" >&2
	exit 2
fi

workdir="${SLURM_SUBMIT_DIR:-$PWD}"
results="$workdir/results/${SLURM_JOB_ID:-local}-perf"
mkdir -p "$results"
cd "$workdir"

ml GCC/15.2.0

# shellcheck disable=SC2086  # OPT is intentionally word-split
gcc $OPT src/MD.cpp -lm -o "$results/mdprof"

# MD reads inputdata.txt on stdin — the redirect is not optional. Run inside
# $results so perf.data and the *_traj.xyz / *_average.txt land there too.
(
	cd "$results"
	OMP_NUM_THREADS="$THREADS" perf record -g -F "$FREQ" -o perf.data \
		-- ./mdprof <"$workdir/inputdata.txt" >perf-run.log 2>&1
)
((KEEP_TRAJ == 1)) || rm -f "$results"/*_traj.xyz

# A batch job has no TTY: --stdio instead of the TUI; -n adds sample counts.
perf report -n --stdio -i "$results/perf.data" >"$results/perf-report.txt"

echo "report written to $results/perf-report.txt"
sed -n '1,40p' "$results/perf-report.txt"
