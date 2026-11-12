# AGENTS.md — pgXXXXX_pgYYYYY (Computação Paralela · WA1, Phase 1)

Mestrado students' repo for the **Parallel Computing** work assignment:
OpenMP-parallelizing a Lennard-Jones molecular-dynamics code of argon gas
and measuring it on the Deucalion ARM partition.
Normative source: [`context/WA1_26-27.pdf`](context/WA1_26-27.pdf) — read it via its
note card (`context/notes/WA1_26-27.md`) first; nothing here restates it.

## Repository map

| path | role | rules |
|---|---|---|
| `src/MD.cpp` | the case-study solver (701 lines, single file) | hot spots `computeAccelerations` and `Potential`; current `N` value/line drift: `context/topics/md-case-study.md` |
| `Makefile` | graded build | **do not restructure**; see the constraint list below |
| `inputdata.txt` | stdin feed: title(`cp`), gas(`Ar`), T(100 K), ρ(35000 mol/m³) | keep the 4-line order of `scanf`s |
| `context/` | knowledge base (indexed course PDFs) | see `context/README.md`; entry point `context/INDEX.md` |
| `remote/` | operator-run Deucalion scripts: `recon.sh` (recon), `md.sbatch` (build/timing/perf runner) | agent writes, **operator runs**; usage in `README.md` |
| `tools/compare_md_output.py` | local canary: did an optimization change the output beyond FP-reorder noise? | agent-written dev tool; usage in `README.md`; not part of the graded build |
| `README.md` | build/run/submit usage | documents workflow only; every fact links into `context/` |

## Hard constraints (WA1:1–2 — these are normative, not advice)

1. Single `Makefile` at repo root that builds `./md`; sources live in `src/`.
2. `make run` launches the parallel binary reading `inputdata.txt` on stdin.
3. `export OMP_NUM_THREADS ?= <best>` inside the Makefile (`?=` = overridable).
4. `-fopenmp` mandatory; build target graded on **GCC/15.2.0, ARM node**;
   also suggested: `-march=native` (and `-g -fno-omit-frame-pointer` when
   profiling — a separate profile build is acceptable).
5. Data races = **strong penalty** (three weighted parts: `context/notes/WA1_26-27.md` §3).
6. Submission: zip → 2-page IEEE report + `src/` + `Makefile` (+ assets it
   needs). No executables, no binary-byproduct committed to git.
   Deadline: `context/notes/WA1_26-27.md` §5.

## Build & run (local, before anything goes to the cluster)

```
make            # default goal 'md'
make run        # ./md < inputdata.txt
make clean
```

## Deucalion

Node facts (cores, CMG topology, ISA/SVE, memory, compiler, partition size,
`perf` status) are **measured, not slide-derived**:
`context/measured/node.md`. Do not restate them here.

- **The agent never connects** (see the access section below). All commands
  here are for the operator.
- Rules of use, session, modules, workspace and quota: `context/notes/Boas_Praticas.md`.
- **Build on the node, never on `ln*`**: the login node is not the target ISA
  (`context/measured/node.md`), so a binary compiled there will not run on
  `cna*`.
- Profiling: recipe in `context/topics/profiling-workflow.md` (`perf` first;
  Score-P/Cube is optional).

## Deucalion access (non-negotiable)

- The agent (LLM) has **no access** to Deucalion: no `ssh`, `scp`, `srun`,
  `sbatch`, no keys, no tunnels, no remote filesystem mounts.
- The interface is **script-mediated**: the agent writes/edits scripts under
  `remote/`, tells the operator exactly what to run, and reads back only the
  transcript the operator commits under `context/measured/`.
- The operator runs everything; `remote/recon.sh` and
  `context/topics/profiling-workflow.md` are operator runbooks, not agent
  actions.

## Context-reading protocol (before answering any technical question)

1. `context/INDEX.md` → catalogue or term/question index gives you the file+page.
2. `context/notes/<pdf>.md` → the 30-line card for that PDF.
3. `context/topics/*.md` → synthesized fact sheets that already *cite* anchors.
4. Only then open the PDF — and only the cited page (see
   `context/FIDELITY.md` for dump-lossy pages and the fixed equation list in
   `context/equations.md`).
5. `_text/*.txt` are greppable haystacks with provenance headers; never cite
   from them for pages flagged lossy/noisy.
6. `context/measured/` holds facts we **measured** on a dated machine, not
   slide claims. Read `measured/node.md` (distilled) and cite its `L<n>`
   anchors into the dated raw transcript; never restate those facts elsewhere.

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
- Do not invent hardware numbers for A64FX — slides never state FLOPs for it.
  Measured facts live in `context/measured/node.md`; anything not there is
  unmeasured (cache sizes, SVE vector length and HBM2 bandwidth are still
  gaps — say so rather than estimating).
- Do not connect to Deucalion in any way (see "Deucalion access"): reply to
  any "try it there" request with a script/command list for the operator.
