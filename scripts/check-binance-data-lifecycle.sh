#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
doc="$root/module/binance/DATA-LIFECYCLE.md"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

[[ -f "$doc" ]] || fail "missing module/binance/DATA-LIFECYCLE.md"

for n in $(seq -w 12 24); do
  grep -q "FR-$n" "$doc" || fail "missing FR-$n"
done

for phrase in \
  "event_type" \
  "funding" \
  "mark_price" \
  "gap detector" \
  "binance_backfill_jobs" \
  "symbols/reload" \
  "Fold 前门禁"; do
  grep -q "$phrase" "$doc" || fail "missing phrase: $phrase"
done

fr_count="$(grep -o 'FR-[0-9][0-9][0-9]' "$doc" | sort -u | wc -l | tr -d ' ')"
[[ "$fr_count" = "13" ]] || fail "expected 13 unique FR entries, got $fr_count"

printf 'PASS: %s covers FR-012..FR-024 lifecycle draft\n' "${doc#$root/}"
