#!/bin/bash
# context/check.sh — verifies the knowledge base contracts (README.md)
# usage: bash context/check.sh    (run from repo root or anywhere)
set -u
cd "$(dirname "$0")" || exit 1
fails=0

say() { printf '%-9s %s\n' "$1" "$2"; }
fail() { say FAIL "$1"; fails=$((fails + 1)); }

# 1. every PDF has a note card whose frontmatter names it
for pdf in *.pdf; do
  base="${pdf%.pdf}"
  if grep -rql "source:.*${pdf}" notes/ 2>/dev/null \
     || grep -rql "source:.*${base}\.pdf" notes/ 2>/dev/null \
     || grep -ql "${pdf}" notes/PL_labs.md 2>/dev/null; then
    :
  else
    fail "no note card for ${pdf}"
  fi
done
say OK "note-card coverage: $(grep -rho 'source:.*' notes/*.md | sort -u | wc -l) frontmatter sources"

# 2. every catalogued PDF exists
grep -oE '`[A-Za-z0-9._-]+\.pdf`' INDEX.md | tr -d '`' | sort -u > /tmp/opencode/ctx_index_pdfs
for f in $(cat /tmp/opencode/ctx_index_pdfs); do
  [ -f "$f" ] || fail "INDEX lists missing file $f"
done
actual=$(ls *.pdf)
listed=$(sort /tmp/opencode/ctx_index_pdfs | tr '\n' ' ')
missing=$(comm -23 <(echo "$actual" | sort) <(sort /tmp/opencode/ctx_index_pdfs) | tr -d '\n')
[ -z "$missing" ] || fail "PDFs not in INDEX: $missing"

# 3. frontmatter sanity on every note card
for m in notes/*.md; do
  head -1 "$m" | grep -q '^---' || fail "frontmatter missing in $m"
done

# 4. required files
for f in INDEX.md FIDELITY.md equations.md glossary.md WA1-checklist.md README.md; do
  [ -f "$f" ] || fail "missing required file $f"
done
for t in topics/*.md; do :; done
for topic in openmp-cheatsheet profiling-workflow md-case-study performance-models memory-locality; do
  [ -f "topics/${topic}.md" ] || fail "missing topics/${topic}.md"
done

# 5. relative markdown links resolve (ignore http(s), mailto)
for m in *.md notes/*.md topics/*.md; do
  for link in $(grep -oE '\]\([^)#h][^)]*\)' "$m" 2>/dev/null | sed 's/[]()]*//g; s/^]*//; s/.*]//'); do
    case "$link" in
      http*|mailto*|"") : ;;
      *)
        target="${link%%#*}"
        dir="$(dirname "$m")"
        [ -e "$dir/$target" ] || fail "broken link in $m -> $link"
        ;;
    esac
  done
done

# 6. _text dumps exist for every pdf and start with provenance
for pdf in *.pdf; do
  t="_text/${pdf%.pdf}.txt"
  [ -f "$t" ] || { fail "missing _text/${pdf%.pdf}.txt"; continue; }
  head -1 "$t" | grep -q "DERIVED FROM" || fail "no provenance header in $t"
done

# 7. AGENTS.md at root names this directory (run from repo root context)
if [ -f ../AGENTS.md ]; then
  grep -q "context/" ../AGENTS.md || fail "root AGENTS.md does not route to context/"
else
  fail "root AGENTS.md missing (generate it last)"
fi

echo
if [ "$fails" -eq 0 ]; then say OK "context knowledge base consistent"; else say SUMMARY "$fails problem(s)"; fi
exit $fails
