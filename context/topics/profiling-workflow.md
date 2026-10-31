# Profiling workflow — from the course guides, adapted to this repo

Sources: `Profiling.pdf p.2–4` (commands), `WA1_26-27.pdf p.2 Annex A` (flags),
`Boas_Praticas.pdf` (session etiquette), plus the measured node facts in
[`../measured/node.md`](../measured/node.md). Connecting and running are now
allowed; the 48-core billing rule while an allocation is open is not suspended.

## Before any measurement (record in the report)
Node identity, core count, memory, compiler version and `perf` status are
**already measured** — cite [`../measured/node.md`](../measured/node.md)
instead of re-probing. Two rules that follow from it: the thread ceiling is
whatever that file says (it is the whole node), and **build and run inside the
allocation**, never on a login node — its ISA is not the target ISA.
- inputs fixed: `inputdata.txt` (`cp\nAr\n100\n35000` → title, gas=Ar,
  Tinit=100 K, ρ=35000 mol/m³). N is the `N = 5000` constant
  (`src/MD.cpp:227`) — **temporary** edit for the profiling seed
  (N=200, cf. `WA1:2` note), restore before final measurements.

## Step 1 — baseline sequential profile (sampling, cheap)

```
ml GCC
# dedicated profiling build: debug symbols, exact attribution
g++ -O3 -g -fno-omit-frame-pointer src/MD.cpp -o mdprof
# 1000 samples/s for a ~2 min run is plenty (slide says -F 1000)
perf record -F 1000 ./mdprof < inputdata.txt
perf report -n                 # hotspot list, % of samples per function
perf record -g -F 1000 ./mdprof < inputdata.txt
perf report -n                 # call-graph view; 'E' expands
```

Expect to find the pair-intensity functions (`computeAccelerations`,
`Potential`) dominating; `Kinetic`, `MeanSquaredVelocity` and the I/O are
O(N) and negligible.

## Step 2 — call-tree with instrumentation (Score-P + Cube)

```
ml Score-P
scorep g++ -O3 -fopenmp src/MD.cpp -o mdsp        (scorep wraps the compiler)
./mdsp < inputdata.txt                            # writes scorep-*/
ml CubeGUI
cube profile.cubex     # Metric tree -> time ; Call tree -> hotspots
```

Score-P *instruments* — it changes the timing budget; use it for the
per-function share picture, not for the final timings (cf. `profiling.pdf p.4`).

## Step 3 — parallel timing sweep (the graded number)

- Decide a data-collection ritual **on one node** to keep the machine noise
  comparable: fixed `inputdata.txt`, same node type, 3–5 repetitions
  (`-r 5` habit from `PL01:2`), median reported.
- Threads: 1, 2, 4, 8, 12, 16, 24, 32, 48 (48 = A64FX node core count,
  `Boas_Praticas.pdf p.2`).
- Kill the run when it repeats: an interactive 48-core slot keeps billing
  whole minutes (`Boas_Praticas.pdf p.8`).

## Reporting artefacts (link to theory)
- core-hours/step: `Texe/Timesteps·N` — model vs measured (`01CP:10-11`).
- speedup table S(P) = T(1)/T(P) (`02CP:5`), with the serial fraction and the
  *measured* span argument (`02CP:8`).
- scalability profile guess: ceiling (bandwidth/critical path) vs knee/contention
  (`03PC:1`).
- perf FLOP/a: peak per node (`Boas:2`) vs measured FLOP/s, roofline placement
  (`PL03:1`).
