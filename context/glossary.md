# Glossary — pt-pt ⇄ en-us

Source material: the course's own bilingual slides (e.g. `04-Notas_Estudo_Aceleradores.pdf`,
`03PC_MemHierarchy.pdf`'s Portuguese side-notes, PL guides) plus `WA1_26-27.pdf`
(English). Use: reference in *both* languages in the report; the oral defence
is usually Portuguese (`01CP_Introduction.pdf p.1`).

**Code legend** (short codes used below and in `topics/*`): `01CP` = `01CP_Introduction.pdf`, `02CP` = `02CP_parallelism.pdf`, `03PC` = `03PC_MemHierarchy.pdf`, `04CP` = `04CP_Acc_draft.pdf`, `04-Notas` = `04-Notas_Estudo_Aceleradores.pdf`, `05CP` = `05CP_Multithreading_draft.pdf`, `06XX` = `06XX-OpenMP_draft.pdf`, `MD_sim` = `MD_simulations.pdf`, `Boas` = `Boas_Praticas.pdf`, `WA1` = `WA1_26-27.pdf`, `PL0n` = `PL0n_MXX.pdf` (same table in `INDEX.md` §C).

## Core parallelism
| pt-pt | en-us | source |
|---|---|---|
| unidade de processamento (PU) | processing unit (PU) | 02CP:7 |
| ganho / aceleração | speedup / gain | 02CP:6 |
| fração paralela / série | parallel / serial fraction | 02CP:8 |
| ponto quente (do código) | hot-spot | 02CP:6 |
| caminho crítico | critical path / span | 02CP:9 |
| trabalho | work | 02CP:9 |
| granularidade | granularity | 02CP:10 |
| dependência de dados / de controlo | data / control dependency | 02CP:10 |
| paralelismo de dados / funcional | data / function parallelism | 02CP:11 |
| mapa / redução | map / reduce | 02CP:11 |
| escalonamento | scheduling (of tasks/threads) | 02CP:10, 05CP:7 |

## Architecture & memory
| pt-pt | en-us | source |
|---|---|---|
| hierarquia de memória | memory hierarchy | 03PC: title |
| localidade espacial / temporal | spatial / temporal locality | 03PC:4 |
| falha de cache | cache miss | PL02:1 |
| largura de banda de memória | memory bandwidth | 03PC:7 |
| processador SMT / núcleos físicos | SMT / physical cores | 05CP:8 |
| coerência/invalidação de cópia de cache | cache coherence / invalidation | 03PC:2,7 |
| arquitectura UMA / NUMA | UMA / NUMA memory | 05CP:3, 03PC:6 |
| primeiro toque | first-touch policy | 03PC:6 |
| blocagem / agrupar em blocos | blocking / tiling | 03PC:10 |

## SIMD & accelerators
| pt-pt | en-us | source |
|---|---|---|
| processamento vetorial / matricial | vector / matrix processing | 04CP:5, 04-Notas:1 |
| registo vetorial | vector register | 04-Notas:1 |
| recolha / dispersão | gather / scatter | 04CP:8 |
| predicação (máscaras) | predication (mask registers) | 04CP:14 |
| disposição dos dados | data layout | 04CP:14–16 |
| AoS — *array of structures* / SoA — *structure of arrays* | same | 04CP:15–16 |
| densidade de precisão (FP64/FP32/FP16) | floating-point precision | 04CP:5 |
| precisão mista | mixed precision | 04-Notas:3 |
| quantização | quantization | 04-Notas:3 |

## OpenMP (the vocabulary you will mix into English text)
| pt-pt | en-us | source |
|---|---|---|
| região paralela | parallel region | 06XX:7 |
| equipa de threads | team of threads / team | 06XX:7 |
| partilha de trabalho | work-sharing | 06XX:9 |
| atribuição de iterações | iteration distribution | 06XX:9 |
| barreira (implícita) | (implicit) barrier | 06XX:9 |
| corrida de dados | data race | 06XX:16, WA1:2 |
| exclusão mútua | mutual exclusion | 06XX:15 |
| operação atómica | atomic operation | 06XX:16 |
| repartição em blocos (*chunk size*) | chunk size | 06XX:10 |
| variáveis partilhadas / privadas | shared / private variables | 06XX:14 |

## Supercomputing / HPC operations
| pt-pt | en-us | source |
|---|---|---|
| nó de cálculo | compute node | measured/node.md |
| cluster de memória (CMG) | core-memory group (CMG) | measured/node.md |
| largura de vetor (SVE) | vector length (SVE VL) | measured/node.md |
| fila de computação | compute queue / partition | Boas:5 |
| tarefa em lote | batch job | Boas:11 |
| módulos de software | (software) modules | Boas:10 |
| nó de login | login node | Boas:7 |
| medição de tempo de execução | wall-clock execution time | 02CP:6, PL00:1 |
| analisador de desempenho | profiler | Profiling:3 |
