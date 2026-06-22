#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

failures=0

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

pass() {
  printf 'PASS: %s\n' "$1"
}

require_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    pass "file exists: $path"
  else
    fail "missing file: $path"
  fi
}

require_pattern() {
  local pattern="$1"
  local path="$2"
  local label="$3"
  if rg -q "$pattern" "$path"; then
    pass "$label"
  else
    fail "$label"
  fi
}

require_absent() {
  local pattern="$1"
  local label="$2"
  shift 2
  local matches
  matches="$(rg -n "$pattern" "$@" || true)"
  if [[ -z "$matches" ]]; then
    pass "$label"
  else
    fail "$label"
    printf '%s\n' "$matches" >&2
  fi
}

standard="module/binance/STANDARD.md"
spec="module/binance/SPEC.md"

require_file "$standard"
require_file "module/binance/DATA-LIFECYCLE.md"
require_file "docs/migrations/binance-v2-upgrade.md"
require_file "docs/migrations/INDEX.md"
require_file "docs/report/binance/commit-coverage-audit-20260623.md"

require_pattern 'Spec-Version:[[:space:]]*v2\.3\.0' "$spec" "root spec is v2.3.0"

product_lines=(spot um_perp cm_perp options)
event_types=(tick trade bar depth)

nats_missing=0
kafka_missing=0
for product_line in "${product_lines[@]}"; do
  for event_type in "${event_types[@]}"; do
    nats_subject="binance.market.${product_line}.${event_type}"
    kafka_topic="binance.${product_line}.${event_type}.v1"
    if ! rg -q "(^|[^[:alnum:]_.-])${nats_subject}([^[:alnum:]_.-]|$)" "$standard"; then
      printf 'MISSING NATS: %s\n' "$nats_subject" >&2
      nats_missing=$((nats_missing + 1))
    fi
    if ! rg -q "(^|[^[:alnum:]_.-])${kafka_topic}([^[:alnum:]_.-]|$)" "$standard"; then
      printf 'MISSING Kafka: %s\n' "$kafka_topic" >&2
      kafka_missing=$((kafka_missing + 1))
    fi
  done
done

if [[ "$nats_missing" -eq 0 ]]; then
  pass "16 NATS subjects present in STANDARD.md"
else
  fail "missing NATS subjects: $nats_missing"
fi

if [[ "$kafka_missing" -eq 0 ]]; then
  pass "16 Kafka topics present in STANDARD.md"
else
  fail "missing Kafka topics: $kafka_missing"
fi

active_docs=(
  module/binance/SPEC.md
  module/binance/STANDARD.md
  module/binance/NAMING.md
  module/binance/RULES.md
  module/binance/TRACEABILITY.md
  module/binance/ACCEPTANCE.md
  module/binance/FEATURES.md
  module/binance/IMPLEMENTATION-PLAN.md
  module/binance/RUNTIME-MAPPING.md
  module/binance/CHANGELOG.md
  docs/report/binance/business-types-coverage-20260622.md
  docs/report/binance/deep-analysis-20260622-v3.md
)

require_absent '(Kafka|kafkax|topic).{0,120}binance\.market\.|binance\.market\..{0,120}(Kafka|kafkax|topic)' \
  "Kafka active docs do not use legacy market namespace" \
  "${active_docs[@]}"

require_file "module/binance/server/tasks/TASK-BINANCE-SERVER-014-kafkax-dispatch.md"
require_file "module/binance/server/tasks/TASK-BINANCE-SERVER-016-ossx-archiver.md"

require_absent 'TASK-BINANCE-SERVER-014-kafkax-export\.md|TASK-BINANCE-SERVER-016-ossx-archive\.md' \
  "active docs do not reference legacy task filenames" \
  "${active_docs[@]}"

require_pattern 'L1[[:space:]]*\|[[:space:]]*文档证据' "$standard" "STANDARD defines L1"
require_pattern 'L2[[:space:]]*\|[[:space:]]*本地 runtime 证据' "$standard" "STANDARD defines L2"
require_pattern 'L3[[:space:]]*\|[[:space:]]*外部发布证据' "$standard" "STANDARD defines L3"
require_pattern '本地 runtime HEAD SHA' "$standard" "L2 includes local runtime HEAD SHA"
require_pattern 'scripts/boundary-gates\.sh' "$standard" "L2 includes boundary gates"
require_pattern 'go test \./\.\.\.' "$standard" "L2 includes go test"
require_pattern 'smoke' "$standard" "L2 includes smoke"
require_pattern 'live、prod、race、vet、lint、secret、CI、release' "$standard" \
  "L2 explicitly excludes live/prod/race/vet/lint/secret/CI/release"

forbidden_pr_prefix='PR #'
forbidden_pr_prefix="${forbidden_pr_prefix}9"
require_absent "$forbidden_pr_prefix" "forbidden PR issue prefix is absent from checked docs and script" \
  "$standard" \
  module/binance/DATA-LIFECYCLE.md \
  docs/migrations/binance-v2-upgrade.md \
  docs/migrations/INDEX.md \
  docs/report/binance/commit-coverage-audit-20260623.md \
  docs/report/binance/business-types-coverage-20260622.md \
  docs/report/binance/deep-analysis-20260622-v3.md \
  scripts/check-binance-docs.sh

if [[ "$failures" -eq 0 ]]; then
  printf 'binance docs check passed\n'
else
  printf 'binance docs check failed: %d issue(s)\n' "$failures" >&2
  exit 1
fi
