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
# remote/md.sbatch — one batch job = one A64FX node = one experiment.
#
# PURPOSE
#   A single, parameterised Slurm runner for this repo. `MODE` picks what the
#   job does (build | timing | perf); every knob below is an environment
#   variable, so an experiment is a submit line, never a file edit:
#
#       sbatch remote/md.sbatch
#       sbatch -J timing --export=ALL,MODE=timing,THREADS="1 2 4",REPS=5 remote/md.sbatch
#       sbatch -J perf   --export=ALL,MODE=perf,FREQ=1000 remote/md.sbatch
#       sbatch -J build  --export=ALL,MODE=build,OPT="-O2 -fopenmp" remote/md.sbatch
#
#   Full usage, cost rules and the harvest procedure: README.md.
#
# INVARIANTS
#   * Runs only inside a Slurm allocation: the `aarch64` guard refuses the
#     x86-64 login node, where a `./md` binary cannot run (measured/node.md).
#   * `#SBATCH --output` has no `--error` twin on purpose: Slurm merges stderr
#     into the stdout file by default, so one job = exactly one log file.
#   * Builds and measures on the node; nothing is built on `ln*`.
#   * Physics, `inputdata.txt` and the output formats are never touched: the
#     script only sets environment variables and flags (root AGENTS.md,
#     "Anti-patterns").
#
# FAILURE MODES
#   * `logs/` missing under the workspace -> Slurm cannot open the output file
#     and the job fails immediately (create it once, see README.md).
#   * One run exceeding `RUN_TIMEOUT` -> that rep is recorded with `exit=124`
#     and the sweep continues.
#   * `perf` unreadable -> perf mode reports it and skips, the job still exits 0.
#   * Non-ARM host -> exit 2, nothing is built or run.
#
# USAGE (this file is an operator runbook; the agent never submits it)
#   see README.md §"Running on Deucalion".

set -euo pipefail

# ---------------------------------------------------------------- knobs -----
# Every knob is overridable at submit time with `--export=ALL,NAME=value`.
# Comma-free values only: Slurm splits --export on commas.
MODE="${MODE:-timing}"                # build | timing | perf | help
OPT="${OPT:--O3 -ffast-math -fopenmp -march=native}"
PROF_OPT="${PROF_OPT:--O3 -fopenmp -march=native -g -fno-omit-frame-pointer}"
THREADS="${THREADS:-1 2 4 8 12 16 24 32 48}"   # sweep points (one process each)
REPS="${REPS:-3}"                     # repetitions per sweep point
FREQ="${FREQ:-1000}"                  # perf sampling frequency, samples/s
RUN_TIMEOUT="${RUN_TIMEOUT:-900}"     # seconds allowed per single run
TOL="${TOL:-1e-6}"                    # determinism tolerance, relative
KEEP_TRAJ="${KEEP_TRAJ:-0}"           # 1 = keep the multi-GB *_traj.xyz
ALLOW_NON_ARM="${ALLOW_NON_ARM:-0}"   # 1 = local smoke test outside Slurm
RESULTS_DIR="${RESULTS_DIR:-}"        # default: $workdir/results/<job>-<mode>
# Thread placement: overridable so affinity experiments need no file edit.
: "${OMP_PROC_BIND:=close}"
: "${OMP_PLACES:=cores}"
export OMP_PROC_BIND OMP_PLACES
# ----------------------------------------------------------------------------

arch="$(uname -m)"
workdir="${SLURM_SUBMIT_DIR:-$PWD}"
results_dir="${RESULTS_DIR:-$workdir/results/${SLURM_JOB_ID:-local}-$MODE}"

section() { printf '\n===== %s =====\n' "$*"; }
note() { printf '  %s\n' "$*"; }

usage() {
	cat <<'EOF'
remote/md.sbatch — parameterised Slurm runner (see README.md)

Knobs (pass with: sbatch --export=ALL,NAME=value remote/md.sbatch)
  MODE         build | timing | perf | help            [timing]
  OPT          flags for the graded build path         [-O3 -ffast-math -fopenmp -march=native]
  PROF_OPT     flags for the perf-only binary          [... -g -fno-omit-frame-pointer]
  THREADS      space-separated sweep points            [1 2 4 8 12 16 24 32 48]
  REPS         repetitions per point                   [3]
  FREQ         perf sampling rate (samples/s)          [1000]
  RUN_TIMEOUT  seconds allowed per single run          [900]
  TOL          determinism tolerance (relative)        [1e-6]
  KEEP_TRAJ    1 = keep *_traj.xyz (multi-GB)          [0]
  RESULTS_DIR  where per-run directories are written   [<repo>/results/<job>-<mode>]

Other sbatch overrides worth knowing: -J <name> (log file name), --time=HH:MM:SS,
--cpus-per-task (default: one whole node, measured/node.md).

Modes
  build   compile with OPT through the Makefile, report the file type
  timing  build, then sweep THREADS x REPS, one RESULT line per run, then a
          cross-thread determinism canary (data-race check)
  perf    build mdprof with PROF_OPT, perf record -g + perf stat, print the
          --stdio hotspot report (the interactive TUI needs a terminal)
EOF
}

