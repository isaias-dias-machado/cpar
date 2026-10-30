---
source:      MD_simulations.pdf
pages:       6
type:        theory
utility:     high
fidelity:    lossy p.3-4 (equations are images -> read ../equations.md)
topics:      [lennard-jones, verlet, md-model, boundaries]
wa1:         report
---

# MD simulations — theory of the case study (Sobral)

Geométrico da simulação / model outline: N particles obey Newton's laws;
each particle feels forces from the other N-1; classical approximation of a
real gas (argon here).

## What each page contains
- **p.1** motivation: protein folding, thin films, nano devices; full code
  skeleton reference.
- **p.2** the **Lennard-Jones potential** φ(r)=4ε[(σ/r)¹²−(σ/r)⁶] with
  *r* = pair distance, ε = well depth ("field depth"), σ = zero of the field;
  typical values: ε=σ=1 in natural units (graph: interaction energy vs r).
- **p.3** the simulation model, as **equation images** (use `../equations.md`):
  system energy V+K; pair-sum potential; forces as the gradient of the
  potential; Velocity-Verlet updates for r(t) and v(t); question of borders →
  periodic (replicate) or other techniques.
- **p.4** scale anecdotes: tobacco mosaic virus (1M atoms, NAMD);
  P-Found L55P-TTR ("doença dos pezinhos") 44k atoms on 8-12 Pentium-4 for
  4-6 weeks; trajectory file sizes.
- **p.5** SARS-CoV-2 all-atom model, 4000 Frontera nodes, Gordon Bell 2020.

## Use it for
- Report introduction: one paragraph on what the solver does, with the three
  equations from `equations.md` (potential, force, Verlet) — citable as
  `MD_simulations.pdf p.2-3`.
- Sensitivity: *why* timestep matters (dt is fixed per gas in the code).

## Do not use it for
- Implementation details: this file never mentions the code's global arrays,
  `MAXPART`, or I/O; for that see `../topics/md-case-study.md`.
