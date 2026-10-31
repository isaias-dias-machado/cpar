---
source:      03PC_MemHierarchy.pdf
pages:       10
type:        lecture
utility:     high
fidelity:    noisy p.2 (label texts from pasted figure 2.16 interleave)
topics:      [scalability-profiles, locality, cache, bandwidth, blocking]
wa1:         report
---

# Data management: memory hierarchy

## Page map
- p.2 **scalability profiles** (figure 2.16 from a textbook): four profile
  families — **ceiling**, **knee point**, **contention**, **coherence** — the
  knee/ceiling definitions come from the pasted figure text (⚠️labels only
  clear in the image); also the speedup (gain) definition; diagnosis path:
  critical path (serial fraction, schedule, #PUs) ⇒ ceiling.
- p.3 the performance equation on a multicore: instructions **flat** with
  threads, CPI **rises past ~8 threads**, giving the loss curve of naïve MM;
  second insight: real FLOP/s ≈ **10% of peak** = `#FLOPs/Texe` vs
  `#PUs×2×IPC×Fclk`.
- p.4 locality principle; spatial = neighbours in address space; temporal =
  same address soon again; `sum += a[i]` example.
- p.5 hierarchy overview: by software, by compiler, by hardware (OS).
- p.6 hierarchy in detail: allocation in virtual pages, **first-touch**
  placement of physical pages (data partitioning), caching replication,
  coherence hardware; data movement is the cost.
- p.7 multicore anatomy: private L1/L2 per PU, shared L3, coherence
  invalidates other PUs' copies, **memory bandwidth shared by all PUs**
  (L1 bandwidth scales, DRAM does not).
- p.8 Intel Raptor Cove example (P/E cores, L2/L3 sharing).
- p.9 making code cache-friendly: minimise cache misses / blocks transferred.
- p.10 **blocking/tiling** (transpose example, blocksize).

## Use it for
- Explaining why MD's O(N²) force kernel has a *memory component*: r, v, a
  are 3×N doubles and every pair touches all three arrays; per-thread
  bandwidth ≠ DRAM bandwidth.
- Explaining a slowing speedup curve with *contention* and *coherence*
  profiles instead of vague words (p.2).
- First-touch matters for array-of-per-thread accumulators (p.6).
