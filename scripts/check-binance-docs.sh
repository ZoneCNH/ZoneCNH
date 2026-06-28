#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"

# Guard: SPEC.md is the anchor file for the old-style structure.
# If absent, the module uses the goal-driven structure — skip gracefully.
if [[ ! -f module/binance/SPEC.md ]]; then
  echo "SKIP: module/binance/SPEC.md not found (module uses goal-driven structure)"
  exit 0
fi

failures=0

pass() { printf 'PASS %s\n' "$1"; }
fail() {
  printf 'FAIL %s\n' "$1"
  failures=$((failures + 1))
}

expect_file() {
  local path=$1
  if [[ -f "$path" ]]; then
    pass "file exists: $path"
  else
    fail "missing file: $path"
  fi
}

expect_executable() {
  local path=$1
  if [[ -x "$path" ]]; then
    pass "executable: $path"
  else
    fail "not executable: $path"
  fi
}

expect_eq() {
  local label=$1 expected=$2 actual=$3
  if [[ "$actual" == "$expected" ]]; then
    pass "$label = $expected"
  else
    fail "$label expected $expected got ${actual:-<empty>}"
  fi
}

expect_rg() {
  local pattern=$1 path=$2 label=$3
  if rg -q "$pattern" "$path"; then
    pass "$label"
  else
    fail "$label"
  fi
}

expect_no_rg() {
  local pattern=$1 path=$2 label=$3
  if rg -q "$pattern" "$path"; then
    fail "$label"
  else
    pass "$label"
  fi
}

require_text() {
  local path=$1 pattern=$2 label=$3
  expect_rg "$pattern" "$path" "$label"
}

reject_text() {
  local path=$1 pattern=$2 label=$3
  expect_no_rg "$pattern" "$path" "$label"
}

table_value() {
  local key=$1 path=$2
  awk -F'|' -v key="$key" '$2 ~ key {v=$3; gsub(/^[ \t]+|[ \t]+$/, "", v); print v; exit}' "$path"
}

spec_version=$(sed -nE 's/^- Spec-Version: (v[0-9.]+).*/\1/p' module/binance/SPEC.md | head -1)
readme_root=$(sed -nE 's/^- Spec-Version: (v[0-9.]+).*/\1/p' module/binance/README.md | head -1)
trace_ref=$(sed -nE 's/^- Spec-Reference: `module\/binance\/SPEC.md` (v[0-9.]+).*/\1/p' module/binance/TRACEABILITY.md | head -1)
acceptance_version=$(table_value "Module-Version" module/binance/ACCEPTANCE.md)
features_version=$(table_value "Module-Version" module/binance/FEATURES.md)
impl_version=$(sed -nE 's/^- Module-Version: (v[0-9.]+).*/\1/p' module/binance/IMPLEMENTATION-PLAN.md | head -1)
changelog_ref=$(sed -nE 's/^- Spec-Reference: `module\/binance\/SPEC.md` (v[0-9.]+).*/\1/p' module/binance/CHANGELOG.md | head -1)

expect_eq "README root Spec-Version" "$spec_version" "$readme_root"
expect_eq "TRACEABILITY Spec-Reference" "$spec_version" "$trace_ref"
expect_eq "ACCEPTANCE Module-Version" "$spec_version" "$acceptance_version"
expect_eq "FEATURES Module-Version" "$spec_version" "$features_version"
expect_eq "IMPLEMENTATION-PLAN Module-Version" "$spec_version" "$impl_version"
expect_eq "CHANGELOG Spec-Reference" "$spec_version" "$changelog_ref"

# R6 全量版本统一：顶层治理文档 Module-Version == root SPEC Spec-Version
for f in RULES.md NAMING.md DATA-LIFECYCLE.md STANDARD.md ARCHITECTURE-DRIFT-WATCHLIST.md; do
  v=$(sed -nE 's/^- Module-Version: (v[0-9.]+).*/\1/p' module/binance/$f | head -1)
  [ -z "$v" ] && v=$(table_value "Module-Version" module/binance/$f)
  expect_eq "$f Module-Version" "$spec_version" "$v"
