#!/usr/bin/env python3
"""
compare_md_output.py — MD optimization canary.

Compares a known-good MD run's cp_output.txt (and its companion
cp_average.txt) against the output of an optimized build, and reports
every difference that is too large to be harmless floating-point
reordering noise.

Why not a plain diff?
    Legal optimizations (OpenMP reductions, -ffast-math reassociation,
    FMA instructions, ...) change the ORDER in which floating-point sums
    are accumulated, so the last digits of every number can change even
    when the physics is identical. MD is chaotic, so such perturbations
    grow over the run — but this run is short (200 steps), so they stay
    far below anything physical. Real bugs (lost interactions, data
    races, broken reductions) produce differences orders of magnitude
    larger, at full size already in the FIRST rows. Both runs also
    always start from identical conditions (the code seeds the random
    number generator implicitly, with a fixed seed).

    Verdict logic:
      * first --window rows, every column -> very strict (--tight)
      * the time column, whole run        -> very strict: it is pure
        schedule arithmetic, so drift there means the run configuration
        changed, not the physics
      * other columns, whole run          -> strict (--loose)
      * the pressure column               -> advisory only: pressure is
        built from discrete wall-bounce events, so single rows can jump
        for legal reasons; the averaged pressure in cp_average.txt
        carries the verdict instead
      * cp_average.txt fields             -> strict for configuration-
        derived values (time, volume, N), loose for the physical ones
      * each file against itself          -> the averages must match
        what the per-step rows re-derive (this catches a broken
        averaging loop even without any reference file)

Typical use (after every optimization step):
    python3 tools/compare_md_output.py golden/cp_output.txt cp_output.txt

Determinism check (race alarm), on TWO RUNS OF THE SAME BINARY:
    python3 tools/compare_md_output.py r1/cp_output.txt r2/cp_output.txt --exact

Exit codes:
    0 = PASS  only harmless reordering-level differences
    1 = FAIL  differences too large to be reordering noise — treat as a bug
    2 = a file is broken (unreadable/truncated/NaN/wrong shape)
"""

import argparse
import math
import sys
from pathlib import Path

# --- cp_output.txt layout (must mirror the fprintf formats in src/MD.cpp) ---
OUTPUT_COLUMNS = ("time (s)", "T (K)", "P (Pa)", "kinetic E", "potential E", "total E")
COL_TIME, COL_T, COL_P, COL_KE, COL_PE, COL_TE = range(len(OUTPUT_COLUMNS))

# Columns judged against --loose over the whole run.
STRICT_COLUMNS = (COL_T, COL_KE, COL_PE, COL_TE)

# --- cp_average.txt layout: one data row of 7 numbers ------------------------
AVG_FIELDS = ("total_time", "T_avg", "P_avg", "PV_over_nT", "Z", "volume", "N")
AVG_DISPLAY = {
    "total_time": "total time (s)",
    "T_avg": "T avg (K)",
    "P_avg": "P avg (Pa)",
    "PV_over_nT": "PV/nT (J/(mol K))",
    "Z": "Z",
    "volume": "V (m^3)",
    "N": "N",
}
# Which tolerance regime each averages field is compared with. Configuration-
# derived values (time, volume, N) must match tightly: any drift there means
# the two runs were not the same problem/configuration.
AVG_REGIME = {
    "total_time": "tight",
    "T_avg": "loose",
    "P_avg": "loose",
    "PV_over_nT": "loose",
    "Z": "loose",
    "volume": "tight",
    "N": "tight",
}

# Constants mirrored from src/MD.cpp — needed to re-derive PV/nT and Z.
AVOGADRO = 6.022140857e23   # NA
KB_SI = 1.38064852e-23      # kBSI

# The averages file prints fewer digits than the per-step file, so a
# re-derivation can never match exactly. 1e-5 absorbs the print rounding while
# still catching averaging/formula mistakes, which are orders of magnitude
# larger.
CONSISTENCY_TOL = 1e-5


