# Performance models — formulas you can *use* in the report

Normative purpose, from `WA1_26-27.pdf p.2`: the report must "include strong
scalability analysis, profiling and other models and metrics that explain the
results". These are the course's own models, with source anchors.

## 1. Processor performance equation (01CP:14–15, 02CP:4, PL01:1)

$$T_{exe} = \#I \times \text{CPI} \times T_{cc}$$

(#instructions, cycles/instruction, clock-period). On a multicore, #I still
grows with the problem; CPI grows with *contention*: naïve MM stalls past
8 PUs (03PC:2) — that measured behaviour is the template for presenting your
speedup table: **why** is the curve shaped like that (link a model *term* to
each deviation point).

## 2. Speedup & Amdahl (02CP:5–7)

- speedup `S(P) = T_best_sequential / T_parallel(P)`.
- bounded by the serial fraction f: `Smax = 1/(1−f)`; with 95% parallel,
  Smax = 20.
- corollary: *the program's hot-spot defines the effort frontier* — profile
  first (`initial profile with N=200` per `WA1:2`).

## 3. Work & span bound (02CP:8–9)

`T_P ≥ span`; `S_P ≤ work/span` — the *algorithmic* bound; report your
estimation of the span for the chosen parallelization (e.g. the per-step
critical path move → forces → half-kick) alongside the benchmark.

## 4. Peak performance identities (04CP:5, 04CP:11, Boas:2)

- per PU: `Peak = #PEs × 2(FMA) × Fclk` (the RTX-5090 example: 21760×2×2017 M).
- per system: `Peak = #cores × SIMDlen × IPC × Fclk` (SIMDlen = #lanes).
- The ARM-node numbers are **measured** — see
  [`../measured/node.md`](../measured/node.md); do not restate them here.
  Plug `SIMDlen` in only once the SVE vector length is measured (it is listed
  there as a known gap, not a guess).

## 5. Roofline (PL03:1)

Intensity = FLOP/s ÷ Byte/s of the kernel, against the machine's roof:

```
perf ceiling           _________
              ________/
mem ceiling_/         ↑ knee at ArithmeticIntensity(bytes/FLOP) = Peak_FLOPs/BW
```

Rough arithmetic for the MD pair loop (`rSqd` even powers, per pair):
#FLOP ≈ 2×3 (dists) + 1−2 (scalar f) + 2×3 (a[i],a[j]) ≈ 12–13 FLOP/pair;
#bytes ≈ 6 doubles read + 6 double-accumulate writes ≈ 96 B/pair worst-case —
so the kernel sits deep on the *memory-floor* side; the roofline sketch
(`PL03:1 p.1`; model described `PL03:2` notes) justifies treating DRAM
bandwidth as the first-order explanation if the speedup curve saturates
*below* 48 cores. **HBM2 bandwidth is still unquantified** — a known gap in
[`../measured/node.md`](../measured/node.md), not a number to copy
(`Boas_Praticas p.2` only says 32 GB HBM2, "50% faster").

## 6. Scalability profiles (03PC:1)

Diagnosis vocabulary for the discussion section of the report:
*ceiling* (hard hardware limit: critical path, bus, interconnect),
*knee point* (profile change at some #PUs), *contention* (shared resource),
*coherence* (cache invalidation traffic). Choose which of these explains
your observed curve — every claim anchored in a `perf stat` metric or figure.

## 7. Numerical-precision caveat (04-Notas p.3; 04CP:4)

Mixed precision is not required for WA1 phase 1, but the *summation-order*
changes with reductions/`max(len)` — write the caveat with the same
underflow/overflow vocabulary used for accelerators (one sentence is enough
for a 2-page IEEE report).
