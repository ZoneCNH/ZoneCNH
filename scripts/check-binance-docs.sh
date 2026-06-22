#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"

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

table_value() {
  local key=$1 path=$2
  awk -F'|' -v key="$key" '$2 ~ key {v=$3; gsub(/^[ \t]+|[ \t]+$/, "", v); print v; exit}' "$path"
}

spec_version=$(sed -nE 's/^- Spec-Version: (v[0-9.]+).*/\1/p' module/binance/SPEC.md | head -1)
readme_root=$(sed -nE 's/^- Spec-Version: (v[0-9.]+).*/\1/p' module/binance/README.md | head -1)
trace_ref=$(sed -nE 's/^- Spec-Reference: `module\/binance\/SPEC.md` (v[0-9.]+).*/\1/p' module/binance/TRACEABILITY.md | head -1)
acceptance_version=$(table_value "Module-Version" module/binance/ACCEPTANCE.md)
features_version=$(table_value "Module-Version" module/binance/FEATURES.md)
impl_version=$(sed -nE 's/^- Version: (v[0-9.]+).*/\1/p' module/binance/IMPLEMENTATION-PLAN.md | head -1)
changelog_ref=$(sed -nE 's/^- Spec-Reference: `module\/binance\/SPEC.md` (v[0-9.]+).*/\1/p' module/binance/CHANGELOG.md | head -1)

expect_eq "README root Spec-Version" "$spec_version" "$readme_root"
expect_eq "TRACEABILITY Spec-Reference" "$spec_version" "$trace_ref"
expect_eq "ACCEPTANCE Module-Version" "$spec_version" "$acceptance_version"
expect_eq "FEATURES Module-Version" "$spec_version" "$features_version"
expect_eq "IMPLEMENTATION-PLAN Version" "$spec_version" "$impl_version"
expect_eq "CHANGELOG Spec-Reference" "$spec_version" "$changelog_ref"

for f in SPEC.md TRACEABILITY.md ACCEPTANCE.md FEATURES.md IMPLEMENTATION-PLAN.md \
         RUNTIME-MAPPING.md BOUNDARY-GATES.md NAMING.md RULES.md \
         ARCHITECTURE-DRIFT-WATCHLIST.md CHANGELOG.md client/SPEC.md \
         client/TRACEABILITY.md server/SPEC.md server/TRACEABILITY.md \
         client/tasks/archive/README.md server/tasks/archive/README.md; do
  expect_file "module/binance/$f"
done
expect_file "scripts/check-binance-docs.sh"
expect_executable "scripts/check-binance-docs.sh"

product_lines=(spot um_perp cm_perp options)
event_types=(tick trade bar depth)

for product_line in "${product_lines[@]}"; do
  for event_type in "${event_types[@]}"; do
    expect_rg "binance\\.market\\.${product_line}\\.${event_type}" module/binance/RUNTIME-MAPPING.md "NATS subject ${product_line}/${event_type}"
    expect_rg "binance\\.${product_line}\\.${event_type}\\.v1" module/binance/RUNTIME-MAPPING.md "Kafka runtime mapping ${product_line}/${event_type}"
    expect_rg "binance\\.${product_line}\\.${event_type}\\.v1" module/binance/server/tasks/TASK-BINANCE-SERVER-014-kafkax-dispatch.md "Kafka task ${product_line}/${event_type}"
  done
done

expect_rg "CREATE STABLE IF NOT EXISTS binance_market_ticks" module/binance/server/tasks/TASK-BINANCE-SERVER-013-taosx-storage.md "taosx ticks stable"
expect_rg "CREATE STABLE IF NOT EXISTS binance_market_depth" module/binance/server/tasks/TASK-BINANCE-SERVER-013-taosx-storage.md "taosx depth stable"
expect_rg "binance/\\{product_line\\}/\\{symbol\\}/\\{YYYY\\}/\\{MM\\}/\\{DD\\}/\\{event_type\\}\\.parquet" module/binance/server/tasks/TASK-BINANCE-SERVER-016-ossx-archiver.md "ossx generic 4x4 archive path"
expect_rg "/api/v1/market/ticks" module/binance/server/tasks/TASK-BINANCE-SERVER-015-gin-market-api.md "Gin ticks route"
expect_rg "/api/v1/market/depth" module/binance/server/tasks/TASK-BINANCE-SERVER-015-gin-market-api.md "Gin depth route"

expect_no_rg 'binance\.market\.(spot|um_perp|cm_perp|options)\.(tick|trade|bar|depth)|topic := fmt.Sprintf\("binance\.market' module/binance/server/tasks/TASK-BINANCE-SERVER-014-kafkax-dispatch.md "Kafka task has no legacy topic format"
expect_rg 'Kafka topic 格式：`binance\.\{product_line\}\.\{event_type\}\.v1`' module/binance/server/tasks/TASK-BINANCE-SERVER-014-kafkax-dispatch.md "Kafka canonical format documented"
expect_rg 'topic = `binance\.\{product_line\}\.\{event_type\}\.v1`' module/binance/server/TRACEABILITY.md "server TRACEABILITY Kafka topic canonical"
expect_no_rg 'topic = `binance\.market' module/binance/server/TRACEABILITY.md "server TRACEABILITY has no legacy Kafka topic"
expect_no_rg 'binance\.market\.(ticks|bars|depth|events)|fmt.Sprintf\("binance\.market|kafkax\.Send\("binance\.market' module/binance/DEEP-ANALYSIS.md "DEEP-ANALYSIS has no legacy Kafka topic examples"
expect_rg '\| AC-029 \| FR-008 \| kafkax topic = `binance\.\{product_line\}\.\{event_type\}\.v1` \|' module/binance/TRACEABILITY.md "TRACEABILITY AC-029 maps to FR-008"
expect_rg '\| AC-032 \| FR-009 \| server 源码无 `internal/client` 或 `internal/cs` 导入' module/binance/TRACEABILITY.md "TRACEABILITY AC-032 maps to FR-009"
expect_rg '\| AC-028 \| FR-008 \| Server 通过 `kafkax` 发送 `binance\.\{product_line\}\.\{event_type\}\.v1`' module/binance/ACCEPTANCE.md "ACCEPTANCE AC-028 maps to FR-008"
expect_rg '\| AC-031 \| FR-009 \| CI 禁止 `binance-client` 导入 server internals' module/binance/ACCEPTANCE.md "ACCEPTANCE AC-031 maps to FR-009"
expect_rg '\| TC-020 \| FR-009, BR-005 \|' module/binance/ACCEPTANCE.md "ACCEPTANCE TC-020 maps to FR-009"
expect_rg '\| TC-021 \| FR-009, BR-001 \|' module/binance/ACCEPTANCE.md "ACCEPTANCE TC-021 maps to FR-009"
expect_rg '\| TC-022 \| FR-009, BR-009 \|' module/binance/ACCEPTANCE.md "ACCEPTANCE TC-022 maps to FR-009"

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

expect_rg '\| FR-009 \|.*runtime SHA `bae80d6`' module/binance/TRACEABILITY.md "FR-009 has runtime SHA evidence"
expect_rg "L1 Boundary/Governance Gate" module/binance/RULES.md "RULES documents L1/L2 status boundary"
expect_rg "bash scripts/check-binance-docs\\.sh" .github/workflows/docs-ci.yml "docs CI runs binance checker"

if (( failures > 0 )); then
  printf '%s check(s) failed\n' "$failures" >&2
  exit 1
fi

printf 'binance docs checks passed\n'
