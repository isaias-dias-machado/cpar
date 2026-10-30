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
- p.1 levels of parallelism by granularity: **ILP** (instructions, SIMD) →
  **threads** (focus of the lecture) → **processes** (cluster).
- p.2 explicit parallel computing: **shared memory** system: single address
  space, SMT counts cores, **memory bandwidth shared by all cores**,
  cache coherence unresolved by programmer.
- p.3 **distributed memory** per node; bandwidth ≈ proportional to #nodes.
- p.4–5 logical (time-sliced) vs physical parallelism; scheduling cost =
  thread creation + context switches; result varies run to run.
- p.6–7 single-core multithreading styles: **coarse-grain** (switch on long
  stall or time slice — incl. OS), **fine-grain** (switch every cycle — GPUs),
  **SMT** (simultaneous issue).
- p.8 GPU hardware scheduling: registers allocated at thread creation, fast
  switch, cap on thread count; multithreading hides memory latency.

## Use it for
- Only if the report needs one paragraph of "why thread-level parallelism on
  a multicore is the right level here" (p.1–2). Everything else is phase-2
  GPU material.
