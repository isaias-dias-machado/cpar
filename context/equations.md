# Equations — transcribed from `MD_simulations.pdf p.3–4`

⚠️ These are **not present in the text layer** of the PDF (equations are
embedded as images; `_text/MD_simulations.txt` gives garbage there). They were
transcribed from rendered page images — read on 2026-10-30 with
`pdftoppm -f 3 -l 4 -png MD_simulations.pdf`. To re-verify, re-render the
same pages and read them side-by-side with this file.

## The three model equations (p.3–4)

1. **Lennard-Jones potential** *(p.3, native units)*

   $$\varphi(r) = 4\varepsilon\left[\left(\frac{\sigma}{r}\right)^{12} - \left(\frac{\sigma}{r}\right)^{6}\right]$$

2. **Potential energy of the system** *(p.4, note j > i ⇒ each pair counted once)*

   $$V(r_1,\dots,r_N) = \sum_i \sum_{j>i} \varphi\!\left(\lvert \mathbf{r}_i - \mathbf{r}_j \rvert\right)$$
   $$K(t) = \frac{1}{2}\sum_i m_i \, [\mathbf{v}_i(t)]^2$$

3. **Force = gradient of the potential** *(p.4, magnitude of the radial form)*

   $$\mathbf{F}(r) = -\nabla V(r) = 4\varepsilon \left( 12\,\frac{\sigma^{12}}{r^{13}} - 6\,\frac{\sigma^6}{r^7} \right) \hat{\mathbf{r}} \;=\; 24\varepsilon \left(2\frac{\sigma^{12}}{r^{13}} - \frac{\sigma^{6}}{r^{7}}\right)\hat{\mathbf{r}}$$

4. **Velocity-Verlet time step** *(p.4 — the integration the code performs)*

   $$\mathbf{r}(t+\Delta t) = \mathbf{r}(t) + \mathbf{v}(t)\,\Delta t + \tfrac{1}{2}\mathbf{a}(t)\Delta t^2$$
   $$\mathbf{v}(t+\tfrac{\Delta t}{2}) = \mathbf{v}(t) + \tfrac{1}{2}\,\mathbf{a}(t)\,\Delta t \quad\text{(half kick)}$$
   $$\mathbf{a}(t+\Delta t) = \mathbf{F}(\mathbf{r}(t+\Delta t))/m \quad\text{(recompute)}$$
   $$\mathbf{v}(t+\Delta t) = \mathbf{v}(t+\tfrac{\Delta t}{2}) + \tfrac{1}{2}\,\mathbf{a}(t+\Delta t)\,\Delta t \quad\text{(second half kick)}$$

5. **Elastic walls** *(from `WA1_26-27.pdf p.1` text + `src/MD.cpp:591-604`,
   not typeset in the slides): if `r[i][j] < 0` or `r[i][j] >= L` then the
   corresponding velocity component flips `v[i][j] *= -1`, and the instantaneous
   pressure contribution to the wall collisions of the step is accumulated as
   `psum += 2·m·|v|/dt`; the function returns `psum / (6·L²)` — 6 faces × face
   area = total wall area: dimensionally consistent [Pa].
   (*Replica/periodic boundary conditions* are mentioned on `MD_simulations
   p.4` but *not* what this code does.)

## Symbol map — slide ↔ `src/MD.cpp`

| slide symbol | code form (in `computeAccelerations`, `src/MD.cpp:537-558`) | note |
|---|---|---|
| σ, ε set to **1** in natural units | σ=ε=m=kB=1 literals at `MD.cpp:52-55` | the branch table converts to SI only for *outputs* (`TempFac`, `PressFac`, `timefac`) |
| $r$ | `rnorm` would give it, but the code never takes √: it uses `rSqd` (r²) directly | O(r) powers stay even: r⁻¹⁴, r⁻⁸ ⇒ no sqrt in the hot path |
| $\hat{\mathbf{r}}$ (unit vector) | `rij[k] = r[i][k] - r[j][k]` — *unnormalized* | the 1/r factors are folded into the scalar below |
| $\mathbf{F}/m$ (acceleration) | `f = 24*(2*pow(rSqd,-7) - pow(rSqd,-4))` = $24\left(2r^{-14}-r^{-8}\right)$ | then `a[i][k] += rij[k]*f; a[j][k] -= rij[k]*f` (Newton's 3rd law is applied *manually* per pair) |
| $24ε(2σ^{12}/r^{13} - σ^6/r^7)$ | `24*(2/rSqd⁴⁺³ − 1/rSqd⁴)` × `rij[k]/r` ⇒ exactly eq. 3 divided by m | ✅ consistent: `pow(rSqd,-7)=r⁻¹⁴`, `pow(rSqd,-4)=r⁻⁸` |
| dt per gas | `dt = 0.5e-14 / timefac` (Ar ⇒ `MD.cpp:278`), `NumTime = 200` | He: `0.2e-14`, `NumTime=50000` |

## Consequences for WA1 (hooks, not answers)

- The force kernel is **integer-power-of-rSqd only** — a vectorization-friendly
  form if data layout allows (contrast with `Potential()`, which does
  `sqrt` + `pow(quot,12)+pow(quot,6)` per *ordered* pair `j≠i` — every pair
  twice, per `MD.cpp:501-517`).
- `computeAccelerations` writes **both** `a[i]` and `a[j]` from a single
  loop instance (Newton's 3rd law fused) — parallelizing the i-loop creates a
  *write-write race across loop iterations*; see
  `topics/openmp-cheatsheet.md` for candidate clauses and the decision
  questions they raise.
- The *pair sum* in eq. 2 counts `j > i` once; the code's `Potential()`
  counts every ordered pair — the report can analyse this duality (and it is
  also a purely *sequential* optimization candidate, no OpenMP needed).
