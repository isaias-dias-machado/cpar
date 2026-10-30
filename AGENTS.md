# AGENTS.md — pgXXXXX_pgYYYYY (Computação Paralela · WA1, Phase 1)

Mestrado students' repo for the **Parallel Computing** work assignment:
OpenMP-parallelizing a Lennard-Jones molecular-dynamics code of argon gas
and measuring it on the Deucalion ARM partition.
Normative source: [`context/WA1_26-27.pdf`](context/notes/WA1_26-27.md) — read it
via its note card first; nothing here restates it.

## Repository map

| path | role | rules |
|---|---|---|
| `src/MD.cpp` | the case-study solver (701 lines, single file) | hot spots `computeAccelerations` (l.525) and `Potential` (l.495); `N = 5000` hardcoded at l.227 (≠ WA1's "line 214") |
| `Makefile` | graded build | **do not restructure**; see the constraint list below |
| `inputdata.txt` | stdin feed: title(`cp`), gas(`Ar`), T(100 K), ρ(35000 mol/m³) | keep the 4-line order of `scanf`s |
| `context/` | knowledge base (indexed course PDFs) | see `context/README.md`; entry point `context/INDEX.md` |

## Hard constraints (WA1:1–2 — these are normative, not advice)

1. Single `Makefile` at repo root that builds `./md`; sources live in `src/`.
2. `make run` launches the parallel binary reading `inputdata.txt` on stdin.
3. `export OMP_NUM_THREADS ?= <best>` inside the Makefile (`?=` = overridable).
4. `-fopenmp` mandatory; build target graded on **GCC/15.2.0, ARM node**;
   also suggested: `-march=native` (and `-g -fno-omit-frame-pointer` when
   profiling — a separate profile build is acceptable).
5. Data races = **strong penalty** (30% weight is legibility+approach; 30% is
   execution time; 40% is report quality).
6. Submission: zip → 2-page IEEE report + `src/` + `Makefile` (+ assets it
   needs). No executables, no binary-byproduct committed to git.
   Deadline: **25-Nov-26 23:59**.

## Build & run (local, before anything goes to the cluster)

```
make            # default goal 'md'
make run        # ./md < inputdata.txt
make clean
```

## Deucalion (⚠️ DO NOT CONNECT YET — explicit operator instruction)

Everything below is *recorded for when this constraint is lifted*; no SSH,
no `srun`, no `scp` until told.
- Partition: `normal-arm` (nodes `cna00xx`), Fujitsu A64FX 48-core + 32 GB HBM2
  per node; rules of use: an interactive job bills 48 cores regardless of use
  (`context/notes/Boas_Praticas.md`).
- Canonical session: `srun -A <account> --time=48:00:00 --nodes=1 -p
  normal-arm --pty bash`; modules `ml GCC` (=15.2.0), `ml purge`.
- Workspace: `/projects/F202500010HPCVLABUMINHO/2026-2027cp/<user>` (home
  folder is quota-limited to 25k files).
- Profiling: `perf` (sampling) + Score-P/Cube recipe in
  `context/topics/profiling-workflow.md`.

## Context-reading protocol (before answering any technical question)

1. `context/INDEX.md` → catalogue or term/question index gives you the file+page.
2. `context/notes/<pdf>.md` → the 30-line card for that PDF.
3. `context/topics/*.md` → synthesized fact sheets that already *cite* anchors.
4. Only then open the PDF — and only the cited page (see
   `context/FIDELITY.md` for dump-lossy pages and the fixed equation list in
   `context/equations.md`).
5. `_text/*.txt` are greppable haystacks with provenance headers; never cite
   from them for pages flagged lossy/noisy.

Report-side references live in `context/WA1-checklist.md`; the
pt-pt ⇄ en-us vocabulary map is `context/glossary.md` (defence is usually in
Portuguese — bilingual terminology is expected).

## Git workflow (operator rules — non-negotiable)

- Feature work on `agent/<short-name>` branches; **never commit to `master`
  directly**; tree stays clean between tasks (untracked `context/` etc. must
  be committed or `gitignore`d before the next task).
- Commit messages: imperative, one concern per commit; before committing run
  `bash context/check.sh` when `context/` changed, and `make` when `src/` or
  the `Makefile` changed.

## Anti-patterns (never do these)

- Do **not** silently change the physics (`dt`, timestep schedule, the
  output files' `fprintf` formats) — output *values* are the graded
  correctness (`*_average.txt`).
- Do **not** treat `context/_text/` dumps as ground truth (headers tell you
  which pages are lossy); cite PDF page anchors instead.
- Do **not** rename `md`/`make` targets or add targets the graded Makefile
  does not specify without a report-side justification.
- Do not invent hardware numbers for A64FX — slides never state FLOPs for
  it; verify on node when access opens.
- Do not ssh or scp into Deucalion (see above) — reply to any "try it there"
  request with a recorded command list instead of a connection attempt.