class CannotJudge(Exception):
    """A file is broken in a way that makes the comparison meaningless."""


def parse_floats(tokens, where):
    """Convert whitespace tokens to finite floats.

    Fails with CannotJudge on anything non-numeric or non-finite (NaN/Inf),
    with 'where' naming the file and line for the error message.
    """
    values = []
    for token in tokens:
        try:
            value = float(token)
        except ValueError:
            raise CannotJudge(f"{where}: '{token}' is not a number")
        if not math.isfinite(value):
            raise CannotJudge(f"{where}: non-finite value '{token}' (NaN or Inf)")
        values.append(value)
    return values


def parse_output_file(path):
    """Parse one cp_output.txt.

    Layout invariant: first non-empty line is the header text; every other
    non-empty line holds exactly 6 numbers (time, T, P, KE, PE, TE).
    Returns (header, rows) with rows as a list of 6-float tuples; raises
    CannotJudge with a ready-to-print message on any defect.
    """
    header, rows = None, []
    for lineno, raw in enumerate(path.read_text().splitlines(), start=1):
        stripped = raw.strip()
        if not stripped:
            continue
        if header is None:
            header = stripped
            continue
        where = f"{path.name}, line {lineno}"
        values = parse_floats(stripped.split(), where)
        if len(values) != len(OUTPUT_COLUMNS):
            raise CannotJudge(
                f"{where}: expected {len(OUTPUT_COLUMNS)} numbers per row, found {len(values)}"
            )
        rows.append(tuple(values))
    if header is None or not rows:
        raise CannotJudge(f"{path.name}: no data rows found")
    return header, rows


def parse_average_file(path):
    """Parse one cp_average.txt: the line holding exactly 7 numbers is the data.

    Returns a dict keyed like AVG_FIELDS; raises CannotJudge if no such row
    exists (the file's two leading header lines are skipped as non-numeric).
    """
    for lineno, raw in enumerate(path.read_text().splitlines(), start=1):
        stripped = raw.strip()
        if not stripped:
            continue
        try:
            values = parse_floats(stripped.split(), f"{path.name}, line {lineno}")
        except CannotJudge:
            continue  # header/format lines are not numeric — skip them
        if len(values) == len(AVG_FIELDS):
            return dict(zip(AVG_FIELDS, values))
    raise CannotJudge(f"{path.name}: no data row with {len(AVG_FIELDS)} numbers found")


def average_sidekick_path(output_path):
    """Derive the companion averages file of an output path.

    cp_output.txt -> cp_average.txt in the same directory; None when the
    name does not follow the <prefix>_output.txt pattern.
    """
    name = output_path.name
    if name.endswith("_output.txt"):
        return output_path.with_name(name[: -len("_output.txt")] + "_average.txt")
    return None


def load_average(path, explicit):
    """Load an averages file, tolerating absence unless the path was explicit.

    Returns None when an auto-discovered file is missing; raises
    CannotJudge when an explicitly given path is missing (probably a typo).
    """
    if path is None:
        return None
    if not path.exists():
        if explicit:
            raise CannotJudge(f"given averages path does not exist: {path}")
        return None
    return parse_average_file(path)


def relative_difference(a, b, floor):
    """Symmetric relative difference between two numbers.

    Both magnitudes at or below 'floor' -> 0.0: near-zero pairs count as
    equal (pressure is legitimately 0.0 in rows without wall collisions).
    """
    if abs(a) <= floor and abs(b) <= floor:
        return 0.0
    return abs(a - b) / max(abs(a), abs(b), floor)


