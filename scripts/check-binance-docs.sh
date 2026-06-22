#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

pass() {
  echo "PASS: $*"
}

require_file() {
  [ -f "$1" ] || fail "missing file: $1"
}

SPEC="module/binance/SPEC.md"
README="module/binance/README.md"
ACCEPTANCE="module/binance/ACCEPTANCE.md"
TRACEABILITY="module/binance/TRACEABILITY.md"
RUNTIME_MAPPING="module/binance/RUNTIME-MAPPING.md"
RULES="module/binance/RULES.md"

for doc in "$SPEC" "$README" "$ACCEPTANCE" "$TRACEABILITY" "$RUNTIME_MAPPING" "$RULES"; do
  require_file "$doc"
done

spec_version="$(sed -n 's/^- Spec-Version: \(v[0-9][0-9.]*\).*/\1/p' "$SPEC" | head -n 1)"
readme_root_version="$(sed -n 's/^- Spec-Version: \(v[0-9][0-9.]*\) (root).*/\1/p' "$README" | head -n 1)"
acceptance_version="$(sed -n 's/^| Module-Version | \(v[0-9][0-9.]*\) |$/\1/p' "$ACCEPTANCE" | head -n 1)"

[ -n "$spec_version" ] || fail "missing root Spec-Version in $SPEC"
[ "$readme_root_version" = "$spec_version" ] || fail "$README root Spec-Version $readme_root_version != $SPEC $spec_version"
[ "$acceptance_version" = "$spec_version" ] || fail "$ACCEPTANCE Module-Version $acceptance_version != $SPEC $spec_version"
grep -Fq "Spec-Reference: \`module/binance/SPEC.md\` $spec_version" "$TRACEABILITY" || fail "$TRACEABILITY Spec-Reference does not match $spec_version"
pass "Binance root doc versions match $spec_version"

product_lines=(spot um_perp cm_perp options)
event_types=(tick trade bar depth)

for product_line in "${product_lines[@]}"; do
  for event_type in "${event_types[@]}"; do
    grep -Fq "binance.market.${product_line}.${event_type}" "$RUNTIME_MAPPING" || fail "missing natsx subject binance.market.${product_line}.${event_type} in $RUNTIME_MAPPING"
    grep -Fq "binance.${product_line}.${event_type}.v1" "$RUNTIME_MAPPING" || fail "missing Kafka topic binance.${product_line}.${event_type}.v1 in $RUNTIME_MAPPING"
  done
done
pass "RUNTIME-MAPPING has complete 4x4 natsx subjects and Kafka topics"

legacy_topics="$(grep -nE 'binance\.market\.(ticks|bars|depth|events)\b' "$RUNTIME_MAPPING" "$SPEC" "$ACCEPTANCE" "$TRACEABILITY" || true)"
if [ -n "$legacy_topics" ]; then
  printf '%s\n' "$legacy_topics" >&2
  fail "legacy aggregate Kafka topic remains"
fi

topic_wildcards="$(grep -nE 'binance\.market\.\*.*topic|topic.*binance\.market\.\*' "$SPEC" "$ACCEPTANCE" "$TRACEABILITY" || true)"
if [ -n "$topic_wildcards" ]; then
  printf '%s\n' "$topic_wildcards" >&2
  fail "Kafka topic wording still uses natsx binance.market.* wildcard"
fi
pass "Kafka topic wording is separated from natsx subjects"

require_file "module/binance/server/tasks/TASK-BINANCE-SERVER-014-kafkax-dispatch.md"
require_file "module/binance/server/tasks/TASK-BINANCE-SERVER-016-ossx-archiver.md"

stale_tasks="$(grep -nE 'TASK-BINANCE-SERVER-014-kafkax-export|TASK-BINANCE-SERVER-016-ossx-archive\b' "$RULES" || true)"
if [ -n "$stale_tasks" ]; then
  printf '%s\n' "$stale_tasks" >&2
  fail "RULES references stale task filename"
fi
pass "RULES task filenames resolve to existing task docs"

grep -Fq 'runtime 通过状态仍以实际 `/home/binance` 测试为准' "$ACCEPTANCE" || fail "$ACCEPTANCE missing runtime status evidence caveat"
pass "Runtime status remains layered from docs readiness"
