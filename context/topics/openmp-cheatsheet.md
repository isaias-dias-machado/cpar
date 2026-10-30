# OpenMP cheatsheet — course corpus + WA1 hazards

Source anchor: `_text/06XX-OpenMP_draft.txt` (clean). This is a reading aid
for `notes/06XX-OpenMP_draft.md`; WA1 mandates OpenMP (`WA1_26-27.pdf p.2`).

## Constructs, the subset this assignment needs

| constructo / construct | source | what it does | when *not* to use it |
|---|---|---|---|
| `#pragma omp parallel` | 06XX:6 | create/join a team once | creating it *inside* the time loop pays the fork-join barrier every step |
| `#pragma omp for schedule(...)` | 06XX:8 | split loop iterations | loops where iterations *write to shared state* (races), dependent iterations |
| `reduction(op:var)` | 06XX:16 | private partial + combine at end | reductions whose order changes FP results must be justified in the report |
| `#pragma omp atomic` | 06XX:15 | one memory update becomes atomic (cmpxchg spin) | many threads hammering the same address ⇒ serialized; use for rare updates only |
| `#pragma omp critical [name]` | 06XX:14 | mutual exclusion, global lock | same serialization, worse; fine for init/QA paths |
| `#pragma omp single` / `master` | 06XX:4 | one-thread regions | — |
| `barrier` / `nowait` | 06XX:8 | join points within a region | — |
| `#pragma omp task` (+`taskwait`) | 06XX:11–12 | DAG of tasks | probably unnecessary for 1 hot loop; cited for alternatives step (ii) |

## Schedules (06XX:8–9) — how to *choose*

| schedule | distribution | overhead | balance | typical fit |
|---|---|---|---|---|
| `static` (default) | fixed chunks, round-robin | lowest | good for uniform cost | pair loop with N known ⇒ predictable |
| `dynamic` (chunk) | hand out at run time | higher | best for irregular | ragged work, e.g. wall-collision counts |
| `guided` | shrinking chunks | medium | good | irregular unknown-cost |
| `auto` / dense default | runtime decides | — | — | comparing in experiments |

## Data sharing (06XX:13) — rules of thumb

- declared **inside** region ⇒ private; declared outside ⇒ shared.
- loop-local temporaries (`rSqd`, `rij[3]`, `f`) must not be shared; for-loop
  index variables are implicitly private in a `parallel for`.
- `firstprivate` initialises the private copy; `lastprivate` writes back the
  last iteration's value; `reduction` is the *only* race-free way to combine.

## Data-race hazards in the MD kernel (open questions — the design work is yours)

Anchors: `src/MD.cpp`; equations in `../equations.md`; race anatomy 06XX:15.

1. **`computeAccelerations` (MD.cpp:537-558)**: one pair (i,j) updates
   `a[i][k] += f·rij` **and** `a[j][k] -= f·rij`. Any naive `parallel for
   schedule(static) for i` lets two threads touch `a[j]`.
   Questions to answer in the report: which of (a) per-thread private
   acceleration arrays + reduction, (b) restructure to accumulate only `a[i]`
   (doubling work via `j<i` full pass), (c) alternative pairing (stride/
   coloring) scales best on **A64FX 48 cores**? — justification is required
   by WA1 step (iii) — `WA1_26-27.pdf p.1-2`.
2. **`Potential()` (MD.cpp:501) and `Kinetic()`/`MeanSquaredVelocity()`**: pure
   "read all, sum one scalar" ⇒ textbook reductions (06XX:16). Check that
   `Pot += 4*epsilon*(term1-term2)` reduction changes FP summation order —
   report as a numerical caveat (accuracy vs order, cf. mixed-precision notes
   `04-Notas_Estudo_Aceleradores p.3` for the conceptual family).
3. **`VelocityVerlet` (MD.cpp:573-604)** has *five* sequential stages (move,
   half-kick, forces, second half-kick, walls): partially parallelizable
   per-particle (each thread owns i-range), but the **force** stage must
   complete before the second half-kick — the dependency chain above is
   *control-free* but *data-dependent* (02CP:8-9 work/span).
4. **`gaussdist()` (MD.cpp:679)** uses `rand()` + `static` state ⇒ not
   thread-safe, only called from `initializeVelocities` (initialisation);
   state as-is: keep it out of parallel regions, or note in the report.
5. **I/O and printf** inside the simulator (`fprintf` of trajectory — is
   commented out, `MD.cpp:606`) — if re-enabled, must stay `master`/`single`.
