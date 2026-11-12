# pgXXXXX_pgYYYYY — Lennard-Jones MD (WA1, Phase 1)

## Correctness canary (local, after every optimization step)

`tools/compare_md_output.py` compares the known-good run's `cp_output.txt`
against the optimized build's and fails (exit 1) when differences are too
large to be floating-point reorder noise (legal reordering from
`-ffast-math`/reductions stays ≤ ~1e-13 here; real bugs — lost pairs,
races — show at ≥ 1e-5 already in the first rows, because both runs start
from identical conditions and the argon run is only 200 steps). The sibling
`cp_average.txt` (the graded artifact) is judged too. Pressure rows are
advisory only (discrete wall-bounce events); the averages carry the verdict.

```bash
# once (or when the inputs change): golden output from the untouched provided code
REPO="$(pwd)"
mkdir -p /tmp/mdcanary/golden
gcc -O3 -ffast-math src/baseline.cpp -lm -o /tmp/mdcanary/md
( cd /tmp/mdcanary/golden && /tmp/mdcanary/md < "$REPO/inputdata.txt" )

# after each optimization: rebuild (make), rerun (~70 s per run on a laptop), compare
mkdir -p /tmp/mdcanary/new
( cd /tmp/mdcanary/new && "$REPO/md" < "$REPO/inputdata.txt" )
python3 tools/compare_md_output.py /tmp/mdcanary/golden/cp_output.txt /tmp/mdcanary/new/cp_output.txt
```

Exit `0` = optimization kept the physics; `1` = errors listed — investigate
before keeping the optimization; `2` = a file is broken (truncation/NaN).
Golden and candidate must come from the **same machine and inputs**.
`--exact` requires bit-identical output — use it only on two runs of the
*same binary* as a determinism/race alarm. Tolerances and their rationale:
`python3 tools/compare_md_output.py --help`.

## Running on Deucalion

### One-time setup (login node, no allocation needed)

```
ssh deucalion
cd /projects/F202500010HPCVLABUMINHO/2026-2027cp/$USER   # the only writable space
git clone <this repo> work && cd work                    # or rsync your tree
mkdir -p /projects/F202500010HPCVLABUMINHO/2026-2027cp/$USER/logs
```

That `logs/` directory is mandatory: the job scripts ask Slurm to write
`logs/<jobname>-<jobid>.log` there, and a missing directory fails the job
before your script ever starts. If your workspace directory name and `$USER`
differ, edit the `#SBATCH --output` path in the `remote/*.sbatch` files.

### The scripts

| script | submit line | what the job does | artefacts |
|---|---|---|---|
| `remote/recon.sh` | run by hand on the login node (see its header) | one recorded recon transcript of node facts | transcript under `/projects` |
| `remote/md.sbatch` | `sbatch remote/md.sbatch` | build via the graded Makefile, then the `THREADS` × `REPS` timing sweep, one `RESULT threads=… wall_s=…` line per run | `results/<jobid>-timing/p<P>_r<R>/` + `logs/md-<jobid>.log` |
| `remote/perf.sbatch` | `sbatch remote/perf.sbatch` | separate `-g` profiling binary, `perf record -g`, full `perf report -n --stdio` | `results/<jobid>-perf/{perf.data,perf-report.txt,mdprof}` + `logs/md-perf-<jobid>.log` |

Timing and profiling are two separate jobs on purpose: profiling needs its own
binary and its own overhead budget, so mixing it into the timed job would
contaminate the number that is actually graded
(`context/topics/profiling-workflow.md`).

### The constants block — the only configuration

Each `remote/*.sbatch` is self-contained and bare enough to read top to
bottom: the constants at the top of the file (`THREADS`, `REPS`, `OPT` in
`md.sbatch`; `FREQ`, `THREADS`, `PROF_OPT` in `perf.sbatch`) are the
configuration, and `#SBATCH --time` is the only timeout. To change an
experiment, edit the constants block and resubmit — there are no submit-time
environment knobs (`--export=ALL,NAME=value`).

`#SBATCH --time` is a hard ceiling *and* a scheduling hint (short jobs
backfill sooner); ask for too little and the sweep is cut off. A job bills the
whole node (48 cores) for as long as it holds it, whatever it uses
(`context/notes/Boas_Praticas.md`). Keep `THREADS` ≤ `--cpus-per-task`:
oversubscribing invalidates the speedup curve rather than merely slowing it
down.

Keeping `perf` in a batch job has one trap: **`perf report` needs `--stdio`**,
because a batch job has no terminal for the TUI. Both scripts already do
this.

### Contract for future `remote/*.sbatch`

1. Same `#SBATCH` header fields, same order; only `-J` and `--time` differ.
2. `#!/bin/bash -l` + `set -euo pipefail` (batch shells don't inherit
   login-node modules; without `-l`, `module` is undefined).
3. One-paragraph header comment: what it is + the submit line.
4. Constants block at the top, clearly marked — no `--export` knobs.
5. Unconditional aarch64 guard (the login node is x86-64; a binary built there
   dies with "Exec format error" on the compute nodes —
   `context/measured/node.md`).
6. Results under `results/$SLURM_JOB_ID-<name>/`; `results/` stays gitignored.
7. Standalone: no `source` of other repo files. `#SBATCH --time` is the only
   timeout — no per-run `timeout`. Always `< inputdata.txt` (MD `scanf`s stdin)
   and `rm -f *_traj.xyz` after a run (multi-GB, never kept).

## Housekeeping

```
squeue --me                                   # your queue
scancel <jobid>                               # stop one job
sacct -j <jobid> --format=JobID,JobName,Elapsed,State,MaxRSS,CPUTime
billing                                       # what the allocation cost
```

- Results and logs are **not** committed: `results/`, `logs/`, `perf.data*`
  are gitignored. `/projects` is where they live; `$HOME` is file-count
  limited (`context/notes/Boas_Praticas.md`).
- To keep a measurement, copy the job log (and any distilled table) into
  `context/measured/<date>-<what>.txt` as a **new, never-edited** file, the
  convention documented in `context/README.md`.
- Build and measure only inside the allocation: the login node is not the
  target ISA (`context/measured/node.md`).
- Before committing anything that touches `context/`, run
  `bash context/check.sh`.
