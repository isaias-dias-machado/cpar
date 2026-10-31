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
- p.1 goals: access the SeARCH cluster and run on a `cpar` node; build a C MM
  in functions (init / multiply / validate); measure wall time and why
  `time srun` is inaccurate; `-O3` gain; introduce `perf stat`.
- p.2 exercises: `perf stat -M flops`, `perf record` sampling (4000 samples/s
  by default), optimized variants.
- p.3 Annex 2: instructions for the SeARCH cluster (ssh, `srun`).

## PL01 — metrics ↔ Texe (`PL01_MXX.pdf`) · 5 pp
- p.1 goals: identify `#I / CPI / Tcc` inside `perf stat` output; complexity
  O(N³); what changes when N doubles; data vs function parallelism;
  dependencies limit parallelism.
- p.2 Exercise 3: `std::thread` data parallelism, speedup with 4/8/16
  threads (512²), `srun --cpus-per-task=40`.
- p.3 Annex 1: SeARCH instructions (`module load gcc/11.2.0`,
  `gcc -g -fno-omit-frame-pointer -O2 …`).
- p.4 Annex 3: `std::thread` example; p.5 Annex 4: Pearson-coefficient code.

## PL02 — data locality (`PL02_MXX.pdf`) · 2 pp
- p.1 Exercise 1 spatial locality in the DOT version of MM; estimate L1
  misses analytically; fix via **transpose**; `perf stat -e
  L1-dcache-load-misses -M cpi`.
- p.2 Exercise 2: impact of representation (array of pointers) and parallel
  speedup with 16 threads; Exercise 3 temporal locality.

## PL03 — vectorization + roofline (`PL03_MXX.pdf`) · 2 pp
- p.1 Exercise 1 compiler-based vectorization: why the compiler cannot
  vectorize the DOT kernel; loop reorderings that enable it; SIMDlen 2/4
  gains; `-ftree-vectorize -msse4`.
- p.2 Exercise 2: the **roofline model** (peak performance vs arithmetic
  intensity), applied to the `ikj` MM variant.

## PL04 — OpenMP hands-on (`PL04_MXX.pdf`) · 2 pp
- p.1 goals + basic constructs: `parallel` region (`num_threads(2)`), thread
  ids via `omp_get_thread_num()`, `single`/`master`/`barrier`;
  build `gcc -O2 -fopenmp ex41.c`; `srun --partition=cpar
  --cpus-per-task=2 ./a.out`.
- p.2 Exercise 2: work-sharing and synchronization (`for`, `master`,
  `single`, `barrier`) inserted into the exercise-1 code.

## Transfer to WA1 (report templates)
| from the labs | reuse in WA1 as |
|---|---|
| PL00's "profile each *phase*" | profile `computeAccelerations`, `Potential`, `VelocityVerlet` separately |
| PL01's `Texe = #I×CPI×Tcc` on two sizes | strong-scalability table per thread count |
| PL02's "spatial locality per array, 3 arrays" | the 6 distance/force arrays movement pattern |
| PL03's roofline sketch | intensity ≈ 2 FLOP/pair vs 24 B/pair — see `topics/memory-locality.md` |
| PL04's output-ordering questions | reasoning about which MD loops admit `parallel for` |