load_modules() {
	section "toolchain"
	# The job shell is not a login shell; modules are not inherited from the
	# login node, and they are architecture-correct per node (Boas_Praticas.md).
	if type -t module >/dev/null 2>&1; then
		module purge >/dev/null 2>&1 || true
		if module load GCC >/dev/null 2>&1; then
			note "module GCC loaded"
		else
			note "!! module load GCC failed, using the system compiler"
		fi
	else
		note "!! 'module' undefined: not a login shell (shebang must be '#!/bin/bash -l')"
	fi
}

provenance() {
	section "provenance"
	note "date        $(date -Is)"
	note "host        $(hostname) ($arch)"
	note "job         ${SLURM_JOB_ID:-<not under Slurm>} (account ${SLURM_JOB_ACCOUNT:-?})"
	note "nodes       ${SLURM_JOB_NODELIST:-?} · cpus-per-task ${SLURM_CPUS_PER_TASK:-?} · partition ${SLURM_JOB_PARTITION:-?}"
	note "workdir     $workdir"
	note "results     $results_dir"
	if command -v gcc >/dev/null 2>&1; then
		note "compiler    $(gcc --version | head -n 1)"
	fi
	note "flags       OPT='$OPT' PROF_OPT='$PROF_OPT'"
	note "sources     $(sha256sum src/MD.cpp Makefile | awk '{print $1}' | tr '\n' ' ')"
	note "openmp      OMP_PROC_BIND=$OMP_PROC_BIND OMP_PLACES=$OMP_PLACES"
}

# Builds through the graded Makefile so the measurement also validates the
# build path the grader will use. CFLAGS is the Makefile's own variable.
build_tuned() {
	section "build — make CFLAGS='$OPT'"
	make clean >/dev/null 2>&1 || true
	make CFLAGS="$OPT"
	if [[ ! -x ./md ]]; then
		note "!! ./md was not produced"
		return 1
	fi
	if command -v file >/dev/null 2>&1; then
		file ./md | sed 's/^/  /'
	fi
}

# Separate binary on purpose: -g -fno-omit-frame-pointer improves attribution
# but must not contaminate the timed binary (context/topics/profiling-workflow.md).
build_prof() {
	section "build — profiling binary mdprof"
	note "flags '$PROF_OPT'"
	# shellcheck disable=SC2086  # PROF_OPT is intentionally word-split
	gcc $PROF_OPT src/MD.cpp -lm -o mdprof
	if [[ ! -x ./mdprof ]]; then
		note "!! ./mdprof was not produced"
		return 1
	fi
}

