# Index — `context/`

The routing table for this corpus. Read **only what you need**: catalogue row →
note card → (rarely) the PDF page itself. Provenance and extraction fidelity:
[`FIDELITY.md`](FIDELITY.md). Raw dumps: [`_text/`](_text/).

Page numbers below are **PDF pages** (what `pdftotext -f N -l N` shows), not
slide-footer numbers. When a footer disagrees with the PDF page (e.g.
`Boas_Praticas.pdf` skips one), the PDF page wins.

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

## A′. Measured sources (não são PDFs / not PDFs)

The only layer whose claims come from *us running something* on a dated
machine, not from a slide. One dated raw transcript per run (never edited, so
its line anchors are permanent) + one distilled decision file.

| raw transcript | when / where | distilled |
|---|---|---|
| [`measured/2026-10-31-recon.txt`](measured/2026-10-31-recon.txt) | 2026-10-31 18:24Z, `cna0022`, `normal-arm`, job 2172610 | [`measured/node.md`](measured/node.md) |

Read `measured/node.md` first; open the raw transcript only to check an anchor
(`L<n>`) or to grep something that was deliberately not distilled.

## B. Page index (file : page → tópico / topic)

### `WA1_26-27.pdf` — the assignment 🟥
- p.1: learning outcomes · MD/argon case study (FoleyLab origin) · LJ potential, Velocity Verlet, elastic walls · the 5-step methodology (profile → alternatives → select+scalability → implement on Deucalion ARM → measure) · groups of 2 · zip layout `pgXXXXX_pgYYYYY` · 2-page IEEE report · sources in `src/` · single `Makefile` → `md` · `make run` · submission deadline
- p.2: evaluation (three weighted parts; exact split in the note card §3) · `OMP_NUM_THREADS ?= N` in the Makefile · Annex A: Makefile extension rules (`?=`, override) · flags: `-fopenmp` mandatory, `-march=native` suggested, `-g -fno-omit-frame-pointer` for `perf` · **compiled with GCC/15.2.0 on an ARM node** · Annex B: the provided Makefile · profiling tip: seed with small N (e.g. 200) — slide says "line 214"; the repo's current line drift is in `topics/md-case-study.md`

### `06XX-OpenMP_draft.pdf` — core API 🟧
- p.2: what OpenMP is (directives + runtime + env vars; fork-join)
- p.3: programmer owns correctness: races, deadlock, load balance
- p.4: master thread/team model; default thread count
- p.5–6: directive syntax; `parallel`, `for`, `sections`, `single`, `task`; `master`, `critical`, `barrier`, `taskwait`, `atomic`, `flush`, `ordered`
- p.7: `parallel` syntax + data-clause teaser
- p.8: nested parallelism → outdated, use **tasks**
- p.9: `for` work-sharing; `schedule(static|dynamic|guided|auto)`, chunk size; implicit barrier
- p.10: static vs dynamic trade-off; "which schedule?" exercise
- p.11: `ordered` clause
- p.12–13: sections → tasks; task construct, `taskwait`
- p.14: **data sharing**: locals vs shared; `private` / `firstprivate` / `lastprivate` / `reduction(op:var)`
- p.15: `critical` (mutual exclusion, named, global lock)
- p.16: **critical vs atomic** + assembly of the race and the `cmpxchg` loop
- p.17: **reduction** example; thread reuse across regions (one `parallel`, many `for`s)
- p.18: env vars `OMP_SCHEDULE`, **`OMP_NUM_THREADS`**, `OMP_DYNAMIC`, `OMP_STACKSIZE`, `OMP_WAIT_POLICY`, `OMP_THREAD_LIMIT`…
- p.19: runtime routines (`omp_get_thread_num`, `omp_get_wtime`, locks…)

