#!/usr/bin/env bash
#
# remote/recon.sh — Deucalion recon runbook (WA1 Phase 1, Lennard-Jones MD)
#
# PURPOSE
#   Collect, in one recorded transcript, every Deucalion fact the assignment
#   needs but that must not be *invented*: the Slurm account name, the
#   normal-arm partition state, the workspace path spelling, the A64FX
#   topology/flags as the node itself reports them, the GCC version actually
#   loadable, and whether `perf` is usable. The operator runs it; nothing here
#   connects anywhere.
#
# INVARIANTS
#   * Run by the operator on Deucalion (login node, then one short allocated
#     job). This script never opens a connection on its own.
#   * Everything is tee'd into one transcript file so no result is retyped.
#   * The transcript is written under the /projects workspace, never to $HOME
#     (home is limited to 25k files — context/notes/Boas_Praticas.md p.8).
#   * Part 2 runs for at most 10 minutes: an interactive/allocated job bills
#     48 cores even when one is used (context/notes/Boas_Praticas.md p.8, p.11).
#
# FAILURE MODES
#   * No ARM account associated with $USER  -> Part 2 is skipped, a hint is
#     printed; exit status 0 (Part 1 facts are still valid).
#   * srun unavailable / rejected / times out -> recorded in the transcript and
#     the script exits non-zero.
#   * $USER different from the workspace directory name -> the probe prints
#     both spellings instead of hiding the mismatch.
#   * A single probe failing never aborts the run; it is marked "!!" inline.
#
# USAGE
#   ./recon.sh                     # Part 1, parse account, then Part 2
#   ./recon.sh -A f202500010hpcvlabuminhoa
#   ./recon.sh --part1-only        # free login-node facts only
#   ./recon.sh -o /tmp/recon.txt   # override the transcript path
#
set -uo pipefail

HPC_PROJECT_ROOT="/projects/F202500010HPCVLABUMINHO/2026-2027cp"
PARTITION="normal-arm"
ALLOCATION_MINUTES="00:10:00"
CORES_PER_NODE="48"

account_override=""
transcript_override=""
part1_only=0

usage() {
	sed -n '/^# USAGE/,/^#$/p' "$0" | sed 's/^# \{0,1\}//; s/^#$//'
}

while (($# > 0)); do
	case "$1" in
	-A)
		account_override="${2:-}"
		shift 2 || { usage >&2; exit 2; }
		;;
	-o)
		transcript_override="${2:-}"
		shift 2 || { usage >&2; exit 2; }
		;;
	--part1-only)
		part1_only=1
		shift
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		printf 'recon.sh: unknown argument %s\n\n' "$1" >&2
		usage >&2
		exit 2
		;;
	esac
done

# The workspace is the only place we are allowed to grow files.
workspace_dir="${HPC_PROJECT_ROOT}/${USER}"
transcript="${transcript_override:-${workspace_dir}/deucalion-recon.txt}"

if [[ -z "$transcript_override" ]] && ! mkdir -p "$workspace_dir" 2>/dev/null; then
	transcript="${PWD}/deucalion-recon.txt"
	printf 'recon.sh: cannot create %s, writing transcript to %s instead\n' \
		"$workspace_dir" "$transcript" >&2
fi

# Transcript goes to the file *and* to the terminal: a silent run looks hung.
exec > >(tee -a "$transcript") 2>&1

section() { printf '\n===== %s =====\n' "$*"; }

# probe <command...>: run it, record it, keep going if it fails.
probe() {
	printf '\n$ %s\n' "$*"
	"$@" || printf '!! command exited %s\n' "$?"
}

section "recon transcript"
printf 'started:   %s\n' "$(date -Is)"
printf 'transcript: %s\n' "$transcript"
printf 'user:       %s\n' "${USER:-?}"
printf 'home:       %s\n' "$HOME"
printf 'workspace:  %s\n' "$workspace_dir"

section "part 1 — login-node facts (no allocation, free)"
probe date
probe hostname
probe uname -a
probe sacctmgr show assoc where user="$USER" format=Account,Partition,QOS,MaxJobs
probe sinfo -p "$PARTITION"
probe squeue --me
probe ls -la "$workspace_dir"
probe df -h "$workspace_dir"

