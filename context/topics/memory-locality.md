# Memory & locality — what it means for the MD kernel

Sources: `03PC_MemHierarchy.pdf` (locality), `04CP_Acc_draft.pdf p.13-15`
(vectorization(data layout)), `PL02`/`PL03` (how to *measure*). All claims
below anchored.

## The hierarchy in one paragraph (03PC:2–6)
per-PU private L1/L2, shared L3, coherent caches, **DRAM bandwidth shared by
all PUs** (L1 bandwidth scales with cores; DRAM does not). Data placement:
virtual pages → physical via **first-touch** (03PC:5) — the allocating core
keeps the page ⇒ array-of-threads-private accumulators placed right can live
in the correct socket path.

## Spatial / temporal locality — localidade espacial/temporal (03PC:3)
- spatial: **consecutive addresses** touched in sequence (row-major roving)
- temporal: same address soon again (blocked kernels, reused accumulators)

## Applying it to `src/MD.cpp` (facts to analyse, questions to answer)

1. **Data layout** `double r[MAXPART][3], v, a, F` (MD.cpp:67–75):
   interleaved per-particle — a *natural* AoS. Per pair, the hot loops touch
   6 cache lines (r[i], r[j]) and force out-of-order writes into `a[i]`/`a[j]`.
   Two *complementary* questions (report, step (ii) — alternatives):
   - would a per-*thread* private `a` accumulator (one array of 3N per
     thread) turn the fused pair update of `computeAccelerations` into
     race-free work? and at what reduction cost at the end of the loop?
   - if restructured to SoA (`r[3][N]`), do the inner k-loops become unit
     stride (compiler-vectorizable, cf. 04CP:14-15: the canonical
     *AoS never vectorizes; SoA does* argument)?
2. **Movement per pair**: `rij` temp is the only contiguity-friendly item;
   `r` is read 6× per pair (both i and j coordinates); the *locality*
   quality of the O(N²) i-j loop is high on r[i] (row reused over the inner
   j loop) but low on r[j] (col-major roving pattern) — quantify with
   `perf stat -e L1-dcache-load-misses,cycles -M cpi` after PL02's recipe
   (`PL02:1`).
3. **Blocking possibility**: pair blocking (tile i-range × j-range so each
   tile's `r` rows stay in L1/L2) mirrors PL02's transpose argument
   (`PL02:1 p.1` annex, `03PC:9` blocking) — an *alternative* to present, cost
   = extra bookkeeping for the same pairwise logic.
4. **The 48-core ceiling**: A64FX/HBM2 (Boas:2) — memory bandwidth does not
   scale with threads ⇒ *contention* profile (`03PC:1`) is the predicted
   shape; say it *before* measuring, then check.

## Normative note for the report
Per `WA1_26-27.pdf p.1`, step (iii) demands a *"selection justified by a
scalability analysis"* — this file's numbers (bytes/FLOP, miss rates) are the
inputs; `topics/performance-models.md` has the framework, `Profiling`'s
command set has the measurement (`ML`).