### `02CP_parallelism.pdf` — performance vocabulary 🟧
- p.2–3: optimization cycle ⇒ profile first, never guess
- p.4: latency vs throughput (bandwidth)
- p.5: `Texe = #I × CPI × Tcc`
- p.6: speedup = T_best_seq / T_par; hot-spots definition
- p.7: parallel speedup curves (knee at ~8 threads in the example)
- p.8: Amdahl limit formula (95% → cap 20)
- p.9: dependency graph, critical path, work/span, speedup bound; `z=(x−y)(x+y)` (⚠️ `overlap-figure`)
- p.10: granularity; data vs control dependencies
- p.11: function vs **data parallelism**; map/reduce in C++/Haskell/Scala; ⚠️ `overlap-figure`

### `03PC_MemHierarchy.pdf` — memory & scalability 🟧
- p.2: **scalability profiles**: knee point vs ceiling; speedup definition; "why aren't we getting ideal speedup?"; limitation taxonomy: critical path / serial fraction / schedule / #PUs ⇒ ceiling; ⚠️ graph labels only in image: ceiling, knee point, contention, coherence
- p.3: Texe & multicore: CPI **increases** beyond ~8 threads (naïve MM case study); FLOPs peak vs real (10%)
- p.4: locality principle: spatial vs temporal
- p.5: hierarchy big picture (software / compiler / hardware)
- p.6: detailed view; virtual/physical pages; first-touch placement (NUMA)
- p.7: multicores: private L1/L2, shared L3, coherence invalidates, **shared memory bandwidth**
- p.8: Raptor Cove example (P-cores/E-cores)
- p.9: cache-friendly code: minimise misses / blocks transferred
- p.10: blocking (tiling) — transpose example

### `MD_simulations.pdf` — the case-study theory 🟧
- p.2: MD goals (chemistry, thin films, nanotech); N particles, Newton laws
- p.3: **LJ potential** φ(r)=4ε[(σ/r)¹²−(σ/r)⁶] (image — see `equations.md`)
- p.4: V(r), K(t), **F=−∇V**, Verlet integration, boundary conditions (image)
- p.5: scale anecdotes (NAMD, tobacco mosaic virus, P-Found)
- p.6: SARS-CoV-2 Gordon Bell 2020

### `Profiling.pdf` — how to find hot spots 🟧
- p.1: copy course project to `/projects/F202500010HPCVLABUMINHO/2026-2027cp/<user>`
- p.2: `srun --time=02:00:00 -p normal-arm -A <account> -n 1 --x11 --pty bash` · `ml GCC` · `g++ -O3` · (score-p GUI needs `ssh -X`)
- p.3: **perf sampling**: `perf record -F 1000 ./a.out` (⚠️ slide has the missing-space typo), `perf report -n`; call graph: `perf record -g -F 1000`
- p.4: **Score-P (instrumentation)**: `ml Score-P`, `scorep g++ -O3`, `ml CubeGUI`, `cube profile.cubex`

### `Boas_Praticas.pdf` — Deucalion operations 🟧
- p.3: **About Deucalion**: ARM = 1632 nodes, Fujitsu A64FX, 32 GB HBM2 ("50% faster"); x86 = 500 nodes with 2×EPYC 7742
- p.4: usage overview: >1500 active users; ARM partition not at full capacity; **this course uses the ARM partition**
- p.5: partitions/topology: x86 500, GPU 33, ARM 1632; Infiniband, NAS
- p.6: node naming: login `ln01-04`, x86 `cnx*`, GPU `gnx*`, **ARM `cna0001-1632`**
- p.7: login-node courtesy rules; access revocation
- p.8: SSH key setup (ed25519, TOTP, `~/.ssh/config`)
- p.9: **folders**: home ≤ 25k files → use `/projects/F202500010HPCVLABUMINHO/2026-2027cp/<user>`; accounts ending `a/x/g` = arm/x86/gpu; billing (interactive job bills 48 cores regardless)
- p.10: modules; `ml GCC` (latest: 15.2.0), `ml GCC/12.3.0`, `ml purge`
- p.11: batch jobs preferred; interactive sessions not recommended
- p.12: `billing`; `srun -A <account> --time=48:00:00 --nodes=1 -p normal-arm --pty bash`
- p.13: practical part (`cp -r …/PLprojeto1/ ~`)
- p.14: `sbatch`, `squeue --me`, `scancel`
- p.15: batch script template (`#SBATCH -p normal-arm`, `--cpus-per-task=48`)

