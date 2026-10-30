---
source:      02CP_parallelism.pdf
pages:       11
type:        lecture
utility:     high
fidelity:    noisy p.9,11 (overlapping figure text; Amdahl formula drawn as vector art)
topics:      [speedup, amdahl, dependencies, work-span, map-reduce, granularity]
wa1:         report
---

# Introduction to parallelism

## Page map
- p.1–2 revisit of the optimization *cycle*: profile → metrics → models →
  change → validate. "BAD: start by editing source — that is guessing."
- p.3 latency vs throughput/bandwidth (lower latency better; higher
  throughput better; related by `Th = 1/L` in some cases).
- p.4 processor performance equation `Texe = #I × CPI × Tcc`.
- p.5 speedup = T(best sequential) / T(parallel); **hot-spots** definition and
  the warning that hot-spots *shift* as you optimize.
- p.6–7 speedup curves (ideal vs real, knee at ~8 threads in the example) and
  the Amdahl message: with 95% parallel the cap is `S = 1/(0.05 + 0.95/N)` → 20.
- p.8 **work & span** (McCool figure): work = total computation, span =
  critical path; both bound speedup; superlinear impossible in this model.
- p.9 dependency graph example `z=(x−y)*(x+y)` plus text (⚠️ overlap-figure).
- p.10 granularity levels (ILP → statements → functions → program); data vs
  control dependencies.
- p.11 **function vs data parallelism**; map/reduce as the two canonical data
  patterns (⚠️ overlap-figure: Stanford CS149 & McCool excerpts).

## Use for the report
- Section "methodology": justify *why* you profiled before parallelizing
  (`p.1-2, 5`), cite Amdahl with your measured serial fraction.
- Use **work/span** language for three call-level dependency constraints:
  init → forces → positions; see `topics/md-case-study.md`.
