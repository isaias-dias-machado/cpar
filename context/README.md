# `context/` — how this knowledge base is organized

A layered knowledge base for the WA1 assignment. Designed so an agent (or a
human, or your future tired self) loads the *cheapest* thing that answers the
question, never more.

## The three layers

| layer | files | when to read |
|---|---|---|
| **L0 index** | [`INDEX.md`](INDEX.md), [`FIDELITY.md`](FIDELITY.md) | first contact with a topic; the routing table |
| **L1 note cards** | [`notes/`](notes/) — one per PDF | need the gist of one source |
| **L2 synthesis** | [`topics/`](topics/), [`equations.md`](equations.md), [`glossary.md`](glossary.md), [`WA1-checklist.md`](WA1-checklist.md) | need a *decision file* spanning several sources |
| **measured** | [`measured/`](measured/) — distilled `node.md` + one dated raw transcript per run | need a fact about the real machine (cores, ISA, compiler, partition) |
| raw dumps | [`_text/`](_text/) | greppable text layer, per-file provenance header; **lossy on the pages flagged in `FIDELITY.md`** |

## Contracts (keep them when extending)

1. **One fact, one home.** A number, formula or constraint lives in exactly
   one file; every other file links to it. This file and `AGENTS.md` are the
   only *routing* files — veto any restatement.
2. **Every source claim carries an anchor**: `[file.pdf p.N]`; when a claim
   needs a *figure* or *equation*, say so: `(figure)`, `(image → equations.md)`.
3. **Note cards** carry YAML frontmatter
   (`source, pages, type, utility, fidelity, topics, wa1`) so retrieval is a
   plain `grep`; `fidelity:` must mirror `FIDELITY.md`.
4. **The `_text/` dumps are derived** — regenerate with `pdftotext -layout`,
   do not hand-edit; if their header's `fidelity:` conflicts with
   `FIDELITY.md`, the PDF itself wins.
5. **Normative vs pedagogical**: `WA1_26-27.pdf` is law; everything else is
   supporting material and may be paraphrased with an anchor.

## Verification

```
bash context/check.sh      # links, frontmatter, 16/16 coverage, INDEX consistency
```

(Read the script before changing anything — it is deliberately `bash`+`grep`
so it runs anywhere; the graded `Makefile` must not be touched.)
