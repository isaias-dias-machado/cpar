---
source:      01CP_Introduction.pdf
pages:      15
type:        lecture 0
utility:     medium
fidelity:    clean prose (p.4-5 book covers, p.13 figure)
topics:      [course-organization, models, methodology, benchmarks]
wa1:         methodology
---

# Course introduction (Sobral, 2026/27)

## Page map
- p.1 team/administrative; documentation on MEI BB, key `cp2627`.
- p.2 **grading**: written test 40% (minimum 5.0), intermediate work
  (i.e. WA1) 10%, final work 50%.
- p.3 lab schedule: JS = PL1+PL3, RS = PL4+PL2; search cluster = 2×20-core
  Intel + K20 GPUs; **Minho advanced computing center: 48-core ARM (A64FX),
  NVidia Ampere GPUs (A100)**.
- p.3–7 textbooks (Gerry/Algebraic, McCool patterns, CUDA textbook).
- p.8 background assumed: imperative programming + computer architecture.
- p.9 why parallelism: single-thread performance stalled around 2000; the
  answer is parallel software.
- p.10 **WA definition**: "solve this problem, on this computer, for this
  input, as fast as possible", graded on correct solution + good performance;
  *understanding* via models and metrics is the emphasis.
- p.11 performance optimization **cycle** (benchmark → profile → model →
  change → validate) with the "never start by editing code" message.
- p.12–14 metric levels (application → ISA → digital logic); the questions
  "how/what to measure".
- p.14–15 performance equation worked micro example (movl/addl loop, CPI 1.5,
  2 GHz ⇒ 24 ns).

## Use it for
- Framing dates (matches `WA1`), grading weights, and the engineering mindset
  the report should demonstrate; don't cite this for MD or OpenMP facts.
