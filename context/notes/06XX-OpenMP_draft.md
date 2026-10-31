---
source:      06XX-OpenMP_draft.pdf
pages:       19
type:        lecture (draft)
utility:     high
fidelity:    clean (diagrams p.6,7,13 are pictures)
topics:      [openmp, worksharing, scheduling, data-sharing, synchronization]
wa1:         implementation
---

# OpenMP — the common core (Sobral, Oct 2026; standard v2.5)

## Page map
- p.2 what OpenMP is; p.3 considerations: **programmer owns correctness**
  (races, deadlock, load balancing are not solved for you).
- p.4 model: directives + runtime + env vars; one master, a team, implicit
  join.
- p.5–6 the core constructs: `parallel`, `for`, `sections`, `single`, `task`;
  `master`, `critical [name]`, `barrier`, `taskwait`, `atomic`, `flush`,
  `ordered`.
- p.7 syntax `#pragma omp parallel [clauses] { ... }`; fork inside; join at end.
- p.8 nested parallelism flagged **outdated** → use tasks instead.
- p.9 `for` work-sharing: distributes iterations (map); schedule types
  `static` (round-robin chunks, low overhead), `dynamic` (runtime queue,
  better balance), `guided`, `auto`; chunk size tuning; **implicit barrier at
  end of `for`** (unless `nowait`).
- p.10 loop constructors — exercise: choose schedule by payoff uniformity;
  static cheaper, dynamic balances; larger chunks → less overhead but worse
  balance.
- p.11 `ordered` clause.
- p.12 sections.
- p.13 `task` + `taskwait` (OpenMP 2.5).
- p.14 **data sharing**: variables declared inside the region are private;
  outside are shared; clauses `private` (unmodified), `firstprivate`
  (initialized from the outside value), `lastprivate`, and
  **`reduction(op:var)`** — each thread keeps a private copy, combined at the end.
- p.15 synchronization: `critical` — mutual exclusion, works across teams,
  may be *named*.
- p.16 **critical vs atomic + assembly**: `critical` = coarse lock around
  load-add-store; `atomic` = fine-grain optimistic update, a `cmpxchg` spin
  (`Repeat until successful update`); the *invisible* race on `8(%rsp,%r12)`.
- p.17 reduce synchronisation: `#pragma omp parallel for reduction(+:sum)`;
  thread **reuse across regions** (one `parallel`, many `for` inside ⇒ fewer
  team creations; each `for` still has an implicit barrier).
- p.18 env vars recap: `OMP_NUM_THREADS`, `OMP_SCHEDULE`, `OMP_DYNAMIC`,
  `OMP_NESTED`, `OMP_STACKSIZE`, `OMP_WAIT_POLICY`, `OMP_THREAD_LIMIT`.
- p.19 runtime API: `omp_get_num_threads`, `omp_get_thread_num`,
  `omp_get_wtime`, locks.

## Use it for
- Choosing exact directive + clause combinations during WA1 implementation;
  the atomic-vs-critical assembly is *the* argument for
  reduction-over-locks in the report.
