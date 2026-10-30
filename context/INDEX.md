# Index — `context/`

The routing table for this corpus. Read **only what you need**: catalogue row →
note card → (rarely) the PDF page itself. Provenance and extraction fidelity:
[`FIDELITY.md`](FIDELITY.md). Raw dumps: [`_text/`](_text/).

## A. Catalogue (16 files)

| PDF | pp | tipo / type | utilidade / utility for WA1 | fidelity | note card |
|---|---|---|---|---|---|
| `WA1_26-27.pdf` | 2 | assignment | **normative** | clean | [`notes/WA1_26-27.md`](notes/WA1_26-27.md) |
| `MD_simulations.pdf` | 6 | theory (LJ/Verlet) | high | lossy p.3–4 | [`notes/MD_simulations.md`](notes/MD_simulations.md) |
| `01CP_Introduction.pdf` | 15 | lecture 0 | medium | clean prose | [`notes/01CP_Introduction.md`](notes/01CP_Introduction.md) |
| `02CP_parallelism.pdf` | 11 | lecture | high | noisy p.9,11 | [`notes/02CP_parallelism.md`](notes/02CP_parallelism.md) |
| `03PC_MemHierarchy.pdf` | 10 | lecture | high | noisy p.2 | [`notes/03PC_MemHierarchy.md`](notes/03PC_MemHierarchy.md) |
| `04CP_Acc_draft.pdf` | 19 | lecture (draft) | medium (phase 2) | noisy p.6 | [`notes/04CP_Acc_draft.md`](notes/04CP_Acc_draft.md) |
| `04-Notas_Estudo_Aceleradores.pdf` | 3 | study notes (pt-pt) | medium | clean | [`notes/04-Notas_Estudo_Aceleradores.md`](notes/04-Notas_Estudo_Aceleradores.md) |
| `05CP_Multithreading_draft.pdf` | 9 | lecture (draft) | low | clean prose | [`notes/05CP_Multithreading_draft.md`](notes/05CP_Multithreading_draft.md) |
| `06XX-OpenMP_draft.pdf` | 19 | lecture (draft) | **high (implementation)** | clean | [`notes/06XX-OpenMP_draft.md`](notes/06XX-OpenMP_draft.md) |
| `Boas_Praticas.pdf` | 15 | ops guide | high (logistics) | clean prose | [`notes/Boas_Praticas.md`](notes/Boas_Praticas.md) |
| `Profiling.pdf` | 4 | ops guide | high (method) | screenshots p.2,4 | [`notes/Profiling.md`](notes/Profiling.md) |
| `PL00_MXX.pdf` | 3 | lab guide | method template | clean | [`notes/PL_labs.md`](notes/PL_labs.md) |
| `PL01_MXX.pdf` | 5 | lab guide | method template | clean | [`notes/PL_labs.md`](notes/PL_labs.md) |
| `PL02_MXX.pdf` | 2 | lab guide | method template | clean | [`notes/PL_labs.md`](notes/PL_labs.md) |
| `PL03_MXX.pdf` | 2 | lab guide | method template | clean | [`notes/PL_labs.md`](notes/PL_labs.md) |
| `PL04_MXX.pdf` | 2 | lab guide | method template | clean | [`notes/PL_labs.md`](notes/PL_labs.md) |

## B. Page index (file : page → tópico / topic)

### `WA1_26-27.pdf` — the assignment 🟥
- p.1: learning outcomes · MD/argon case study (FoleyLab origin) · LJ potential, Velocity Verlet, elastic walls · the 5-step methodology (profile → alternatives → select+scalability → implement on Deucalion ARM → measure) · groups of 2 · zip layout `pgXXXXX_pgYYYYY` · 2-page IEEE report · sources in `src/` · single `Makefile` → `md` · `make run` · deadline **25-Nov-26**, defence in Jan'27 (WA-Phase 2)
- p.2: evaluation weights: exec time on ARM (**30%**, `OMP_NUM_THREADS ?= N` in Makefile) · approach + legibility + **no data races** (**30%**, "strong penalty") · report: scalability/profiling/models (**40%**) · Annex A: Makefile extension rules (`?=`, override) · flags: `-fopenmp` mandatory, `-march=native` suggested, `-g -fno-omit-frame-pointer` for `perf` · **compiled with GCC/15.2.0 on an ARM node** · Annex B: the provided Makefile · profiling tip: seed with small N (e.g. 200) — ⚠️ slide says "line 214"; in *this* repo `N = 5000` is hardcoded at `src/MD.cpp:227`

