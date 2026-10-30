# Glossary — pt-pt ⇄ en-us

Source material: the course's own bilingual slides (e.g. `04-Notas_Estudo_Aceleradores.pdf`,
`03PC_MemHierarchy.pdf`'s Portuguese side-notes, PL guides) plus `WA1_26-27.pdf`
(English). Use: reference in *both* languages in the report; the oral defence
is usually Portuguese (`01CP_Introduction.pdf p.1`).

## Core parallelism
| pt-pt | en-us | source |
|---|---|---|
| unidade de processamento (PU) | processing unit (PU) | 02CP:6 |
| ganho / aceleração | speedup / gain | 02CP:5 |
| fração paralela / série | parallel / serial fraction | 02CP:6 |
| ponto quente (do código) | hot-spot | 02CP:5 |
| caminho crítico | critical path / span | 02CP:8–9 |
| trabalho | work | 02CP:9 |
| granularidade | granularity | 02CP:10 |
| dependência de dados / de controlo | data / control dependency | 02CP:8,10 |
| paralelismo de dados / funcional | data / function parallelism | 02CP:11 |
| mapa / redução | map / reduce | 02CP:11 |
| escalonamento | scheduling (of tasks/threads) | 02CP:9, 05CP:5 |

## Architecture & memory
| pt-pt | en-us | source |
|---|---|---|
| hierarquia de memória | memory hierarchy | 03PC: title |
| localidade espacial / temporal | spatial / temporal locality | 03PC:3 |
| falha de cache | cache miss | PL02:1 |
| largura de banda de memória | memory bandwidth | 03PC:6 |
| processador SMT / núcleos físicos | SMT / physical cores | 05CP:7 |
| coerência/invalição de cópia de cache | cache coherence / invalidation | 03PC:1,6 |
| arquitectura UMA / NUMA | UMA / NUMA memory | 05CP:4, 03PC:5 |
| primeiro toque | first-touch policy | 03PC:5 |
| blocagem / agrupar em blocos | blocking / tiling | 03PC:9 |

## SIMD & accelerators
| pt-pt | en-us | source |
|---|---|---|
| processamento vetorial / matricial | vector / matrix processing | 04CP:5, 04-Notas:1 |
| registo vetorial | vector register | 04-Notas:1 |
| recolha / dispersão | gather / scatter | 04CP:7 |
| predicação (máscaras) | predication (mask registers) | 04CP:13 |
| disposição dos dados | data layout | 04CP:13–15 |
| AoS — *array of structures* / SoA — *structure of arrays* | same | 04CP:14–15 |
| densidade de precisão (FP64/FP32/FP16) | floating-point precision | 04CP:4 |
| precisão mista | mixed precision | 04-Notas:3 |
| quantização | quantization | 04-Notas:3 |

## OpenMP (the vocabulary you will mix into English text)
| pt-pt | en-us | source |
|---|---|---|
| região paralela | parallel region | 06XX:6 |
| equipa de threads | team of threads / team | 06XX:6 |
| partilha de trabalho | work-sharing | 06XX:8 |
| atribuição de iterações | iteration distribution | 06XX:8 |
| barreira (implícita) | (implicit) barrier | 06XX:8 |
| corrida de dados | data race | 06XX:15, WA1:2 |
| exclusão mútua | mutual exclusion | 06XX:14 |
| operação atómica | atomic operation | 06XX:15 |
| repartição em blocos (*chunk size*) | chunk size | 06XX:8 |
| variáveis partilhadas / privadas | shared / private variables | 06XX:13 |

## Supercomputing / HPC operations
| pt-pt | en-us | source |
|---|---|---|
| fila de computação | compute queue / partition | Boas:8 |
| tarefa em lote | batch job | Boas:10 |
| módulos de software | (software) modules | Boas:9 |
| nó de login | login node | Boas:6 |
| medição de tempo de execução | wall-clock execution time | 02CP:5, PL00:1 |
| analisador de desempenho | profiler | Profiling:3 |
