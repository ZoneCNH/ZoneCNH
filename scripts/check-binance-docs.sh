#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

failures=0
pass() { printf 'PASS %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; failures=$((failures + 1)); }

require_file() {
  local file="$1"
  [[ -f "$file" ]] && pass "file exists: $file" || fail "missing file: $file"
}

require_text() {
  local file="$1" pattern="$2" label="$3"
  if grep -Eq "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

reject_text() {
  local file="$1" pattern="$2" label="$3"
  if grep -Eq "$pattern" "$file"; then
    fail "$label"
  else
    pass "$label"
  fi
}

# R9 + Stage artifacts.
required_docs=(
  module/binance/SPEC.md
  module/binance/README.md
  module/binance/NAMING.md
  module/binance/RULES.md
  module/binance/RUNTIME-MAPPING.md
  module/binance/BOUNDARY-GATES.md
  module/binance/TRACEABILITY.md
  module/binance/IMPLEMENTATION-PLAN.md
  module/binance/FEATURES.md
  module/binance/ACCEPTANCE.md
  module/binance/CHANGELOG.md
  module/binance/DATA-LIFECYCLE.md
  docs/report/binance/INDEX.md
  docs/report/binance/goal-execution-plan-20260622.md
)
for doc in "${required_docs[@]}"; do
  require_file "$doc"
done

# R6 version sync for current Stage0 repair baseline.
require_text module/binance/SPEC.md 'Spec-Version: v2\.2\.3' 'SPEC version is v2.2.3'
require_text module/binance/README.md 'Spec-Version: v2\.2\.3' 'README root version is v2.2.3'
require_text module/binance/ACCEPTANCE.md 'Module-Version \| v2\.2\.3' 'ACCEPTANCE module version matches v2.2.3'
require_text module/binance/FEATURES.md 'Module-Version \| v2\.2\.3' 'FEATURES module version matches v2.2.3'
require_text module/binance/IMPLEMENTATION-PLAN.md 'Version: v2\.2\.3' 'IMPLEMENTATION-PLAN version matches v2.2.3'
require_text module/binance/TRACEABILITY.md 'Spec-Reference: `module/binance/SPEC\.md` v2\.2\.3' 'TRACEABILITY spec reference matches v2.2.3'
require_text module/binance/CHANGELOG.md 'Spec-Reference: `module/binance/SPEC\.md` v2\.2\.3' 'CHANGELOG spec reference matches v2.2.3'

# R2 4x4 symmetry: NATS subjects and Kafka topics must be explicitly enumerable in SSOT docs.
product_lines=(spot um_perp cm_perp options)
event_types=(tick bar depth trade)
for product_line in "${product_lines[@]}"; do
  for event_type in "${event_types[@]}"; do
    require_text module/binance/NAMING.md "binance\.market\.${product_line}\.${event_type}" "NAMING has NATS subject ${product_line}.${event_type}"
    require_text module/binance/RUNTIME-MAPPING.md "binance\.market\.${product_line}\.${event_type}" "RUNTIME-MAPPING has NATS subject ${product_line}.${event_type}"
    require_text module/binance/SPEC.md "binance\.market\.${product_line}\.${event_type}" "SPEC has NATS subject ${product_line}.${event_type}"
    require_text module/binance/NAMING.md "binance\.${product_line}\.${event_type}\.v1" "NAMING has Kafka topic ${product_line}.${event_type}"
    require_text module/binance/RUNTIME-MAPPING.md "binance\.${product_line}\.${event_type}\.v1" "RUNTIME-MAPPING has Kafka topic ${product_line}.${event_type}"
  done
done

# Stage0 Kafka topic repair: active Kafka docs must not use the NATS subject template as Kafka topic.
reject_text module/binance/ACCEPTANCE.md 'kafkax.*binance\.market\.\{product_line\}\.\{event_type\}' 'ACCEPTANCE Kafka topic is not old NATS template'
reject_text module/binance/TRACEABILITY.md 'kafkax.*binance\.market' 'TRACEABILITY Kafka topic is not old NATS template'
reject_text module/binance/server/tasks/TASK-BINANCE-SERVER-014-kafkax-dispatch.md 'topic.*binance\.market\.\{product_line\}\.\{event_type\}' 'SERVER-014 Kafka topic is not old NATS template'
require_text module/binance/server/tasks/TASK-BINANCE-SERVER-014-kafkax-dispatch.md 'binance\.\{product_line\}\.\{event_type\}\.v1' 'SERVER-014 documents versioned Kafka topic template'

# R1 naming aliases: operational docs must not reintroduce legacy product-line aliases.
legacy_alias='usdm_futures|coinm_futures|futures_usdt|futures_coin|option|opts'
scan_files=(
  module/binance/SPEC.md
  module/binance/README.md
  module/binance/TRACEABILITY.md
  module/binance/IMPLEMENTATION-PLAN.md
  module/binance/FEATURES.md
  module/binance/ACCEPTANCE.md
  module/binance/RUNTIME-MAPPING.md
  module/binance/client/SPEC.md
  module/binance/server/SPEC.md
  module/binance/client/TRACEABILITY.md
  module/binance/server/TRACEABILITY.md
)
for file in "${scan_files[@]}"; do
  reject_text "$file" "(^|[^[:alnum:]_])(${legacy_alias})([^[:alnum:]_]|$)" "no legacy alias in $file"
done

# R5 archive isolation remains physically documented.
if find module/binance/client/tasks/archive module/binance/server/tasks/archive -type f >/dev/null 2>&1; then
  pass 'archive task directories are physically isolated'
else
  fail 'archive task directories are missing'
fi

# Stage2 draft shape.
require_text module/binance/DATA-LIFECYCLE.md 'DL-GAP-015' 'DATA-LIFECYCLE records 15 lifecycle gaps'
require_text module/binance/DATA-LIFECYCLE.md 'FR-024' 'DATA-LIFECYCLE records 13 suggested FR landing points through FR-024'
require_text module/binance/DATA-LIFECYCLE.md 'does not modify `SPEC\.md`' 'DATA-LIFECYCLE states no direct SPEC modification'

if (( failures > 0 )); then
  printf 'SUMMARY FAIL %d check(s) failed\n' "$failures"
  exit 1
fi
printf 'SUMMARY PASS all binance doc checks passed\n'
