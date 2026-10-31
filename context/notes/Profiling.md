---
source:      Profiling.pdf
pages:      4
type:        ops guide
utility:     high
fidelity:    clean; screenshots p.2, p.4
topics:      [perf, score-p, cube, profiling, deucalion]
wa1:         methodology
---

# Profiling @ Deucalion (Malaca, Sobral, Silva, Oct 2026)

Four-page cheat sheet; extremely terse, but everything in it is a command you
will actually run. Adapted commands below are **for this repo's layout**
(`src/MD.cpp` on the assignment code, not the slides' `MDseqClaudeAI.cpp`).

⚠️ Every command here is for the **operator** to run inside a Deucalion
allocation; the agent never connects (root `AGENTS.md`).

## Page map
- p.1 context; GUI tools need X-forwarding (`ssh -X` or `-Y`).
- p.2 get the course project onto Deucalion and open an ARM session:
  - `cd /projects/F202500010HPCVLABUMINHO/2026-2027cp/<user>` · `quotaprojects`
  - `cp -r ../PLprojeto1/ .`
  - `srun --time=02:00:00 -p normal-arm -A <account> -n 1 --x11 --pty bash`
  - `ml GCC` · `g++ -O3 <file>` · `./a.out` (or `./a.out 500 50` on
    Score-P slide, i.e. reduced N/timesteps for profiling runs)
- p.3 **perf (sampling)**, two levels:
  - flat: `perf record -F 1000 ./a.out` then `perf report -n`
    (⚠️ the slide types `-F 1000./a.out` without a space — that is a
    **source typo**, keep the space);
  - call graph: `perf record -g -F 1000 ./a.out` then `perf report -n`;
    navigate with arrows, expand with `E`.
- p.4 **Score-P (instrumentation)**:
  `ml Score-P` → `scorep g++ -O3 <srcs>` → run → `ml CubeGUI` →
  `cube profile.cubex` → metric tree → call-tree hot spots.

## Corollaries for WA1
1. `-g -fno-omit-frame-pointer` help `perf` attribute samples to functions
   (`WA1:2 Annex A` says the same for the graded build; keep them *out* of the
   timed `=-O3` binary if you want the fastest, and profile a separate build).
2. Profile **before** optimizing with small params (see `WA1:2` note).
3. Sample size: `-F 1000` = 1000 samples/s; for a 2-minute run that is plenty.