done

# R6 子规格对称：client/server TRACEABILITY Module-Version == 对应子 SPEC Spec-Version
client_spec=$(sed -nE 's/^- Spec-Version: (v[0-9.]+).*/\1/p' module/binance/client/SPEC.md | head -1)
server_spec=$(sed -nE 's/^\| Spec-Version \| (v[0-9.]+).*/\1/p' module/binance/server/SPEC.md | head -1)
client_trace=$(sed -nE 's/^- Module-Version: (v[0-9.]+).*/\1/p' module/binance/client/TRACEABILITY.md | head -1)
server_trace=$(sed -nE 's/^- Module-Version: (v[0-9.]+).*/\1/p' module/binance/server/TRACEABILITY.md | head -1)
client_trace_ref=$(sed -nE 's/^- Spec-Reference: `module\/binance\/client\/SPEC.md` (v[0-9.]+).*/\1/p' module/binance/client/TRACEABILITY.md | head -1)
server_trace_ref=$(sed -nE 's/^- Spec-Reference: `module\/binance\/server\/SPEC.md` (v[0-9.]+).*/\1/p' module/binance/server/TRACEABILITY.md | head -1)
expect_eq "client/TRACEABILITY Module-Version" "$client_spec" "$client_trace"
expect_eq "server/TRACEABILITY Module-Version" "$server_spec" "$server_trace"
expect_eq "client/TRACEABILITY Spec-Reference" "$client_spec" "$client_trace_ref"
expect_eq "server/TRACEABILITY Spec-Reference" "$server_spec" "$server_trace_ref"

# R6 异名字段禁用：禁止 Doc-Version / Matrix-Version / ^- Version:
for f in module/binance/*.md module/binance/client/*.md module/binance/server/*.md; do
  case "$f" in
    */DEEP-ANALYSIS.md|*/goal.md|*/BOUNDARY-GATES.md|*/RUNTIME-MAPPING.md|*/client/README.md|*/server/README.md|*/client/IMPLEMENTATION-PLAN.md|*/server/IMPLEMENTATION-PLAN.md|*/tasks/*) continue ;;
  esac
  if grep -qE '^[-|] (Doc-Version|Matrix-Version|Version) [:(|]' "$f" 2>/dev/null; then
    echo "FAIL $f uses deprecated version field name (Doc-Version/Matrix-Version/Version); use Module-Version or Spec-Version"
    exit 1
  fi
done

for f in SPEC.md TRACEABILITY.md ACCEPTANCE.md FEATURES.md IMPLEMENTATION-PLAN.md \
         RUNTIME-MAPPING.md BOUNDARY-GATES.md NAMING.md RULES.md \
         ARCHITECTURE-DRIFT-WATCHLIST.md CHANGELOG.md STANDARD.md client/SPEC.md \
         client/TRACEABILITY.md server/SPEC.md server/TRACEABILITY.md \
         client/tasks/archive/README.md server/tasks/archive/README.md; do
  expect_file "module/binance/$f"
done
expect_file "scripts/check-binance-docs.sh"
expect_executable "scripts/check-binance-docs.sh"

product_lines=(spot um_perp cm_perp options)
event_types=(tick trade bar depth funding_rate mark_price)

for product_line in "${product_lines[@]}"; do
  for event_type in "${event_types[@]}"; do
    expect_rg "binance\\.market\\.${product_line}\\.${event_type}" module/binance/RUNTIME-MAPPING.md "NATS subject ${product_line}/${event_type}"
    expect_rg "binance\\.${product_line}\\.${event_type}\\.v1" module/binance/RUNTIME-MAPPING.md "Kafka runtime mapping ${product_line}/${event_type}"
    expect_rg "binance\\.${product_line}\\.${event_type}\\.v1" module/binance/server/tasks/TASK-BINANCE-SERVER-014-kafkax-dispatch.md "Kafka task ${product_line}/${event_type}"
  done
done

# Stage0 Kafka topic repair: active Kafka docs must not use the NATS subject template as Kafka topic.
reject_text module/binance/ACCEPTANCE.md 'kafkax.*binance\.market\.\{product_line\}\.\{event_type\}' 'ACCEPTANCE Kafka topic is not old NATS template'
reject_text module/binance/TRACEABILITY.md 'kafkax.*binance\.market' 'TRACEABILITY Kafka topic is not old NATS template'
reject_text module/binance/server/tasks/TASK-BINANCE-SERVER-014-kafkax-dispatch.md '[Tt]opic.*binance\.market\.\{product_line\}\.\{event_type\}' 'SERVER-014 Kafka topic is not old NATS template'
require_text module/binance/server/tasks/TASK-BINANCE-SERVER-014-kafkax-dispatch.md 'binance\.\{product_line\}\.\{event_type\}\.v1' 'SERVER-014 documents versioned Kafka topic template'
require_text module/binance/server/TRACEABILITY.md 'binance\.\{product_line\}\.\{event_type\}\.v1' 'server TRACEABILITY documents versioned Kafka topic template'

# R1 naming aliases: operational docs must not reintroduce legacy product-line aliases.
legacy_alias='usdm_futures|coinm_futures|futures_usdt|futures_coin|opts'
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

expect_no_rg "FR-010, BOUNDARY-GATES\\.md" module/binance/SPEC.md "SPEC boundary gate references FR-009"

implemented_functional=$(awk -F'|' '
  $2 ~ /^[[:space:]]*FR-[0-9]/ {
    id=$2
    row=$0
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", id)
    if (row ~ /\*\*Implemented\*\*/ && id != "FR-009") {
      print id
    }
  }