def self_consistency_problems(rows, averages, floor):
    """Cross-check ONE run against itself.

    The per-step rows re-derive what cp_average.txt should say: the T and P
    averages (note MD.cpp's own behaviour: it sums NumTime+1 samples but
    divides by NumTime), and PV/nT & Z from the averaged values. Differences
    beyond CONSISTENCY_TOL mean the averaging/reporting path itself changed.

    Returns a list of ready-to-print problem strings (empty = consistent).
    """
    problems = []
    n_rows = len(rows)
    if n_rows < 2:
        return problems
    divisor = n_rows - 1  # MD.cpp: sum over NumTime+1 samples, divided by NumTime
    checks = [
        ("T_avg", averages["T_avg"], math.fsum(row[COL_T] for row in rows) / divisor),
        ("P_avg", averages["P_avg"], math.fsum(row[COL_P] for row in rows) / divisor),
    ]
    try:
        volume_si = averages["volume"]
        n_particles = averages["N"]
        checks.append((
            "PV_over_nT",
            averages["PV_over_nT"],
            AVOGADRO * averages["P_avg"] * volume_si / (n_particles * averages["T_avg"]),
        ))
        checks.append((
            "Z",
            averages["Z"],
            averages["P_avg"] * volume_si / (n_particles * KB_SI * averages["T_avg"]),
        ))
    except ZeroDivisionError:
        problems.append(
            "cannot re-derive PV/nT and Z: division by zero (T avg or N is zero?)"
        )
    for field, in_file, rederived in checks:
        rel = relative_difference(in_file, rederived, floor)
        if rel > CONSISTENCY_TOL:
            problems.append(
                f"averages file says {AVG_DISPLAY[field]} = {in_file:.8g}, but its own "
                f"per-step data re-derives {rederived:.8g} "
                f"(relative difference {rel:.1e} > {CONSISTENCY_TOL:.0e})"
            )
    return problems


def describe_hits(hits, limit=3):
    """Render comparison hits (col, rel, row_idx, ref, cand) for error messages."""
    parts = [
        f"row {row_idx + 1}: {ref:.8g} vs {cand:.8g} (rel {rel:.1e})"
        for _col, rel, row_idx, ref, cand in hits[:limit]
    ]
    if len(hits) > limit:
        parts.append(f"... plus {len(hits) - limit} more rows")
    return "; ".join(parts)


