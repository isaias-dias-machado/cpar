Após a primeira optimização o ciclo crítico revou estar na função
`computeAccelerations`, e é relacionado com o cálculo das forças resultantes
entre cada par de partícula e também da energia potencial resultante agregada.

Estes calculos foram o principal alvo de optimização do projeto.

# substituir as chamadas à função de potenciação genérica pow().

A função pow() da biblioteca padrão é genérica. Isto significa que tem de lidar
com todos os tipos de casos possíveis e ainda garantir precisão para os casos
mais complicados.

Isto cria overhead desnecessário para os casos mais gerais.

A optimização aplicada foi calcular manualmente as potências utilizando o
pricípio da aditividade dos expoentes.

# distribuir o trabalho do cálculo das acelarações e energia potencial por threads

Na função `computeAccelerations` são calculados dois elementos distintos: as
accelarações de todas as partículas, e o acumular da energia potencial
resultante.

No primeiro caso a única dependência é a posição das partículas, que é
conhecida de antemão e não é mutada durante o ciclo.

O fator restritivo à paralelização total do cálculo é o acumular da energia
potencial, o que nos levou a uma solução de paralelismo por redução.

Neste esquema o trabalho independente é distribuído pelas threads, mas no final
do trabalho elas têm de esperar numa barreira que todas as outras terminem para,
no final, se calcular o acumular da energia potencial.

Uma possível optimização que poderia ser feita passaria pela barreira ser feita
em árvore, o que o OpenMP não suporta diretamente.

Na tabela referente à análise de escalabilidade das threads (em anexo)
podemos ver uma particularidade interessante: o número de instruções desce
significativamente quando o número de threads ultrapassa o número de cores da
máquina.

Uma hipótese para este fenómeno é que as threads deixam de poder recorrer a
spin-waiting/espera ativa e passem a fazer espera passiva, levando a que o
número de instruções reduza. No entanto, espera passiva implica que o sistema
operativo tenha de intervir no escalonamento das threads no CPU, o que leva à
degradação do tempo de execução.

# Cálculo do limite teórico para o cálculo das forças dos pares

Assumpções:
- N = 5000 { Número de partículas }
- pares de força calculados a cada chamada do computeAccelerations (para
  N=5000) = N*(N-1)/2 = 12,497,500
- iterações por execução = 201
- número de cores = 48
- Bandwidth utilizando todos os bancos de memória (4) = 1TiB/s =
                                                           = 1 * 2^40 / 10^12 =
                                                           = 1.1TB/s

- Bandwidth utilizando um banco de memória = 1.1TB/s / 4 = 275GB/s ; É
  importante salientar que na prática um banco não vai conseguir entregar este
  débito a todas as 48 threads. Isto implica que o nosso limite teórico para um
  banco de memória é otimista.
- Número de flops por par de partículas = 37 { optimized version }
- Número de bytes buscados da DRAM por par de partículas = 8 * 3 = 24

flops/cycle = SIMD lanes * SVE pipes * 2 { where two comes from Fused Multiply Add }
flops/cycle = 8 * 2 * 2 = 32

P_peak = cores * flops/cycle * frequencia
P_peak = 48 * 32 * 2GHz = 3.072 TFlops/s

BW_peak4banks = 1TiB/s

AI = flops / byte
AI = 37 / 24

Roofline = min(AI * BWpeak, Ppeak)
Roofline_4banks = min(37/24 * 1.1TB/s, 3.072 TFlops/s) =
                = min(1.696 TFlops/s, 3.072 TFlops/s) = 
                = 1.696 TFlops/s

Roofline_1bank  = min(37/24 * 275GB/s, 3.072 TFlops/s) =
                = min(424 GFlops/s, 3.072 TFlops/s) =
                = 424 GFlops/s

Flops_ParesAccelPorExecução = 12,497,500 * 201 * 37 = 92.96 GFlops

Floor = Flops / Roofline

Floor_4banks = 92.93 GFlops / 1696 GFlops/s =
             = 0.054 s

Floor_1banks = 92.94 GFlops / 424 GFlops/s =
             = 0.219 s

Estes valores representam o limite teórico de tempo de execução para a função
`computeAccelerations`.

<!-- # permitir vetorização ao mudar a estrutura de dados de Array of Structs para Structure of Arrays -->
<!---->
<!-- Na estrutura original dos dados relativamente às posições das partículas, cada -->
<!-- partícula ocupa três doubles contíguos. Isto é representativo de um esquema -->
<!-- `Array of Structures`.  -->
<!---->
<!-- # eliminar as divisões envolvidas no cálculo das raizes pela multiplicação da recíproca -->
<!---->
