---
source:      01CP_Introduction.pdf
pages:      15
type:        lecture 0
utility:     medium
fidelity:    clean prose (p.4-8 book covers, p.13 figure)
topics:      [course-organization, models, methodology, benchmarks]
wa1:         methodology
---

# Course introduction (Sobral, 2026/27)

## Page map
- p.1 team/administrative (title slide).
- p.2 course schedule + **grading** (course grade: written test 40%, minimum
  5.0; intermediate work — i.e. WA1 — 10%; final work 50%); MEI BB key `cp2627`.
  (WA1's *internal* 30/30/40 split is a different fact — `WA1_26-27.md` §3.)
- p.3 lab schedule: JS = PL1+PL3, RS = PL4+PL2; SeARCH cluster = 2×20-core
  Intel + K20 GPUs; **Minho advanced computing center: 48-core ARM (A64FX),
  NVidia Ampere GPUs (A100)**.
- p.4–8 textbooks (Key textbook 1–4, p.4–7; Recommended textbook, p.8).
- p.9 background assumed: imperative programming + computer architecture.
- p.10 why parallelism: single-thread performance stalled around 2000; the
  answer is parallel software.
- p.11 **WA definition**: "solve this problem, on this computer, for this
  input, as fast as possible", graded on correct solution + good performance;
  *understanding* via models and metrics is the emphasis.
- p.12 performance optimization **cycle** (benchmark → profile → model →
  change → validate) with the "never start by editing code" message.
- p.13 how/what to measure.
- p.14 metric levels (application → ISA → digital logic).
- p.15 performance equation worked micro example (movl/addl loop, CPI 1.5,
  2 GHz ⇒ 24 ns).

## Use it for
- Framing dates (matches `WA1`), grading weights, and the engineering mindset
  the report should demonstrate; don't cite this for MD or OpenMP facts.