### `06XX-OpenMP_draft.pdf` — core API 🟧
- p.1: what OpenMP is (directives + runtime + env vars; fork-join)
- p.2: programmer owns correctness: races, deadlock, load balance
- p.3: master thread/team model; default thread count
- p.4: directive syntax; `parallel`, `for`, `sections`, `single`
- p.5: `task`; `master`, `critical`, `barrier`, `taskwait`, `atomic`, `flush`, `ordered`
- p.6: `parallel` syntax + data-clause teaser
- p.7: nested parallelism → outdated, use **tasks**
- p.8: `for` work-sharing; `schedule(static|dynamic|guided|auto)`, chunk size; implicit barrier
- p.9: static vs dynamic trade-off; "which schedule?" exercise
- p.10: `ordered` clause
- p.11–12: sections → tasks; task construct, `taskwait`
- p.13: **data sharing**: locals vs shared; `private` / `firstprivate` / `lastprivate` / `reduction(op:var)`
- p.14: `critical` (mutual exclusion, named, global lock)
- p.15: **critical vs atomic** + assembly of the race and the `cmpxchg` loop
- p.16: **reduction** example; thread reuse across regions (one `parallel`, many `for`s)
- p.17: env vars `OMP_SCHEDULE`, **`OMP_NUM_THREADS`**, `OMP_DYNAMIC`, `OMP_STACKSIZE`, `OMP_WAIT_POLICY`, `OMP_THREAD_LIMIT`…
- p.18: runtime routines (`omp_get_thread_num`, `omp_get_wtime`, locks…)

### `02CP_parallelism.pdf` — performance vocabulary 🟧
- p.1–2: optimization cycle ⇒ profile first, never guess
- p.3: latency vs throughput (bandwidth)
- p.4: `Texe = #I × CPI × Tcc`
- p.5: speedup = T_best_seq / T_par; hot-spots corollary of Amdahl
- p.6: parallel speedup curves; Amdahl limit formula (95% → cap 20)
- p.7: (continuation)
- p.8: dependency graph, critical path, work/span, speedup bound (figure)
- p.9: semantic graph: x=a+b, y=b*7, z=(x−y)(x+y); dependency graph; schedule; ⚠️ `overlap-figure`
- p.10: granularity; data vs control dependencies
- p.11: function vs **data parallelism**; map/reduce in C++/Haskell/Scala; ⚠️ `overlap-figure`

### `03PC_MemHierarchy.pdf` — memory & scalability 🟧
- p.1: **scalability profiles**: knee point vs ceiling; "why aren't we getting ideal speedup?"; limitation taxonomy: critical path / serial fraction / schedule / #PUs ⇒ ceiling; ⚠️ graph labels only in image: ceiling, knee point, contention, coherence
- p.2: Texe & multicore: CPI **increases** beyond ~8 threads (naïve MM case study); FLOPs peak vs real (10%)
- p.3: locality principle: spatial vs temporal
- p.4–5: hierarchy big picture; virtual/physical pages; first-touch placement (NUMA)
- p.6: multicores: private L1/L2, shared L3, coherence invalidates, **shared memory bandwidth**
- p.7: Raptor Cove example (P-cores/E-cores)
- p.8: cache-friendly code: loop order swap (row-major)
- p.9: blocking (tiling) — transpose example