### `01CP_Introduction.pdf` — course framing 🟨
- p.1: title/team
- p.2: course schedule; **course grading** (split in `notes/01CP_Introduction.md` p.2); BB key `cp2627`
- p.3: lab schedule; SeARCH cluster; **Minho centre: 48-core ARM (A64FX), A100**
- p.4–8: textbooks (Key 1–4, p.4–7; Recommended, p.8)
- p.9: expected background (Unix, C)
- p.10: why parallelism (serial perf stall ~2000)
- p.11: WA = 60% of grade; predict with models & explain with metrics
- p.12: optimization **cycle**: profile → model → change → validate
- p.13: what to measure / how to measure
- p.14: metric abstraction levels
- p.15: processor performance equation, worked example

### `04CP_Acc_draft.pdf` — SIMD & accelerators 🟨 (mostly phase 2)
- p.2: accelerators definition
- p.3: Apple M4 SoC: CPU < GPU+NPU area
- p.4: computational photography (image page)
- p.5: lower FP precision ⇒ higher performance (lin-log graph)
- p.6: RTX 50 family specs (⚠️ table scrambled in dump; use the formula); bottom: **peak = #PEs × 2(FMA) × Fclk**; vector vs matrix processing
- p.7: CPU/GPU/TPU/NPU: which operations they accelerate
- p.8: vector architecture: gather→register→operate→scatter
- p.9: Flynn taxonomy (SIMD/MIMD)
- p.10–11: SIMD (data-level parallelism for matrix/media/ML)
- p.12: **peak performance = #cores × SIMDlen × IPC × freq**; `Texe = #I×CPI×Tcc/#cores`
- p.13: AVX `vaddps/vaddpd` (8 floats / 4 doubles per 256-bit register)
- p.14: vectorization preconditions: no dependencies, predication, vector length, **data layout**
- p.15–16: **AoS vs SoA** — the canonical compiler-vectorization blocker
- p.17: x64 vector registers (image page)
- p.18–19: GPU SM organization; Intel AMX matrix registers

### `04-Notas_Estudo_Aceleradores.pdf` — pt-pt study notes 🟨
- p.1: aceleradores (GPU/TPU/NPU/FPGA); processamento vetorial vs matricial; SIMD (AVX-512)
- p.2: SVE **length-agnostic VLEN**; gather/scatter; desafios D1 (dependências/predicação) e D2 (gestão de dados)
- p.3: D2 em detalhe (alinhamento/coalescing); precisão mista, quantização (INT8), underflow/overflow

