---
source:      04-Notas_Estudo_Aceleradores.pdf
pages:      3
type:        study notes (pt-pt, IA-assisted, curated by J.L. Sobral, 18-10-2026)
utility:     medium
fidelity:    clean
topics:      [aceleradores, simd, precisao, coalescing]
wa1:         none (glossary source)
---

# Notas de estudo — Aceleradores (pt-pt)

O melhor texto corrido do conjunto; excelente fonte para o glossário
pt-pt ⇄ en-us (ver `../glossary.md`) — mas sem impacto direto no WA1.

## Mapa de páginas
- p.1 aceleradores: **GPU** (milhares de núcleos), **TPU/NPU** (ASIC de
  álgebra linear / redes neuronais), **FPGA** (hardware reprogramável).
  Processamento **vetorial vs matricial** (1D vs 2D). SIMD em CPUs modernos:
  registos alargados (AVX-512 = 16×FP32), ALUs vetoriais segmentadas.
- p.2 registos polimórficos: ARM **SVE** com VLEN agnóstico de comprimento
  (128–2048 bits); leituras/escritas em passada contínua (unit-stride) ou
  com **gather/scatter**; **desafios D1** (dependências de dados e de
  controlo; predicação com máscaras) e **D2** (gestão de dados: movimentação
  explícita de memória, alinhamento/coalescing).
- p.3 D2 em detalhe (alinhamento, strides, coalescing) e **precisão
  numérica**: FP16/BF16 acelera; **precisão mista** (acumular em FP32);
  **quantização** (INT8); largura de banda (4× menos dados 64→16 bits);
  underflow/overflow.

## Use it for
- Portuguese terminology for the report/defence (the slides mix both
  languages; this file is the cleanest pt-pt source).
