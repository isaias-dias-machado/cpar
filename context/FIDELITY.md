# Text-extraction fidelity of `context/*.pdf`

Method: `pdftotext -layout` cross-checked per page against `mutool draw -F txt`
(word counts; where the two extractors disagree by >25% the page was rendered
to PNG and inspected visually on 2026-10-30).

Three failure modes exist. None of them hides *prose*; they hide math, table
orientation, and figure-graphs:

| rótulo / label (en) | modo / mode | o que específico / specifics | remédio / fix |
|---|---|---|---|
| `equations-as-image` | real text loss | math typeset as raster; text layer gives garbage symbols | read `equations.md` (transcribed to LaTeX from the rendered page) |
| `overlap-figure` | noise, not loss | text of a pasted textbook figure interleaves with the slide's own text; word count inflates (p.9: 282 vs 91 from mutool) | read the *page*, not the dump |
| `figure-page` | nothing to lose | content is a picture (diagram, screenshot, book cover) | open the PDF page if the picture matters |

## Per-file verdict

| PDF | fidelity / fidelidade | detalhe |
|---|---|---|
| `WA1_26-27.pdf` | ✅ clean | normative; the most reliable file in the set |
| `MD_simulations.pdf` | ⚠️ **lossy** | p.3 Lennard-Jones potential is an image; p.4 V(r), K(t), F(r) and the two Verlet update equations are images — see `equations.md` |
| `01CP_Introduction.pdf` | ✅ clean prose | figure pages: p.4–5 (textbook covers), p.13 (scheme diagram) |
| `02CP_parallelism.pdf` | ⚠️ noisy | p.9, p.11 `overlap-figure` (Stanford CS149 + McCool book excerpts superimposed); Amdahl formula drawn as vector art |
| `03PC_MemHierarchy.pdf` | ⚠️ noisy | p.2 `overlap-figure`: the four scalability-profile graph labels — **ceiling, knee point, contention, coherence** — are legible only in the image |
| `04CP_Acc_draft.pdf` | ⚠️ noisy | p.6 GPU table: all 42 numbers survive but **column order is scrambled** — never quote the table, use the formula from p.6 bottom: `peak FP16 = #PEs × IPC × Fclk`. Figure-only p.5, 7, 10, 17–19 |
| `04-Notas_Estudo_Aceleradores.pdf` | ✅ clean | best prose in the set; Portuguese study notes |
| `05CP_Multithreading_draft.pdf` | ✅ mostly clean | figure pages p.1, 5, 8 |
| `06XX-OpenMP_draft.pdf` | ✅ clean | code/asm listings are real text (p.16 critical-vs-atomic); diagrams p.6, 7, 13 are pictures |
| `Boas_Praticas.pdf` | ✅ clean prose | screenshots p.1–2, 13–15 (topology, node naming) |
| `Profiling.pdf` | ✅ clean | screenshots p.2 (compile/run), p.4 (Score-P/Cube GUI). ⚠️ **source typo on p.3**: `perf record -F 1000./a.out` — the missing space is *in the slide*, the correct form is `perf record -F 1000 ./a.out` |
| `PL00_MXX.pdf` … `PL04_MXX.pdf` | ✅ clean | short matrix-figures on PL02/PL03 are illustrations only |

## Rules for artifacts

1. A quote from `_text/` is only authoritative if the source row above is ✅ **clean** for prose.
2. Never re-derive the LJ/Verlet equations from `_text/MD_simulations.txt` — use `equations.md`.
3. Never quote the GPU spec table from `_text/04CP_Acc_draft.txt`; quote the formula.
4. When a note references a figure-page, cite as `[file.pdf p.N (figure)]`.
