#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
doc="$root/module/binance/DATA-LIFECYCLE.md"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

[[ -f "$doc" ]] || fail "missing module/binance/DATA-LIFECYCLE.md"

for i in $(seq 12 30); do
  n="$(printf "%03d" "$i")"
  grep -q "FR-$n" "$doc" || fail "missing FR-$n"
done

for phrase in \
  "event_type" \
  "funding_rate" \
  "mark_price" \
  "gap detector" \
  "binance_backfill_jobs" \
  "symbols/reload" \
  "#880" \
  "#892" \
  "non-normative" \
  "runtime evidence" \
  "SPEC/TRACEABILITY" \
  "Fold 前门禁"; do
  grep -q "$phrase" "$doc" || fail "missing phrase: $phrase"
done

fr_count="$(grep -Eo 'FR-0(1[2-9]|2[0-9]|30)' "$doc" | sort -u | wc -l | tr -d ' ')"
[[ "$fr_count" = "19" ]] || fail "expected 19 unique FR-012..FR-030 entries, got $fr_count"

printf 'PASS: %s covers FR-012..FR-030 lifecycle draft\n' "${doc#$root/}"
