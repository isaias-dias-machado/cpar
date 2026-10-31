---
source:      Boas_Praticas.pdf
pages:      15
type:        ops guide
utility:     high
fidelity:    clean prose (screenshots p.1-2,13-15)
topics:      [deucalion, slurm, modules, projects, billing]
wa1:         logistics
---

# Good practices @ Deucalion (Malaca, Silva, Oct 2026)

⚠️ **Operational only — and the agent never connects: see root `AGENTS.md`.**

## Page map — the numbers you will need
- p.3 **About Deucalion**: ARM = **1632 nodes, Fujitsu A64FX, 32 GB HBM2
  ("50% faster")**; x86 = 500 nodes with 2×AMD EPYC 7742 (128 cores/node,
  256 GB).
- p.4 usage overview: >1500 active users, >340 projects; ARM partition not at
  full capacity; **the ARM partition is the one this course uses**.
- p.5 Deucalion structure/topology: x86 500 nodes, GPU 33, ARM 1632; also the
  Infiniband/NAS layout.
- p.6 node naming: `ln01-04` login, `cnx001-500` x86, `gnx501-533` GPU,
  **`cna0001-1632` ARM**.
- p.7 **Some warnings**: login-node etiquette — compiling on `ln*` with 1500
  concurrent users is abuse; transgressing ⇒ access revoked.
- p.8 access: ed25519 key, key upload via portal, TOTP browser login,
  `~/.ssh/config` alias `deucalion`.
- p.9 **Good practices / folders/limits**: home limited to **25k files** —
  keep work in `/projects/F202500010HPCVLABUMINHO/2026-2027cp/<user>/`
  (`quotaprojects`); account suffix tells the partition:
  `f202500010hpcvlabuminhoa` → arm (`dev-arm`, `normal-arm`, `large-arm`).
  Billing: an interactive job bills **48 cores even if you use 1**.
- p.10 **modules** are architecture-correct per node: on ARM you get the
  ARM-compiled binary. `ml GCC` = latest (15.2.0), `ml GCC/12.3.0`,
  `ml purge`.
- p.11 jobs: batch preferred over interactive (interactive not recommended);
  limits: max 2 days / 128 nodes.
- p.12 useful commands: `billing`; the canonical srun:
  `srun -A <account> --time=48:00:00 --nodes=1 -p normal-arm --pty bash`.
- p.13 practical part: `cp -r /projects/…/PLprojeto1/ ~`.
- p.14 SLURM commands: `sbatch`, `squeue --me`, `scancel <jobid>`.
- p.15 batch script skeleton: `#SBATCH -A <account>`, `-p normal-arm`,
  `--cpus-per-task=48`, `--output=out.o%j`.

## Notes adapted for this repo
- `Profiling.pdf` suggests copying the course project into the same
  `2026-2027cp/` folder; that path is the *project workspace* of the course,
  independent of this git repo.