# run_case <threads> <rep>: one timed run in its own directory, so output files
# never clobber each other and every RESULT line points at its artefacts.
run_case() {
	local p="$1" r="$2"
	local dir="$results_dir/p${p}_r${r}"
	mkdir -p "$dir"
	local t0 t1 secs status
	t0=$(date +%s%N)
	if (cd "$dir" && OMP_NUM_THREADS="$p" timeout "$RUN_TIMEOUT" \
		"$workdir/md" <"$workdir/inputdata.txt" >run.log 2>&1); then
		status=0
	else
		status=$?
	fi
	t1=$(date +%s%N)
	secs=$(awk -v a="$t0" -v b="$t1" 'BEGIN{printf "%.3f", (b-a)/1e9}')
	((KEEP_TRAJ == 1)) || rm -f "$dir"/*_traj.xyz
	printf 'RESULT mode=timing threads=%s rep=%s wall_s=%s exit=%s dir=%s\n' \
		"$p" "$r" "$secs" "$status" "${dir#"$workdir"/}"
}

sweep() {
	build_tuned
	section "timing sweep — threads: $THREADS · reps: $REPS · timeout: ${RUN_TIMEOUT}s"
	for p in $THREADS; do
		for r in $(seq 1 "$REPS"); do
			run_case "$p" "$r"
		done
	done
}

# The single data line of *_average.txt (header + rule + values).
average_data_line() {
	awk 'NF > 1 && $1 ~ /^-?[0-9]/ { print; exit }' "$1" 2>/dev/null
}

# compare_run <label> <reference-file> <file-under-test>
compare_run() {
	local label="$1" ref="$2" file="$3"
	if [[ ! -f $ref || ! -f $file ]]; then
		printf 'CHECK %s status=missing-file\n' "$label"
		return 0
	fi
	if grep -qiE 'nan|inf' "$file"; then
		printf 'CHECK %s status=nan-or-inf\n' "$label"
		return 0
	fi
	local a b verdict
	a="$(average_data_line "$ref")"
	b="$(average_data_line "$file")"
	verdict="$(
		awk -v a="$a" -v b="$b" -v tol="$TOL" 'BEGIN{
			na = split(a, A, " "); nb = split(b, B, " ")
			if (na != nb) { print "status=field-mismatch"; exit }
			worst = 0
			for (i = 1; i <= na; i++) {
				if (A[i] !~ /^-?[0-9]/ || B[i] !~ /^-?[0-9]/) continue
				d = A[i] - B[i]; if (d < 0) d = -d
				s = (A[i] < 0) ? -A[i] : A[i]; if (s == 0) s = 1
				if (d / s > worst) worst = d / s
			}
			printf "max_rel_dev=%.3e status=%s", worst, (worst <= tol) ? "same" : "DIFFERS"
		}'
	)"
	printf 'CHECK %s %s\n' "$label" "$verdict"
}

# Cheap data-race canary: every thread count must reproduce the p=1 averages
# within TOL. Reordered float sums after parallelisation can legitimately move
# the last digits; a NaN or a large jump is a bug, not rounding.
determinism_check() {
	section "determinism cross-check (data-race canary, not a physics test)"
	local ref
	ref="$(ls -1 "$results_dir"/p1_r1/*_average.txt 2>/dev/null | head -n 1)" || true
	if [[ -z ${ref:-} ]]; then
		note "no p=1 rep=1 reference run in this sweep; skipped"
		return 0
	fi
	local dir file
	for dir in "$results_dir"/p*_r*; do
		[[ -d $dir ]] || continue
		[[ $dir == "$results_dir/p1_r1" ]] && continue
		file="$(ls -1 "$dir"/*_average.txt 2>/dev/null | head -n 1)" || true
		if [[ -z ${file:-} ]]; then
			continue
		fi
		compare_run "${dir##*/}" "$ref" "$file"
	done
}

perf_work() {
	build_prof
	mkdir -p "$results_dir"
	if ! command -v perf >/dev/null 2>&1; then
		note "!! perf not on PATH — nothing recorded"
		return 0
	fi
	section "perf record — call graph, $FREQ samples/s"
	if (cd "$results_dir" && perf record -g -F "$FREQ" -o perf.data -- \
		"$workdir/mdprof" <"$workdir/inputdata.txt" >perf-run.log 2>&1); then
		note "perf record done"
	else
		note "!! perf record failed (permission?) — see $results_dir/perf-run.log"
		return 0
	fi
	((KEEP_TRAJ == 1)) || rm -f "$results_dir"/*_traj.xyz
	note "hotspots (perf report --stdio; the TUI needs an interactive terminal):"
	perf report -n --stdio -i "$results_dir/perf.data" | head -n 60 | sed 's/^/  /'
	section "perf stat — counters that exist on A64FX ('branches' is not supported)"
	(cd "$results_dir" && perf stat \
		-e task-clock,cycles,instructions,cache-references,cache-misses \
		-- "$workdir/mdprof" <"$workdir/inputdata.txt" >/dev/null) 2>&1 | sed 's/^/  /'
}

# ------------------------------------------------------------------ main ----
case "$MODE" in
help | -h | --help)
	usage
	exit 0
	;;
esac

if [[ "$arch" != "aarch64" && "$ALLOW_NON_ARM" != "1" ]]; then
	cat >&2 <<EOF
!! refusing to run on '$arch' — this job must execute on an ARM compute node.
   A binary built on the login node (x86-64) dies with 'Exec format error' on
   the compute node (context/measured/node.md). Submit it instead:

       sbatch remote/md.sbatch

   Local smoke test only (never for measurements): ALLOW_NON_ARM=1.
EOF
	exit 2
fi

if [[ "$ALLOW_NON_ARM" == "1" && "$arch" != "aarch64" ]]; then
	printf '\n***** local smoke test on %s — numbers are NOT valid *****\n' "$arch" >&2
fi

cd "$workdir"
if [[ ! -f src/MD.cpp || ! -f Makefile ]]; then
	printf '!! src/MD.cpp not found in %s — submit from the repo root\n' "$workdir" >&2
	exit 2
fi

provenance
load_modules

case "$MODE" in
build)
	build_tuned
	;;
timing)
	sweep
	determinism_check
	;;
perf)
	perf_work
	;;
*)
	printf '!! unknown MODE=%s\n\n' "$MODE" >&2
	usage >&2
	exit 2
	;;
esac

section "end"
note "job ${SLURM_JOB_ID:-<local>} finished after ${SECONDS}s"
note "artefacts in $results_dir"