' module/binance/TRACEABILITY.md)

if [[ -z "$implemented_functional" ]]; then
  pass "only FR-009 is Implemented in root FR table"
else
  fail "non-boundary FR marked Implemented: $implemented_functional"
fi

expect_rg 'FR-009/BR Done 的 2026-06-23.*本地 runtime 证据' module/binance/TRACEABILITY.md "FR-009 has current runtime evidence"
expect_rg '证据提交 `71e2a6e8bb5591c43e8a2ebfff8c7645bf030786`' module/binance/TRACEABILITY.md "FR-009 records published evidence commit"
expect_rg "L1 Boundary/Governance Gate" module/binance/RULES.md "RULES documents L1/L2 status boundary"
expect_rg "bash scripts/check-binance-docs\\.sh" .github/workflows/docs-ci.yml "docs CI runs binance checker"
expect_rg 'POST /api/v1/admin/symbols/reload' module/binance/STANDARD.md "STANDARD documents current symbols reload endpoint"
expect_rg 'FR-024' module/binance/STANDARD.md "STANDARD documents FR-024 boundary"
expect_rg 'FR-030' module/binance/SPEC.md "SPEC includes FR-030"
expect_rg 'AC-104' module/binance/TRACEABILITY.md "TRACEABILITY includes AC-104"
expect_rg 'TC-049' module/binance/TRACEABILITY.md "TRACEABILITY includes TC-049"
expect_rg '4 product lines × 6 event types × 5 文档/checker anchors' module/binance/TRACEABILITY.md "TRACEABILITY documents R2 120-cell matrix"
expect_rg 'POST /api/v1/admin/symbols/reload' module/binance/RUNTIME-MAPPING.md "RUNTIME-MAPPING uses current symbols reload endpoint"
expect_no_rg 'POST /api/v1/admin/catalog/reload' module/binance/RUNTIME-MAPPING.md "RUNTIME-MAPPING drops legacy catalog reload endpoint"

if (( failures > 0 )); then
  printf '%s check(s) failed\n' "$failures" >&2
  exit 1
fi

printf 'binance docs checks passed\n'