printf '\n$ find %s | wc -l   # home file-count guard: must stay under 25000\n' "$HOME"
find "$HOME" 2>/dev/null | wc -l

# Accounts ending in 'a' are the ARM ones (f202500010hpcvlabuminhoa);
# context/notes/Boas_Praticas.md p.8. Preferred parse uses `-P` (parsable,
# '|'-separated); the fallback covers Slurm builds that ignore `-P`.
parsed_account="$(
	sacctmgr -n -P show assoc where user="$USER" format=Account 2>/dev/null |
		awk -F'|' '{print $1}' |
		sed 's/^[[:space:]]*//; s/[[:space:]]*$//' |
		grep -E 'a$' |
		head -n 1
)"
if [[ -z "$parsed_account" ]]; then
	parsed_account="$(
		sacctmgr -n show assoc where user="$USER" format=Account 2>/dev/null |
			awk '{print $1}' |
			grep -E 'a$' |
			head -n 1
	)"
fi
account="${account_override:-$parsed_account}"

section "account resolution"
printf 'parsed from sacctmgr: %s\n' "${parsed_account:-<none>}"
printf 'override (-A):        %s\n' "${account_override:-<none>}"
printf 'using:                %s\n' "${account:-<none>}"

if ((part1_only)); then
	section "part 2 — skipped (--part1-only)"
	printf 'run again without --part1-only to collect the node facts\n'
	exit 0
fi

if [[ -z "$account" ]]; then
	section "part 2 — skipped (no ARM account resolved)"
	cat <<'EOF'
No account ending in 'a' was associated with this user, so the allocated
probe was NOT submitted. Confirm the ARM account and re-run:

    ./recon.sh -A <account>

Part 1 facts above are still valid.
EOF
	exit 0
fi

# Payload run *inside* the allocation. `bash -l` so that /etc/profile defines
# the `ml` module function; `set +e` so one failing probe does not hide the rest.
job_payload=$(
	cat <<'JOB_PAYLOAD'
set -uo pipefail
report() {
	printf '\n$ %s\n' "$*"
	"$@" || printf '!! command exited %s\n' "$?"
}
report hostname
report lscpu
printf '\n$ head /proc/cpuinfo\n'
head /proc/cpuinfo || printf '!! head /proc/cpuinfo failed\n'
report nproc
report free -g
printf '\n$ ml purge && ml GCC && gcc --version\n'
ml purge && ml GCC && gcc --version || printf '!! module load of GCC failed\n'
printf '\n$ ml list\n'
ml list || printf '!! ml list failed\n'
printf '\n$ ml avail\n'
ml avail || printf '!! ml avail failed\n'
printf '\n$ printenv | grep -i ^OMP   # recorded default, not tuned\n'
printenv | grep -i '^OMP' || printf '(no OMP_* variable set in this job)\n'
printf '\n$ which perf\n'
which perf || printf '!! perf not on PATH\n'
printf '\n$ perf stat true\n'
perf stat true || printf '!! perf stat failed (check permission settings)\n'
JOB_PAYLOAD
)

section "part 2 — allocated probe (bills ${CORES_PER_NODE} cores for the whole job)"
printf 'account: %s · partition: %s · time: %s · cores: %s\n' \
	"$account" "$PARTITION" "$ALLOCATION_MINUTES" "$CORES_PER_NODE"
printf 'node-side module probe runs under `bash -l` so `ml` is defined\n'

srun -A "$account" \
	--time="$ALLOCATION_MINUTES" \
	--nodes=1 \
	--ntasks=1 \
	--cpus-per-task="$CORES_PER_NODE" \
	-p "$PARTITION" \
	bash -lc "$job_payload"
srun_status=$?

section "end"
printf 'finished:  %s\n' "$(date -Is)"
printf 'srun exit: %s\n' "$srun_status"
if ((srun_status != 0)); then
	printf 'Part 2 failed; Part 1 facts above are still valid.\n'
fi
exit "$srun_status"
