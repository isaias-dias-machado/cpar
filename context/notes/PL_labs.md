---
source:      PL00_MXX.pdf, PL01_MXX.pdf, PL02_MXX.pdf, PL03_MXX.pdf, PL04_MXX.pdf
pages:       3,5,2,2,2
type:        lab guides
utility:     method templates
fidelity:    clean
topics:      [perf-stat, metrics, locality, vectorization, openmp-lab]
wa1:         methodology
---

# Lab guides PL00–PL04 (method templates, matrix-multiplication based)

⚠️ All five labs use the **matrix multiplication (MM)** case study and the
**SeARCH** front-end (`s7edu.di.uminho.pt`, partition `cpar`) — **not** MD and
**not** Deucalion. Value for WA1 = *transferable procedure*, not content.

## PL00 — environment + first metrics (`PL00_MXX.pdf`)
- p.1 goals: compile/run on a compute node (`srun --partition=cpar ./a.out`);
  write a C MM supporting large N, split into functions (init / multiply /
  validate) to get a clean profile; measure wall time; explain why `time
  srun` is inaccurate; the `-O3` gain; introduce `perf stat` (+ `-e
  <event>` from `perf list`).
- p.2–3 annexes: access steps, helper MM code.

## PL01 — metrics ↔ Texe (`PL01_MXX.pdf`) · 5 pp
- p.1 goals: identify `#I / CPI / Tcc` inside `perf stat` output; complexity
  O(N³); what changes when N doubles; data vs function parallelism;
  dependencies limit parallelism.
- p.2–5 exercises: `perf stat ./a.out`; compare 512² vs 1024² (`-r 5`);
  O0→O3 gain attributed to #I or CPI; phase-wise complexity; profiling
  (`perf stat -r`), annex MM code.

## PL02 — data locality (`PL02_MXX.pdf`) · 2 pp
- p.1 spatial vs temporal locality in the DOT version of MM; estimate L1
  misses analytically; fix via **transpose** of A and/or B; quantify with
  `perf stat -e L1-dcache-load-misses -M cpi` (512², `-O2`).
- p.2 annex: base MM code.

## PL03 — vectorization + roofline (`PL03_MXX.pdf`) · 2 pp
- p.1 why the compiler cannot vectorize the DOT kernel (read patterns, but
  also: no guaranteed unit-stride, plus accumulation across j); loop
  *reorderings* that enable vectorization; `[int-pane]` gains for SIMDlen 2
  and 4; build with `-ftree-vectorize -msse4`; and the **roofline model**
  relating arithmetic intensity to the memory-bottleneck ceiling.
- p.2 annex: naive MM triple loop.

## PL04 — OpenMP hands-on (`PL04_MXX.pdf`) · 2 pp
- p.1 semantics of `parallel` region (`num_threads(2)`), thread ids via
  `omp_get_thread_num()`; constraints of `single`, `master`, `barrier`;
  build: `module load gcc`, `gcc -O2 -fopenmp ex41.c`,
  `srun --partition=cpar --cpus-per-task=2 ./a.out`.
- p.2 exercise source `ex41.c`.

## Transfer to WA1 (report templates)
| from the labs | reuse in WA1 as |
|---|---|
| PL00's "profile each *phase*" | profile `computeAccelerations`, `Potential`, `VelocityVerlet` separately |
| PL01's `Texe = #I×CPI×Tcc` on two sizes | strong-scalability table per thread count |
| PL02's "spatial locality per array, 3 arrays" | the 6 distance/force arrays movement pattern |
| PL03's roofline sketch | intensity ≈ 2 FLOP/pair vs 24 B/pair — see `topics/memory-locality.md` |
| PL04's output-ordering questions | reasoning about which MD loops admit `parallel for` |
