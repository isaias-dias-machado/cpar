# pgXXXXX_pgYYYYY — Lennard-Jones MD (WA1, Phase 1)

## Running on Deucalion

### One-time setup (login node, no allocation needed)

```
ssh deucalion
cd /projects/F202500010HPCVLABUMINHO/2026-2027cp/$USER   # the only writable space
git clone <this repo> work && cd work                    # or rsync your tree
mkdir -p /projects/F202500010HPCVLABUMINHO/2026-2027cp/$USER/logs
```

That `logs/` directory is mandatory: `remote/md.sbatch` asks Slurm to write
`logs/<jobname>-<jobid>.log` there, and a missing directory fails the job
before your script ever starts. If your workspace directory name and `$USER`
differ, edit the `#SBATCH --output` path in `remote/md.sbatch`.

Seeing the knob list without submitting (works anywhere):

```
MODE=help bash remote/md.sbatch
```

### First run: calibrate the wall clock

`#SBATCH --time` is a hard ceiling *and* a scheduling hint (short jobs backfill
sooner). Ask for too little and the sweep is cut off; ask for a week and you
wait. Measure one run first:

```
sbatch -J probe --export=ALL,MODE=timing,THREADS=1,REPS=1 remote/md.sbatch
squeue --me
tail -f /projects/F202500010HPCVLABUMINHO/2026-2027cp/$USER/logs/probe-*.log
```

The log's `RESULT` line gives you one serial wall time; multiply as needed for
the `--time` of the real sweep. Note that a job bills the whole node (48 cores)
for as long as it holds it, whatever it uses (`context/notes/Boas_Praticas.md`).

### The three modes

| command | what the job does | artefacts |
|---|---|---|
| `sbatch -J build --export=ALL,MODE=build remote/md.sbatch` | `make clean && make CFLAGS="$OPT"`, then `file ./md` so you can see it is an `aarch64` binary | log only |
| `sbatch -J timing --export=ALL,THREADS="1 2 4 8 12 16 24 32 48",REPS=3 remote/md.sbatch` | build, then every thread count × repetition, then a cross-thread determinism check | one `RESULT` line per run + `results/<job>-timing/p<P>_r<R>/` |
| `sbatch -J perf --export=ALL,MODE=perf,FREQ=1000 remote/md.sbatch` | separate `mdprof` build (`$PROF_OPT`) into the results dir, `perf record -g` + `perf stat` (each under `RUN_TIMEOUT`, `OMP_NUM_THREADS=PERF_THREADS`), full `perf report --stdio` in `perf-report.txt` | `results/<job>-perf/{perf.data,perf-report.txt,mdprof}` |

Two separate jobs on purpose: profiling needs its own binary and its own
overhead budget, so mixing it into the timed job would contaminate the number
that is actually graded (`context/topics/profiling-workflow.md`).

Keeping `perf` in a batch job has one trap: **`perf report` needs `--stdio`**,
because a batch job has no terminal for the TUI.

### Knobs (never edit the script to change an experiment)

Pass any of them with `--export=ALL,NAME=value` — comma-free values only.

| knob | default | meaning |
|---|---|---|
| `MODE` | `timing` | `build`, `timing`, `perf`, `help` |
| `OPT` | `-O3 -ffast-math -fopenmp -march=native` | flags for the graded build path (`make CFLAGS=...`) |
| `PROF_OPT` | `-O3 -fopenmp -march=native -g -fno-omit-frame-pointer` | flags for the perf-only binary |
| `THREADS` | `1 2 4 8 12 16 24 32 48` | sweep points, one process each |
| `REPS` | `3` | repetitions per point (report the median) |
| `FREQ` | `1000` | perf samples per second |
| `PERF_THREADS` | `48` | `OMP_NUM_THREADS` for the perf-mode run (whole node) |
| `RUN_TIMEOUT` | `350` | seconds allowed per single run (timing reps and each perf command); a timeout is logged as `exit=124` and the sweep continues |
| `TOL` | `1e-6` | relative tolerance for the determinism canary |
| `KEEP_TRAJ` | `0` | `1` keeps `*_traj.xyz` — multi-GB per run, off by default |
| `RESULTS_DIR` | `<repo>/results/<job>-<mode>` | where per-run directories go |
| `OMP_PROC_BIND` / `OMP_PLACES` | `close` / `cores` | thread placement; the first-order knob on a CMG-based node (`context/topics/memory-locality.md`) |

Useful `sbatch`-side overrides: `-J <name>` (log file name), `--time=HH:MM:SS`,
`--cpus-per-task` (default: one whole node — see `context/measured/node.md`).

Keep `THREADS` ≤ `--cpus-per-task`: oversubscribing invalidates the speedup
curve rather than merely slowing it down.

### Comparing flag sets

```
sbatch -J o3 --export=ALL,OPT="-O3 -fopenmp" remote/md.sbatch
sbatch -J o3native --export=ALL,OPT="-O3 -fopenmp -march=native" remote/md.sbatch
```

One variable per comparison, and read `compiler` + `sources` from the log
before believing two numbers are comparable — the provenance block exists to
make that check automatic.

### The determinism canary

`MODE=timing` compares every `*_average.txt` against the `p=1` run and prints
`CHECK <dir> max_rel_dev=... status=same|DIFFERS`. This is a data-race canary
(races carry a strong penalty, `context/notes/WA1_26-27.md` §3), **not** a
physics test: parallel floating-point sums reorder legitimately, so a small
`DIFFERS` after parallelisation is expected — `nan`, `inf` or a large jump is
a bug.

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
