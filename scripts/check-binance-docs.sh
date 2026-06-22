#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

failures=0

pass() { printf 'PASS %s %s\n' "$1" "$2"; }
fail() { printf 'FAIL %s %s\n' "$1" "$2"; failures=$((failures + 1)); }
require_file() {
  local rule="$1" file="$2"
  if [[ -f "$file" ]]; then
    pass "$rule" "$file exists"
  else
    fail "$rule" "$file: missing"
  fi
}
require_contains() {
  local rule="$1" file="$2" pattern="$3" label="$4"
  if grep -Eq -- "$pattern" "$file"; then
    pass "$rule" "$label"
  else
    fail "$rule" "$file: missing $label"
  fi
}

spec_version="1000 4 24 27 30 46 100 111 114 972 1000sed -n 's/^- Spec-Version: //p' module/binance/SPEC.md | head -n1)"
acceptance_version="$(sed -n 's/^| Module-Version | \([^|]*\) |$/\1/p' module/binance/ACCEPTANCE.md | head -n1)"
impl_version="$(sed -n 's/^- Version: //p' module/binance/IMPLEMENTATION-PLAN.md | head -n1)"
trace_ref="$(sed -n 's/^- Spec-Reference: `module\/binance\/SPEC.md` //p' module/binance/TRACEABILITY.md | head -n1)"

active_docs=(
  module/binance/README.md
  module/binance/NAMING.md
  module/binance/RUNTIME-MAPPING.md
  module/binance/ACCEPTANCE.md
  module/binance/TRACEABILITY.md
  module/binance/IMPLEMENTATION-PLAN.md
  docs/report/binance/goal-execution-plan-20260622.md
)

if rg -n 'usdm_futures|coinm_futures|futures_usdt|futures_coin' "${active_docs[@]}" >/tmp/binance-doc-aliases.$$ 2>/dev/null; then
  fail R1 "invalid product_line alias found: $(head -n1 /tmp/binance-doc-aliases.$$)"
else
  pass R1 'product_line aliases stay on spot/um_perp/cm_perp/options'
fi
rm -f /tmp/binance-doc-aliases.$$

nats_missing=0
kafka_missing=0
for product in spot um_perp cm_perp options; do
  for event in tick trade bar depth; do
    if ! grep -Rqs "binance.market.${product}.${event}" module/binance/NAMING.md module/binance/RUNTIME-MAPPING.md; then
      printf 'FAIL R2 missing NATS subject binance.market.%s.%s\n' "$product" "$event"
      nats_missing=$((nats_missing + 1))
    fi
    if ! grep -Rqs "binance.${product}.${event}.v1" module/binance/NAMING.md module/binance/RUNTIME-MAPPING.md; then
      printf 'FAIL R3 missing Kafka topic binance.%s.%s.v1\n' "$product" "$event"
      kafka_missing=$((kafka_missing + 1))
    fi
  done
done
if [[ $nats_missing -eq 0 ]]; then pass R2 'NATS 4x4 matrix complete'; else failures=$((failures + nats_missing)); fi
if [[ $kafka_missing -eq 0 ]]; then pass R3 'Kafka 4x4 matrix complete'; else failures=$((failures + kafka_missing)); fi

if [[ -n "$spec_version" && "$acceptance_version" == "$spec_version" ]]; then
  pass R4 "ACCEPTANCE Module-Version matches SPEC ${spec_version}"
else
  fail R4 "module/binance/ACCEPTANCE.md: Module-Version ${acceptance_version:-missing} != SPEC ${spec_version:-missing}"
fi
if [[ -n "$spec_version" && "$trace_ref" == "$spec_version" ]]; then
  pass R5 "TRACEABILITY Spec-Reference matches SPEC ${spec_version}"
else
  fail R5 "module/binance/TRACEABILITY.md: Spec-Reference ${trace_ref:-missing} != SPEC ${spec_version:-missing}"
fi
if [[ -n "$spec_version" && "$impl_version" == "$spec_version" ]]; then
  pass R6 "IMPLEMENTATION-PLAN Version matches SPEC ${spec_version}"
else
  fail R6 "module/binance/IMPLEMENTATION-PLAN.md: Version ${impl_version:-missing} != SPEC ${spec_version:-missing}"
fi

if rg -n 'SPEC v2\.2\.2|Spec-Version v2\.2\.0→v2\.2\.2' docs/report/binance/goal-execution-plan-20260622.md >/tmp/binance-doc-version.$$ 2>/dev/null; then
  fail R7 "stale goal-plan version reference: $(head -n1 /tmp/binance-doc-version.$$)"
else
  pass R7 'goal plan current metadata references v2.2.3'
fi
rm -f /tmp/binance-doc-version.$$

require_file R8 docs/report/binance/INDEX.md
require_contains R8 docs/report/binance/INDEX.md 'deep-analysis-20260622\.md' 'v3 report link'
require_contains R8 docs/report/binance/INDEX.md 'deep-analysis-20260622-v2\.md' 'v4 report link'
require_contains R8 docs/report/binance/INDEX.md 'iteration-plan-20260622\.md' 'iteration plan link'
require_contains R8 docs/report/binance/INDEX.md 'goal-execution-plan-20260622\.md' 'goal plan link'

require_file R9 module/binance/DATA-LIFECYCLE.md
for fr in FR-012 FR-013 FR-014 FR-015 FR-016 FR-017 FR-018 FR-019 FR-020 FR-021 FR-022 FR-023 FR-024; do
  require_contains R9 module/binance/DATA-LIFECYCLE.md "$fr" "$fr landing"
done
require_contains R9 module/binance/DATA-LIFECYCLE.md 'SPEC v2\.4\.0|SPEC v2\.5\.0|SPEC v3\.0\.0|SPEC v3\.1\.0' 'bump path'
require_contains R9 module/binance/DATA-LIFECYCLE.md 'Depends on|依赖' 'dependencies column'

if rg -n 'kafkax[^`\n]*`?binance\.market\.\{product_line\}\.\{event_type\}`?|kafkax topic = `binance\.market\.\{product_line\}\.\{event_type\}`|binance\.market\.\* topic' module/binance/ACCEPTANCE.md module/binance/TRACEABILITY.md >/tmp/binance-kafka-drift.$$ 2>/dev/null; then
  fail R10 "Kafka topic drift: $(head -n1 /tmp/binance-kafka-drift.$$)"
else
  pass R10 'Kafka topic docs use binance.{product_line}.{event_type}.v1 where kafkax is described'
fi
rm -f /tmp/binance-kafka-drift.$$

if [[ $failures -eq 0 ]]; then
  printf 'SUMMARY PASS R1-R10 0 fail\n'
else
  printf 'SUMMARY FAIL R1-R10 %d fail\n' "$failures"
fi
exit "$failures"