def parse_args(argv):
    parser = argparse.ArgumentParser(
        description=(
            "MD output canary: compare two cp_output.txt files (and their companion "
            "cp_average.txt) and report differences too large to be harmless "
            "floating-point reordering noise."
        ),
        epilog="exit codes: 0 PASS, 1 FAIL (physics changed), 2 broken file",
    )
    parser.add_argument("reference", type=Path,
                        help="cp_output.txt of the known-good run")
    parser.add_argument("candidate", type=Path,
                        help="cp_output.txt of the run to be judged")
    parser.add_argument("--tight", type=float, default=1e-9,
                        help="relative tolerance for the first --window rows and "
                             "configuration-derived values (default: %(default)s)")
    parser.add_argument("--loose", type=float, default=1e-6,
                        help="relative tolerance for the whole run and the physical "
                             "averages (default: %(default)s)")
    parser.add_argument("--window", type=int, default=5,
                        help="how many rows are compared with --tight — bugs are "
                             "full-size there (default: %(default)s)")
    parser.add_argument("--floor", type=float, default=1e-12,
                        help="magnitudes at or below this count as zero when "
                             "comparing (default: %(default)s)")
    parser.add_argument("--no-average", action="store_true",
                        help="ignore the cp_average.txt companion files entirely")
    parser.add_argument("--ref-avg", type=Path, default=None,
                        help="explicit path to the reference cp_average.txt "
                             "(default: derived from the output path)")
    parser.add_argument("--cand-avg", type=Path, default=None,
                        help="explicit path to the candidate cp_average.txt "
                             "(default: derived from the output path)")
    parser.add_argument("--exact", action="store_true",
                        help="require bit-identical numbers — meant for two runs of "
                             "the SAME binary, as a nondeterminism/race alarm")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)

    # ---- parse both per-step files ----------------------------------------
    try:
        ref_header, ref_rows = parse_output_file(args.reference)
        cand_header, cand_rows = parse_output_file(args.candidate)
    except (CannotJudge, OSError) as problem:
        print(f"CANNOT JUDGE: {problem}")
        return 2

    if len(ref_rows) != len(cand_rows):
        print(
            f"CANNOT JUDGE: row count differs "
            f"(reference {len(ref_rows)}, candidate {len(cand_rows)}).\n"
            "The candidate run probably crashed early, or NumTime/N changed."
        )
        return 2

    errors = []    # -> FAIL
    warnings = []  # printed, but not fatal

    if ref_header != cand_header:
        warnings.append(
            "the column header line differs between the two files — changing the "
            "output format is itself something to avoid (WA1 grades the printed formats)"
        )

    tight = 0.0 if args.exact else args.tight
    loose = 0.0 if args.exact else args.loose
    window = min(args.window, len(ref_rows))

    # ---- row-by-row scan ---------------------------------------------------
    # Every hit is (column, rel_diff, row_idx, ref_value, cand_value).
    worst = {col: (0.0, 0) for col in range(len(OUTPUT_COLUMNS))}
    time_hits, window_hits, strict_hits, pressure_hits = [], [], [], []

    for row_idx, (ref_row, cand_row) in enumerate(zip(ref_rows, cand_rows)):
        for col in range(len(OUTPUT_COLUMNS)):
            ref_val, cand_val = ref_row[col], cand_row[col]
            rel = relative_difference(ref_val, cand_val, args.floor)
            if rel > worst[col][0]:
                worst[col] = (rel, row_idx)

            if col == COL_TIME:
                if rel > tight:
                    time_hits.append((col, rel, row_idx, ref_val, cand_val))
            elif row_idx < window:
                if rel > tight:
                    window_hits.append((col, rel, row_idx, ref_val, cand_val))
            elif col in STRICT_COLUMNS:
                if rel > loose:
                    strict_hits.append((col, rel, row_idx, ref_val, cand_val))
            elif col == COL_P:
                # advisory outside the window; strict under --exact
                if rel > (0.0 if args.exact else loose):
                    pressure_hits.append((col, rel, row_idx, ref_val, cand_val))

    if time_hits:
        errors.append(
            "the 'time (s)' column differs — it is pure schedule arithmetic, so this "
            "means the two runs used different dt/timefac/NumTime (configuration "
            "drift, not physics): " + describe_hits(time_hits)
        )

    for hits, what in (
        (window_hits, f"first {window} rows check"),
        (strict_hits, "whole-run check"),
    ):
        by_column = {}
        for hit in hits:
            by_column.setdefault(hit[0], []).append(hit)
        for col, col_hits in by_column.items():
            max_rel = max(hit[1] for hit in col_hits)
            errors.append(
                f"{what}: column '{OUTPUT_COLUMNS[col]}' — "
                f"{len(col_hits)} of {len(ref_rows)} rows above tolerance, "
                f"worst {max_rel:.1e}: " + describe_hits(col_hits)
            )

    # ---- companion averages files -----------------------------------------
    ref_avg = cand_avg = None
    comparison_lines = []
    if args.no_average:
        pass
    else:
        try:
            ref_avg = load_average(
                args.ref_avg if args.ref_avg else average_sidekick_path(args.reference),
                explicit=bool(args.ref_avg),
            )
            cand_avg = load_average(
                args.cand_avg if args.cand_avg else average_sidekick_path(args.candidate),
                explicit=bool(args.cand_avg),
            )
        except (CannotJudge, OSError) as problem:
            print(f"CANNOT JUDGE: {problem}")
            return 2

        if ref_avg is None and cand_avg is None:
            warnings.append(
                "no companion *_average.txt found — comparing the per-step output only. "
                "The averages are the graded artifact; keep them when you can."
            )
        elif ref_avg is None or cand_avg is None:
            errors.append(
                f"only one side has a companion averages file (reference: "
                f"{ref_avg is not None}, candidate: {cand_avg is not None}) — "
                "generate both, or pass --no-average to judge the per-step output only"
            )

    if ref_avg is not None and cand_avg is not None:
        for field in AVG_FIELDS:
            ref_val, cand_val = ref_avg[field], cand_avg[field]
            tolerance = tight if AVG_REGIME[field] == "tight" else loose
            rel = relative_difference(ref_val, cand_val, args.floor)
            comparison_lines.append((field, ref_val, cand_val, rel, tolerance))
            if rel > tolerance:
                hint = ""
                if field in ("total_time", "volume", "N"):
                    hint = (" (configuration-derived value: check inputdata.txt "
                            "and the hardcoded constants)")
                errors.append(
                    f"averages file, {AVG_DISPLAY[field]}: {ref_val:.8g} vs "
                    f"{cand_val:.8g} (relative difference {rel:.1e} > tolerance "
                    f"{tolerance:.0e}){hint}"
                )

        # Self-consistency: candidate problems are errors; if the trusted
        # reference disagrees with itself we only warn (its golden status is
        # then in question, but the candidate did not cause it).
        for label, averages, rows, sink in (
            ("candidate", cand_avg, cand_rows, errors),
            ("reference", ref_avg, ref_rows, warnings),
        ):
            if averages is None:
                continue
            for problem in self_consistency_problems(rows, averages, args.floor):
                sink.append(f"{label} self-consistency: {problem}")

    if args.exact and pressure_hits:
        errors.append(
            "--exact check: the pressure column differs where bit-identical output "
            "was required: " + describe_hits(pressure_hits)
        )

    # ---- report ------------------------------------------------------------
    ruler = "=" * 74
    print(ruler)
    print("MD OUTPUT CANARY")
    print(f"  reference : {args.reference}")
    print(f"  candidate : {args.candidate}")
    if args.exact:
        print("  mode      : EXACT — bit-identical numbers required")
    else:
        print(f"  tolerance : first {window} rows {tight:.0e}, rest {loose:.0e} (relative)")
    print(f"  rows      : {len(ref_rows)} per file")
    print(ruler)

    if errors:
        print(f"\nPROBLEMS ({len(errors)}) — differences too large to be reordering noise:")
        for problem in errors:
            print(f"  ! {problem}")
    if warnings:
        print(f"\nWarnings ({len(warnings)}):")
        for warning in warnings:
            print(f"  ~ {warning}")

    print("\nWorst difference per column (whole run):")
    print(f"  {'column':<14}{'worst rel':>12}{'at row':>8}   verdict")
    for col in range(len(OUTPUT_COLUMNS)):
        rel, row_idx = worst[col]
        if col == COL_TIME:
            verdict = "ok" if rel <= tight else "EXCEEDED (config drift)"
        elif col == COL_P:
            verdict = "ok" if (args.exact or rel <= loose) else "advisory only"
        else:
            verdict = "ok" if rel <= loose else "EXCEEDED"
        print(f"  {OUTPUT_COLUMNS[col]:<14}{rel:>12.1e}{row_idx + 1:>8}   {verdict}")

    if not args.exact and pressure_hits:
        print(
            f"\n  note: pressure differs beyond {loose:.0e} in {len(pressure_hits)} "
            "row(s) — advisory only: pressure is built from discrete wall-bounce "
            "events, so single rows can jump for legal reasons. The averaged "
            "pressure (P avg in cp_average.txt) carries the verdict."
        )

    if comparison_lines:
        print("\nAverages (cp_average.txt):")
        print(f"  {'field':<18}{'reference':>15}{'candidate':>15}   verdict")
        for field, ref_val, cand_val, rel, tolerance in comparison_lines:
            verdict = "ok" if rel <= tolerance else "EXCEEDED"
            print(f"  {AVG_DISPLAY[field]:<18}{ref_val:>15.8g}{cand_val:>15.8g}   {verdict}")

    if errors:
        print(f"\nVERDICT: FAIL — {len(errors)} problem(s). Treat these as real "
              "differences introduced by the optimization (or by a race), not as "
              "rounding noise.")
        return 1
    print("\nVERDICT: PASS — all differences are within the range that "
          "floating-point reordering can explain. The optimization did not "
          "change the graded output values.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
