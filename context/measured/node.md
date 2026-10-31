# Deucalion ARM node — measured facts (WA1 phase 1)

**Provenance.** Measured `2026-10-31T18:24:13Z → 18:25:18Z` (WET) on node
`cna0022`, partition `normal-arm`, account `f202500010hpcvlabuminhoa`, job
`2172610`, with [`remote/recon.sh`](../../remote/recon.sh) at commit `c2a7b7e`.
Raw output: [`2026-10-31-recon.txt`](2026-10-31-recon.txt) — **never edited**, so
the `L<n>` anchors below stay valid forever. A later run lands in a *new* dated
file and adds rows here; it never rewrites this one.

Anchors are line numbers in that file. `class` = `stable` (a hardware/toolchain
property that will not change under us) or `snapshot` (true at measurement time
only; re-measure before quoting).

| fact | value | class | anchor | consequence for WA1 |
|---|---|---|---|---|
| build host is NOT ARM | login node `ln04`, kernel `…x86_64` | stable | L12-17 | `make` on `ln04` produces an x86-64 `./md` → `Exec format error` on `cna*`. **Build and run only inside the allocation.** |
| CPU | Fujitsu `A64FX`, `aarch64`, 48 CPUs, 1 thread/core | stable | L66-84 | `OMP_NUM_THREADS` ceiling = 48; no SMT, so 48 threads = 48 cores |
| topology | 4 CMG × 12 cores; NUMA 0-11 / 12-23 / 24-35 / 36-47 | stable | L72-84 | first-touch placement and thread affinity are first-order (see `topics/memory-locality.md`) |
| ISA | `sve` present; **no `sve2`, no `bf16`, no `i8mm`** | stable | L85, L90 | `-march=native` can only target ARMv8.2-A + SVE-1: it cannot buy SVE2/matmul extensions |
| chip id | implementer `0x46` (Fujitsu), part `0x001` (A64FX) | stable | L91-94 | confirms the part in the report's hardware table |
| memory | 31 GiB HBM2 + 15 GiB swap | snapshot | L102-105 | the slides' "32 GB HBM2" holds; swap existing means an oversubscribed run can silently slow down |
| compiler | `gcc (GCC) 15.2.0`; modules GCCcore/15.2.0, binutils 2.45, zlib 2.3.2 | snapshot | L107-118 | exactly the graded toolchain (`WA1:2`) — quote this line in the report |
| OpenMP default | no `OMP_*` set ⇒ libgomp uses all 48 threads | snapshot | L2017-2018 | the Makefile's `OMP_NUM_THREADS ?= N` overrides a default of 48, not 1 |
| profiler | `/usr/bin/perf` works unprivileged; `branches` event `<not supported>` | snapshot | L2020-2040 | `perf stat`/`record` are usable; do not put branch counts in the report |
| partition size | 1612 nodes visible in `normal-arm`, `cna0021`–`cna1632`, timelimit 2 days | snapshot | L27-33 | slides say 1632 nodes / `cna0001-1632`: `cna0001`–`cna0020` were not in this partition. Cite the naming range, not "1632 nodes" |
| queue | `squeue --me` empty; the 48-core probe started immediately | snapshot | L35-36, L60-61 | interactive `srun` can start at once; still bills 48 cores while open |
| workspace | `/projects/…/2026-2027cp/mei.2026.pg65416` exists, group-writable, 4.7 T free | snapshot | L38-47 | path spelling confirmed; no quota pressure at this scale |
| home quota | 454 files (limit 25 000) | snapshot | L49-50 | nothing needs to live in `$HOME` |
| account | `f202500010hpcvlabuminhoa` (suffix `a` = ARM) | snapshot | L53-55 | correct `-A` for every `srun`/`sbatch`; association is partition-agnostic, so `-p normal-arm` must be explicit |

## Known gaps (the probe could not answer these — do not read absence as fact)

- **Cache hierarchy: unknown.** `lscpu` (L66-85) prints no L1/L2/L3 at all on
  this EL8/4.18 kernel, and `/proc/cpuinfo` (L87-95) has no cache fields.
- **SVE vector length: unmeasured.** `sve` in the flags proves the extension
  exists, not how many bytes per vector. Needs `svcntb()` compiled **on the
  node** (it is an ARM binary).
- Consequence: `topics/performance-models.md` §4 (peak `#cores × SIMDlen × IPC
  × Fclk`) and §5 (roofline knee = peak FLOP/s ÷ bandwidth) stay unquantified
  until a follow-up reconnaissance measures vector length and memory bandwidth.
- Also unmeasured: NUMA distances (`numactl -H`), real clock under load.

## Deliberately not distilled

`ml avail` (~1 890 lines, L123-2013): only `MAQAO`, `acfl`, `armperformance-
libraries`, `PAPI`, `OpenBLAS`/`FFTW` (GCC-15.2.0 builds) are worth a second
look; everything else is noise here. Also skipped: `/proc/cpuinfo` beyond the
chip id, swap sizing, `ml list` trivia. All of it is still in the raw file —
grep it rather than re-running.
