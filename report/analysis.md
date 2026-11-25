TODO: utilizar o valor teórico na lei de amdhal para estimar o speedup.
## principais optimizações no hot loop
- substituir as chamadas à função de potenciação genérica pow().
- distribuir o trabalho do cálculo das accelarações e energia potencial por threads
- permitir vetorização ao mudar a estrutura de dados de Array of Structs para Structure of Arrays
- eliminar as divisões envolvidas no cálculo das raizes pela multiplicação da recíproca

## computeAccelerations

Pares de força calculados: N * (N-1 / 2)

numero de iterações: 201

Flops por par: 33

(Para N = 5000)

Avaliação de pares por execução: 2,511,997,500

Flops por execução 120,017,858,664

## observações

quando o número de threads passa o número de cores (48), o
número de instruções volta a valores semelhantes ao da execução
sequencial, e o tempo de execução piora comparado com a execução
com 48 threads.

a melhor versão tem tempo de execução 1.228 segundos e
corresponde ao ficheiro simd.cpp
