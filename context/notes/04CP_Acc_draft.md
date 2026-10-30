---
source:      04CP_Acc_draft.pdf
pages:      19
type:        lecture (draft)
utility:     medium (phase 2 bridge)
fidelity:    noisy p.6 (GPU table columns scrambled; figure-only p.5,7,10,17-19)
topics:      [simd, aos-soa, gpu, precision, vectorization]
wa1:         implementation (SIMD/SVE arguments only)
---

# Processing accelerators (SIMD, AVX/AMX, GPU primer)

## Page map — what to trust the dump for
- p.1 definition of accelerator (quoted from AI overview at bottom).
- p.2 Apple M4 SoC: area budget — CPU is dwarfed by GPU+NPU.
- p.4 performance vs precision graph: **lower FP precision ⇒ higher
  throughput** (log-scale graph).
- p.5 **RTX 50 family spec table. NEVER quote it from the dump** — column
  order is scrambled. Use only the page-bottom formula:
  `peak FP16 = #PEs × 2(FMA) × Fclk = 21760×2×2017×10⁶`; and the split
  *vector processing* (FP64/FP32/FP16) vs *matrix processing* (FP16/FP8/FP4).
- p.7 vector architecture cycle: load (gather) → registers → ALU → store
  (scatter); registers managed by the **compiler**.
- p.8 Flynn taxonomy: SISD/SIMD/MISD/MIMD.
- p.11 peak-performance equation: `Peak = #cores × SIMDlen × IPC × Fclk`;
  ideal `Texe = #I×CPI×Tcc / #cores` with `#Ivect = #I/SIMDlen`.
- p.12 concrete AVX: `vaddps` (8 floats) / `vaddpd` (4 doubles) per 256-bit reg.
- p.13 vectorization preconditions (the compiler's lens): [no data
  dependencies], control dependencies (predication/masks), arbitrary lengths,
  data alignments; "SIMD consumes much more data per instruction".
- p.14 **AoS fails to vectorize** (data is interleaved); p.15 **SoA
  vectorizes**.
- p.17–19 GPU SM organization (IEEE 2019 figure); Intel AMX matrix registers
  (tile register = 1 KiB, 16×64 B).

## Use it for
- Arguing SIMD-friendly data layout for the pair loop's inner k-vector
  (`rij` contiguous, inner k-loop) and why the compiler still refuses
  O(N²) loops with cross-iteration accumulation — see
  `topics/memory-locality.md`.
- **A64FX fact to verify *on node*** (slides never say it): SVE with
  length-agnostic VLEN, cf. p.14-15-vs `04-Notas_Estudo_Aceleradores.pdf p.1`.