### `05CP_Multithreading_draft.pdf` — threads background ⬜
- p.1–2: levels: ILP → threads → processes (granularity vs #I per activity); software vs hardware view
- p.3: shared vs distributed memory systems (UMA)
- p.4: distributed memory per node
- p.5: programming-abstractions example (process with 2 threads)
- p.6: logic vs physical parallelism (time-slicing)
- p.7: thread scheduling costs: creation, context switch
- p.8: single-core multithreading: coarse-grain, fine-grain (GPU), **SMT**
- p.9: GPU runtime as multithreading (registers per thread)

### `PL00_MXX.pdf` — lab 0: environment 1ª sessão 🟨
- p.1: goals; SeARCH cluster; `srun --partition=cpar ./a.out`; MM case study in C; `-O3` gain; `perf stat`
- p.2: exercises: `perf stat -M flops`, `perf record` sampling
- p.3: Annex 2: SeARCH cluster instructions

### `PL01_MXX.pdf` — lab 1: metrics ↔ Texe 🟨
- p.1: goals: `perf stat`; `Texe = #I×CPI×Tcc`; data vs function parallelism; dependencies & serial work
- p.2: Exercise 3: `std::thread`, speedup with 4/8/16 threads (`-r 5`, 512²)
- p.3: Annex 1: SeARCH (`module load gcc/11.2.0`)
- p.4: Annex 3: `std::thread` example
- p.5: Annex 4: Pearson-correlation code

### `PL02_MXX.pdf` — lab 2: data locality 🟨
- p.1: Exercise 1 spatial locality: dot-product row/col analysis; estimate L1 misses; transpose fix; `perf stat -e L1-dcache-load-misses -M cpi` (`-O2`, 512²)
- p.2: Exercise 2 parallel speedup & locality; Exercise 3 temporal locality

### `PL03_MXX.pdf` — lab 3: vectorization + roofline 🟨
- p.1: Exercise 1: compiler vectorization limits; loop order to enable vectorization; `-ftree-vectorize -msse4`
- p.2: Exercise 2: **roofline model** (memory bottleneck), applied to the `ikj` MM variant

### `PL04_MXX.pdf` — lab 4: OpenMP hands-on 🟨
- p.1: `parallel` region with `num_threads(2)`; thread ids; `single/master/barrier`; `-fopenmp`; `srun --cpus-per-task=2`; `module load gcc`; exercise source `ex41.c`
- p.2: Exercise 2: work-sharing and synchronization (`for`, `master`, `single`, `barrier`)

## C. Term index (termo → fonte / term → source)

Format `file:page`. EN/pt-pt mirrors share one row. **Code legend**:
`01CP`=`01CP_Introduction.pdf`, `02CP`=`02CP_parallelism.pdf`,
`03PC`=`03PC_MemHierarchy.pdf`, `04CP`=`04CP_Acc_draft.pdf`,
`04-Notas`=`04-Notas_Estudo_Aceleradores.pdf`,
`05CP`=`05CP_Multithreading_draft.pdf`, `06XX`=`06XX-OpenMP_draft.pdf`,
`MD_sim`=`MD_simulations.pdf`, `Boas`=`Boas_Praticas.pdf`,
`WA1`=`WA1_26-27.pdf`, `PL0n` = PL0n_MXX.pdf (i.e. PL00…PL04).

| termo (pt) | term (en) | source |
|---|---|---|
| ganho / aceleração | speedup / gain | 02CP:6, 03PC:2 |
| lei de Amdahl | Amdahl's law | 02CP:8, PL01:1 |
| ponto de joelho | knee point | 03PC:2 |
| teto | scalability ceiling | 03PC:2 |
| contenção / coerência | contention / coherence | 03PC:2 (graph labels, image only) |
| caminho crítico | critical path (span) | 02CP:9 |
| trabalho / extensão | work / span | 02CP:9 |
| granularidade | granularity | 02CP:10, 05CP:1 |
| paralelismo de dados / funcional | data / function parallelism | 02CP:11, PL01:1 |
| mapa / redução | map / reduce | 02CP:11 |
| equação de desempenho | `Texe = #I × CPI × Tcc` | 01CP:15, 02CP:5, PL01:1 |
| latência / débito | latency / throughput(bandwidth) | 02CP:4 |
| localidade espacial/temporal | spatial / temporal locality | 03PC:4, PL02:1 |
| primeiro toque | first-touch (NUMA placement) | 03PC:6 |
| organização AoS vs SoA | array of structures vs structure of arrays | 04CP:15–16, 04-Notas:2 |
| agrupamento em blocos | blocking / tiling | 03PC:10 |
| SIMD, Flynn | SIMD, SISD/MISD/SIMD/MIMD | 04CP:9 |
| recolha / dispersão | gather / scatter | 04CP:8, 04-Notas:2 |
| predicação / máscara | predication / mask registers | 04CP:14, 04-Notas:2 |
| precisão mista | mixed precision | 04-Notas:3 |
| modelo do telhado | roofline model | PL03:2 |
| potencial de Lennard-Jones, método Verlet | Lennard-Jones potential, Verlet method | MD_sim:3–4 |
| região paralela | parallel region / team / fork-join | 06XX:7, PL04:1 |
| partilha de trabalho | work-sharing (`for`, `sections`, `single`) | 06XX:9, PL04:2 |
| calendário do laço | `schedule(static|dynamic|guided|auto)` | 06XX:9–10 |
| cláusulas de dados | `private/firstprivate/lastprivate/reduction` | 06XX:14 |
| corrida de dados | data race (critical vs atomic) | 06XX:16, WA1:2 |
| redução | `reduction(+:sum)` | 06XX:17 |
| variáveis de ambiente | `OMP_NUM_THREADS` etc. | 06XX:18, WA1:2 |
| barramento de memória (partilhado) | shared memory bandwidth | 03PC:7 |
| contenção | contention | 03PC:2 (image) |

## D. Question index (pergunta → onde/where)

Numbers such as weights and deadlines have a **single home**; this table only
routes to it.

| question | answer anchors |
|---|---|
| What exactly do I have to hand in? | `WA1:1` (+ `notes/WA1_26-27.md` §2) |
| How is it graded? | `WA1:2` — weights and race penalty in `notes/WA1_26-27.md` §3 |
| When is it due? | `WA1:1` — date in `notes/WA1_26-27.md` §5 |
| Where do I start? (methodology) | `WA1:1` steps (i)–(v); `01CP:12` optimization cycle |
| How do I find the hot spots before optimizing? | `Profiling:3` (perf), `Profiling:4` (Score-P/Cube), seed N small (`WA1:2`) |
| Which timer do I use in code? | `06XX:19` `omp_get_wtime()` |
| Which loop schedule to pick? | `06XX:10` static low overhead / dynamic balance |
| What causes a data race here? | `06XX:16` race + `cmpxchg`; traps in `topics/openmp-cheatsheet.md` |
| How do I sum many partial results safely? | `06XX:17` `reduction` |
| What limits speedup besides serial fraction? | `03PC:3` CPI growth/coherence/bandwidth; `03PC:2` profiles; `02CP:9` span |
| Why doesn't the machine reach peak FLOP/s? | `03PC:3` naïve MM 10% peak; PL03:2 roofline; `04CP:12` peak equation |
| Is my array layout SIMD-friendly? | `04CP:15–16` AoS vs SoA; `04CP:14` preconditions |
| How big is Deucalion's ARM node? | **measured**: `measured/node.md`; slides `Boas:3`, `01CP:3` |
| How do I run on an ARM node? | `Boas:12` srun; `Profiling:2` exact line; `Boas:15` sbatch |
| Where do I compile, and for which CPU? | **measured**: `measured/node.md` (login node ≠ target ISA ⇒ build inside the allocation); `WA1:2` graded on ARM |
| Which compiler/flags are graded? | `WA1:2` GCC/15.2.0 ARM, `-fopenmp` mandatory, `-march=native`, `-g` for perf |
| Where can I safe-fill without quota pain? | `Boas:9` projects folder; home ≤25k files |

## E. "Open this if…" routing

- **starting any task** → this file's section D, then the relevant note card.
- **implementing with OpenMP** → `notes/06XX-OpenMP_draft.md` + `topics/openmp-cheatsheet.md`.
- **writing the report** → `topics/performance-models.md`, `topics/memory-locality.md`, `notes/02CP_parallelism.md`, `notes/03PC_MemHierarchy.md`.
- **profiling on Deucalion** → `notes/Profiling.md` + `topics/profiling-workflow.md`.
- **understanding the physics of the case study** → `notes/MD_simulations.md` + `equations.md` + `topics/md-case-study.md`.
- **operations on the cluster** → `notes/Boas_Praticas.md` + **`measured/node.md`**
  (what the node actually is: cores, CMG, ISA, compiler, perf, partition size).
  **The agent never connects**: it writes scripts under `remote/` and the
  operator runs them (root `AGENTS.md`); the 48-core billing rule stands.