### `MD_simulations.pdf` — the case-study theory 🟧
- p.1: MD goals (chemistry, thin films, nanotech); N particles, Newton laws
- p.2: **LJ potential** φ(r)=4ε[(σ/r)¹²−(σ/r)⁶] (image — see `equations.md`)
- p.3: V(r), K(t), **F=−∇V**, Verlet integration, boundary conditions (image)
- p.4–5: scale anecdotes (NAMD, tobacco mosaic virus, SARS-CoV-2 Gordon Bell 2020)

### `Profiling.pdf` — how to find hot spots 🟧
- p.1: copy course project to `/projects/F202500010HPCVLABUMINHO/2026-2027cp/<user>`
- p.2: `srun --time=02:00:00 -p normal-arm -A <account> -n 1 --x11 --pty bash` · `ml GCC` · `g++ -O3` · (score-p GUI needs `ssh -X`)
- p.3: **perf sampling**: `perf record -F 1000 ./a.out` (⚠️ slide has the missing-space typo), `perf report -n`; call graph: `perf record -g -F 1000`
- p.4: **Score-P (instrumentation)**: `ml Score-P`, `scorep g++ -O3`, `ml CubeGUI`, `cube profile.cubex`

### `Boas_Praticas.pdf` — Deucalion operations 🟧
- p.1–2: 10 PFlops, Guimarães, EuroHPC; **ARM partition: 1632 nodes, Fujitsu A64FX, 32 GB HBM2 (50% faster)**; x86: 2×EPYC 7742
- p.3: education users share the ARM partition
- p.4–5: partitions (x86 2.3P, GPU 2.6P, ARM 5P), Infiniband, node naming: login `ln01-04`, x86 `cnx*`, GPU `gnx*`, **ARM `cna0001-1632`**
- p.6: login-node courtesy rules; access revocation
- p.7: SSH key setup (ed25519, TOTP, `~/.ssh/config`)
- p.8: **folders**: home ≤ 25k files → use `/projects/F202500010HPCVLABUMINHO/2026-2027cp/<user>`; accounts ending `a/x/g` = arm/x86/gpu; billing (interactive job bills 48 cores regardless)
- p.9: modules; `ml GCC` (latest: 15.2.0), `ml GCC/12.3.0`, `ml purge`
- p.10: batch vs interactive
- p.11: `billing`; `srun -A <account> --time=48:00:00 --nodes=1 -p normal-arm --pty bash`
- p.12: `sbatch`, `squeue --me`, `scancel`
- p.13–14: batch script template (`#SBATCH -p normal-arm`, `--cpus-per-task=48`)

### `01CP_Introduction.pdf` — course framing 🟨
- p.1–2: team, BB key `cp2627`, lab schedule
- p.3–7: textbooks (parallel computing, patterns/HPC, GPU CUDA)
- p.8: expected background (Unix, C)
- p.9: why parallelism (serial perf stall ~2000)
- p.10: WA = 60% of grade; predict with models & explain with metrics
- p.11: optimization **cycle**: profile → model → change → validate
- p.12–13: metric abstraction levels; benchmarking questions
- p.14–15: processor performance equation, worked example
- (p.2, separate slide): grading: exam 40% (min 5.0), intermediate work 10% (WA1), final work+defence 50%

### `04CP_Acc_draft.pdf` — SIMD & accelerators 🟨 (mostly phase 2)
- p.1: accelerators definition
- p.2: Apple M4 SoC: CPU < GPU+NPU area
- p.4: lower FP precision ⇒ higher performance (lin-log graph)
- p.5: RTX 50 family specs (⚠️ table scrambled in dump; use the formula)
- p.5 bottom: **peak = #PEs × IPC × Fclk**; vector vs matrix processing (FP64/32/16 vs FP16/8/4)
- p.7: vector architecture: gather→register→operate→scatter
- p.8: Flynn taxonomy (SIMD/MIMD)
- p.11: **peak performance = #cores × SIMDlen × IPC × freq**; `Texe = #I×CPI×Tcc/#cores`
- p.12: AVX `vaddps/vaddpd` (8 floats / 4 doubles per 256-bit register)
- p.13: vectorization preconditions: no dependencies, predication, vector length, **data layout**
- p.14–15: **AoS vs SoA** — the canonical compiler-vectorization blocker
- p.17–18: GPU SM organization; Intel AMX matrix registers

