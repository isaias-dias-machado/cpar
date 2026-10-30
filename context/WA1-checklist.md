# WA1 — Phase-1 checklist (from `WA1_26-27.pdf`, the normative file)

Deadline **25-Nov-26, 23:59**, submitted via e-learning as a single `zip`
that unzips to a dir named by the pair (`pgXXXXX_pgYYYYY/`).

## The compliance list

- [ ] **Report**: 2 pages of content (annexes excluded but may be read),
      IEEE conference template (ieee.org/conferences/publishing/templates.html),
      including:
      - hot-spot evidence from *before* optimization (N=200 seed note, WA1:p.2);
      - the alternatives considered inside each hot-spot (step ii);
      - the selected approach *justified by a scalability analysis* (step iii);
      - strong-speedup table/graph on the Deucalion ARM node (step v);
      - models/metrics discussion (Texe/Amdahl/roofline — see
        `topics/performance-models.md`);
      - a note on FP summation-order changes (reduction) as a numerical caveat.
- [ ] **Code**: everything in a `src/` subdir, no executables, no object files;
      the version history stays in *this* repo (`make` in the zip must build
      the *parallel* version).
- [ ] **Makefile** (no template change in spirit, per Annex A/B):
      - builds `md` **in the base directory**;
      - `CFLAGS`: `-fopenmp` **mandatory**, `-march=native` suggested,
        `-g -fno-omit-frame-pointer` if you need accurate `perf`
        (a profile-grade binary is OK to keep separate — justify in the report);
      - `export OMP_NUM_THREADS ?= <best>` (gradable best PU count; `?=` so
        the evaluator can override);
      - `run:` target, command is exactly what grading executes;
      - single Makefile in the base directory.
- [ ] **Reproducibility**: same input always (`inputdata.txt`: title, gas
      (`Ar`), T_init (100 K), ρ (35000 mol/m³)) — the program reads 4 lines
      from **stdin** (`scanf` sequence in `main`).
- [ ] **No data races** (30% weight, "strong penalty" straight off the slide).
- [ ] **Course weight**: WA1 is 10% of the course grade; the defence happens
      (`01CP:2`), the defence is the WA2 oral.

## Things that silently cost marks

| trap | why it matters |
|---|---|
| editing the *output format* of `*_output.txt`/*_average.txt* | the evaluator's report-check may compare printed quantities (`Temp`, `Press`) — structural format changes are a needless risk |
| removing the standalone O(N²) `Potential()` | keeps a pedagogical "what would the naive form cost" datapoint; consider *not* deleting it while optimizing |
| last-minute *uncommitted* changes | the report must cite code that exists → commit before zipping |
| wrong GCC version in the report's reproducibility section | graded build is **GCC/15.2.0 on an ARM compute node** (`WA1:p.2`) — record `gcc --version` and the module used |
| forgetting the `run` target's non-interactive stdin | grader runs `make run` exactly as specified |
