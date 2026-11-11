#!/bin/bash -l
#SBATCH -A f202500010hpcvlabuminhoa
#SBATCH -p normal-arm
#SBATCH -J md
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=48
#SBATCH --time=00:30:00
#SBATCH --output=/projects/F202500010HPCVLABUMINHO/2026-2027cp/%u/logs/%x-%j.log
#
# remote/md.sbatch — build the graded binary on the node and run the timing
# sweep (one batch job = one whole billed A64FX node). Submit from the repo
# root:
#
#     sbatch remote/md.sbatch
#
# The file is the configuration: edit the constants block below to change the
# experiment. One RESULT line per run in the log; per-run artefacts in
# results/<jobid>-timing/p<P>_r<R>/; the log in logs/md-<jobid>.log.

set -euo pipefail

# --- edit these --------------------------------------------------------------
THREADS=(1 2 4 8 12 16 24 32 48)                  # sweep points (one process each)
REPS=3                                            # repetitions per sweep point
OPT="-O3 -ffast-math -fopenmp -march=native"      # graded build path (make CFLAGS=...)
# ------------------------------------------------------------------------------

# Refuse the x86-64 login node: a binary built there dies with
# "Exec format error" on the ARM compute nodes (context/measured/node.md).
if [[ "$(uname -m)" != "aarch64" ]]; then
	echo "!! refusing to run on $(uname -m) — submit instead: sbatch remote/md.sbatch" >&2
	exit 2
fi

workdir="${SLURM_SUBMIT_DIR:-$PWD}"
cd "$workdir"
results_dir="results/${SLURM_JOB_ID}-timing"

module purge
module load GCC/15.2.0

echo "===== provenance ====="
echo "  date      $(date -Is)"
echo "  host      $(hostname) ($(uname -m))"
echo "  job       $SLURM_JOB_ID"
echo "  compiler  $(gcc --version | head -n 1)"

echo "===== build — make CFLAGS='$OPT' (the graded build path) ====="
make clean
make CFLAGS="$OPT"

echo "===== timing sweep — threads: ${THREADS[*]} · reps: $REPS ====="
for p in "${THREADS[@]}"; do
	for r in $(seq 1 "$REPS"); do
		dir="$results_dir/p${p}_r${r}"
		mkdir -p "$dir"
		t0=$(date +%s%N)
		# Run inside the per-run dir so outputs never clobber; MD scanf's
		# stdin, so the < inputdata.txt redirect is required.
		(cd "$dir" && OMP_NUM_THREADS="$p" "$workdir/md" \
			< "$workdir/inputdata.txt" > run.log 2>&1)
		t1=$(date +%s%N)
		secs=$(awk -v a="$t0" -v b="$t1" 'BEGIN{printf "%.3f", (b-a)/1e9}')
		rm -f "$dir"/*_traj.xyz   # multi-GB per run, never kept
		printf 'RESULT threads=%s rep=%s wall_s=%s dir=%s\n' "$p" "$r" "$secs" "$dir"
	done
done

echo "===== end ====="
echo "  artefacts in $results_dir"
