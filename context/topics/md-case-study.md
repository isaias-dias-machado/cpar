# MD case study — theory→code map (facts + hazards, not the solution)

Sources: `src/MD.cpp` (this repo), `WA1_26-27.pdf p.1`, `MD_simulations.pdf`,
`equations.md` for the math. **Open questions are phrased for you to answer —
that analysis *is* the graded WA1 material.**

## Program anatomy (single file `src/MD.cpp`, 701 lines)

| function | lines | cost class | role | WA1-relevant fact |
|---|---|---|---|---|
| `main` | 101–406 | trivial | prompts (title/gas/T/ρ on **stdin**: `inputdata.txt` = `cp\nAr\n100\n35000`), argon branch sets conversions | `N = 5000` hardcoded at **l.227**; `MAXPART = 5001` at l. 67 |
| `initialize` | 408–450 | O(N^{1/3})³ | simple-cubic lattice seeding | calls `initializeVelocities` |
| `initializeVelocities` | 619–676 | O(N) | Maxwell distribution + CoM removal + temperature-scaling | uses `gaussdist()` ⇒ not thread-safe (static + `rand()`); runs once |
| `computeAccelerations` | 525–559 | **O(N²)** | i>j pair loop; f from `rSqd` even powers; updates both `a[i]`, `a[j]` | hot spot #1 (⇒ see the hazard list in `openmp-cheatsheet.md`) |
| `Potential` | 495–520 | **O(N²), all ordered pairs** | sqrt + two `pow` per pair | hot spot #2, *more expensive per pair* than #1 and counts each pair twice (equations.md item 2: the math counts `j>i` once) |
| `VelocityVerlet` | 562–617 | 2×O(N) + 1 call to #1 | move + half-kick → forces → half-kick → elastic walls (`psum/(6L²)`) | called once per timestep from the `for i≤NumTime` loop in main; `Print`/trajectory writes are commented out (l.606) |
| `Kinetic`, `MeanSquaredVelocity` | 474–492, 453–471 | O(N) | totals per step | reduction candidates |
| `gaussdist` | 679–701 | O(1) | Box–Muller from `rand()` | never parallelize |

## Timestep call chain (per step, `VelocityVerlet`)

```
VelocityVerlet(dt, iter, fp)
 ├─ move: r += v·dt + ½·a·dt² ; v += ½·a·dt          (MD.cpp:573-580)
 ├─ computeAccelerations()                           (l.582)
 ├─ second half-kick: v += ½·a·dt                    (l.584-588)
 └─ elastic walls: v flip + psum accumulation        (l.591-604)
```

Dependency chain matches the work/span picture (02CP:9): the positions
*must* be moved before the forces are recomputed, `V(t+dt)` requires the
*updated* accelerations before the second half-kick ⇒ one `parallel for` region
hosting the move stages atomically would still need an implicit barrier
between force computation and half-kick (06XX:9's implicit barrier).

## Input conversion (argon)

`timefac = 2.09618e-12`, `dt = 0.5e-14/timefac` (l.278), `NumTime = 200`
(l.279) — the time loop runs `NumTime + 1` iterations (`main:305`).
`Vol = N/(ρ·NAvol)`; box side `L = ∛Vol` natural units; the "liquid argon at
35000 mol/m³" that the prompt advertises (l.222–223) is exactly your
`inputdata.txt` density.

## Race hazards (identical to `openmp-cheatsheet.md` §"MD kernel")

1. `computeAccelerations` — the fused Newton-3rd pair update that writes
   `a[i]` and `a[j]` (l.554-555).
2. `Potential`/`Kinetic`/`MeanSquaredVelocity` scalar sums (need
   `reduction(+:...)`).
3. `gaussdist` static state (init path only).
4. wall-collision `psum` inside `VelocityVerlet` (l.591-604) — also
   reducible, but ordered by thread-chunking; note-the-contribution-per-face
   physical caveat 6·L² (see equations.md item 5).

## Line-number discrepancies to report (facts about *this* repo)

| WA1 slide says | this repo has | note |
|---|---|---|
| `N=200 in line 214` (antigo seed for cheap profiling) | `N = 5000` at **l.227** | course file lineage differs from the e-Learning one; to profile with small N temporarily edit l.227 |
| compiling `MDseqClaudeAI.cpp` | `src/MD.cpp` | `Profiling.pdf` predates this repo layout (also annex-B Makefile differences) |
