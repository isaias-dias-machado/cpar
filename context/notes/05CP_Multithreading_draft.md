---
source:      05CP_Multithreading_draft.pdf
pages:      9
type:        lecture (draft)
utility:     low (background only)
fidelity:    clean prose (figure pages p.1,5,8)
topics:      [ilp, threads, scheduling, smt, gpu-mt]
wa1:         none (deepest background)
---

# Shared-memory programming (1): multithreading

## Page map
- p.1–2 levels of parallelism by granularity: **ILP** (instructions, SIMD) →
  **threads** (focus of the lecture) → **processes** (cluster); software vs
  hardware view.
- p.3 shared-memory parallel systems: single address space, SMT counts as
  cores, **memory bandwidth shared by all cores**, cache coherence
  unresolved by the programmer.
- p.4 **distributed memory** per node; bandwidth ≈ proportional to #nodes.
- p.5 programming-abstractions example (a process with 2 threads).
- p.6 logic vs physical parallelism (time-slicing).
- p.7 executing multiple threads on a single core; scheduling cost =
  thread creation + context switches (OS vs hardware scheduling).
- p.8 single-core multithreading styles: coarse-grain, fine-grain, **SMT**
  (4-way ILP example).
- p.9 GPU architecture: registers allocated per thread, fast switch, cap on
  thread count; multithreading hides memory latency.

## Use it for
- Only if the report needs one paragraph of "why thread-level parallelism on
  a multicore is the right level here" (p.1–3). Everything else is phase-2
  GPU material.