### `04-Notas_Estudo_Aceleradores.pdf` — pt-pt study notes 🟨
- p.1: aceleradores (GPU/TPU/NPU/FPGA); processamento vetorial vs matricial; SIMD (AVX-512, SVE **length-agnostic VLEN**)
- p.2: desafios: D1 dependências, D2 gestão de dados (movimentação explícita, coalescing, gather/scatter); precisão numérica
- p.3: mixed precision, quantização (INT8), underflow/overflow

### `05CP_Multithreading_draft.pdf` — threads background ⬜
- p.1: levels: ILP → threads → processes (granularity vs #I per activity)
- p.2–3: shared vs distributed memory systems (UMA/NUMA, cluster, node)
- p.4–5: logic vs physical parallelism; scheduling costs (creation, context switch)
- p.6–7: single-core multithreading: coarse-grain, fine-grain (GPU), **SMT**
- p.8: GPU runtime as multithreading (registers per thread)

### `PL00_MXX.pdf` — lab 0: environment 1ª sessão 🟨
- p.1: goals; SeARCH cluster; `srun --partition=cpar ./a.out`; MM case study in C; `-O3` gain; `perf stat`
- p.2–3: annexes: cluster access steps; annex 2 helper code

### `PL01_MXX.pdf` — lab 1: metrics ↔ Texe 🟨
- p.1: goals: `perf stat`; `Texe = #I×CPI×Tcc`; data vs function parallelism; dependencies & serial work
- p.2–5: exercises mapping #I/CPI/Tcc to matrix size (512² vs 1024², `-r 5`); profiling phases (init / multiply / validate); annex MM code

### `PL02_MXX.pdf` — lab 2: data locality 🟨
- p.1: spatial vs temporal; dot-product row/col analysis; estimate L1 misses; transpose fix; `perf stat -e L1-dcache-load-misses -M cpi` (`-O2`, 512²)
- p.2: annex: MM base code

### `PL03_MXX.pdf` — lab 3: vectorization + roofline 🟨
- p.1: compiler vectorization limits; loop order to enable vectorization; `-ftree-vectorize -msse4`; **roofline model** (memory bottleneck)
- p.2: annex: naive MM loop

### `PL04_MXX.pdf` — lab 4: OpenMP hands-on 🟨
- p.1: `parallel` region with `num_threads(2)`; thread ids; `single/master/barrier`; `-fopenmp`; `srun --cpus-per-task=2`; `module load gcc`
- p.2: exercise code `ex41.c`

## C. Term index (termo → fonte / term → source)

Format `file:page`. EN/pt-pt mirrors share one row.

| termo (pt) | term (en) | source |
|---|---|---|
| ganho / aceleração | speedup / gain | 02CP:5, 03PC:1 |
| lei de Amdahl | Amdahl's law | 02CP:5–6, PL01:1 |
| ponto de joelho | knee point | 03PC:1 |
| teto | scalability ceiling | 03PC:1 |
| contenção / coerência | contention / coherence | 03PC:1 (graph labels, image only) |
| caminho crítico | critical path (span) | 02CP:7–9 |
| trabalho / extensão | work / span | 02CP:8 |
| granularidade | granularity | 02CP:10, 05CP:1 |
| paralelismo de dados / funcional | data / function parallelism | 02CP:11, PL01:1 |
| mapa / redução | map / reduce | 02CP:11 |
| equação de desempenho | `Texe = #I × CPI × Tcc` | 01CP:14–15, 02CP:4, PL01:1 |
| latência / débito | latency / throughput(bandwidth) | 02CP:3 |
| localidade espacial/temporal | spatial / temporal locality | 03PC:3, PL02:1 |
| primeiro toque | first-touch (NUMA placement) | 03PC:5 |
| organização AoS vs SoA | array of structures vs structure of arrays | 04CP:14–15, 04CP-Notas:2 |
| agrupamento em blocos | blocking / tiling | 03PC:9 |
| SIMD, Flynn | SIMD, SISD/MISD/SIMD/MIMD | 04CP:8 |
| recolha / dispersão | gather / scatter | 04CP:7, 04CP-Notas:2 |
| predicação / máscara | predication / mask registers | 04CP:13, 04CP-Notas:2 |
| precisão mista | mixed precision | 04CP-Notas:3 |
| modelo do telhado | roofline model | PL03:1 |
| potencial de Lennard-Jones, método Verlet | Lennard-Jones potential, Verlet method | MD_sim:2–3 |
| região paralela | parallel region / team / fork-join | 06XX:6, PL04:1 |
| partilha de trabalho | work-sharing (`for`, `sections`, `single`) | 06XX:8, PL04:1 |
| calendário do laço | `schedule(static|dynamic|guided|auto)` | 06XX:8–9 |
| cláusulas de dados | `private/firstprivate/lastprivate/reduction` | 06XX:13 |
| corrida de dados | data race (critical vs atomic) | 06XX:14–15, WA1:2 |
| redução | `reduction(+:sum)` | 06XX:16 |
| variáveis de ambiente | `OMP_NUM_THREADS` etc. | 06XX:17, WA1:2 |
| barramento de memória (partilhado) | shared memory bandwidth | 03PC:6 |
| contenção | contention | 03PC:1 (image) |

## D. Question index (pergunta → onde/where)

| question | answer anchors |
|---|---|
| What exactly do I have to hand in? | `WA1:1` (+ `notes/WA1_26-27.md` checklist) |
| How is it graded? | `WA1:2` — 30% time on ARM · 30% approach+legibility, races ⇒ penalty · 40% report |
| Where do I start? (methodology) | `WA1:1` steps (i)–(v); `01CP:11` optimization cycle |
| How do I find the hot spots before optimizing? | `Profiling:3` (perf), `Profiling:4` (Score-P/Cube), seed N small (`WA1:2`) |
| Which timer do I use in code? | `06XX:18` `omp_get_wtime()` |
| Which loop schedule to pick? | `06XX:9` static low overhead / dynamic balance |
| What causes a data race here? | `06XX:15` race + `cmpxchg`; traps in `topics/openmp-cheatsheet.md` |
| How do I sum many partial results safely? | `06XX:16` `reduction` |
| What limits speedup besides serial fraction? | `03PC:2–3` CPI growth/coherence/bandwidth; `03PC:1` profiles; `02CP:7–9` span |
| Why doesn't the machine reach peak FLOP/s? | `03PC:2` naïve MM 10% peak; PL03 roofline; `04CP:11` peak equation |
| Is my array layout SIMD-friendly? | `04CP:14–15` AoS vs SoA; `04CP:13` preconditions |
| How big is Deucalion's ARM node? | `Boas:2` A64FX 48-core/HBM2 (+ `01CP:3`) |
| How do I run on an ARM node? | `Boas:11` srun; `Profiling:2` exact line; `Boas:13–14` sbatch |
| Which compiler/flags are graded? | `WA1:2` GCC/15.2.0 ARM, `-fopenmp` mandatory, `-march=native`, `-g` for perf |
| Where can I safe-fill without quota pain? | `Boas:8` projects folder; home ≤25k files |

## E. "Open this if…" routing

- **starting any task** → this file's section D, then the relevant note card.
- **implementing with OpenMP** → `notes/06XX-OpenMP_draft.md` + `topics/openmp-cheatsheet.md`.
- **writing the report** → `topics/performance-models.md`, `topics/memory-locality.md`, `notes/02CP_parallelism.md`, `notes/03PC_MemHierarchy.md`.
- **profiling on Deucalion** → `notes/Profiling.md` + `topics/profiling-workflow.md`.
- **understanding the physics of the case study** → `notes/MD_simulations.md` + `equations.md` + `topics/md-case-study.md`.
- **operations on the cluster** → `notes/Boas_Praticas.md` (⚠️ still: do **not** connect yet — see root `AGENTS.md`).
