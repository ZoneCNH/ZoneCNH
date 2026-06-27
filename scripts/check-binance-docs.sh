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

binance_root=module/binance
spec_dir=$binance_root/spec
matrix_dir=$binance_root/matrix
gate_dir=$binance_root/gate
design_dir=$binance_root/design
plan_dir=$binance_root/plan
tasks_dir=$binance_root/tasks

root_spec=$spec_dir/SPEC.md
root_readme=$binance_root/README.md
root_trace=$matrix_dir/TRACEABILITY.md
root_acceptance=$spec_dir/ACCEPTANCE.md
root_features=$spec_dir/FEATURES.md
root_plan=$plan_dir/PLAN.md
root_changelog=$binance_root/CHANGELOG.md
root_runtime_mapping=$design_dir/RUNTIME-MAPPING.md
root_boundary_gates=$gate_dir/BOUNDARY-GATES.md
root_rules=$gate_dir/RULES.md
root_standard=$gate_dir/STANDARD.md
root_naming=$spec_dir/NAMING.md
root_data_lifecycle=$spec_dir/DATA-LIFECYCLE.md
root_drift_watchlist=$design_dir/ARCHITECTURE-DRIFT-WATCHLIST.md
client_spec_file=$spec_dir/client/SPEC.md
client_trace_file=$matrix_dir/client/TRACEABILITY.md
server_spec_file=$spec_dir/server/SPEC.md
server_trace_file=$matrix_dir/server/TRACEABILITY.md
server_kafka_task=$tasks_dir/server/TASK-BINANCE-SERVER-014-kafkax-dispatch.md

spec_version=$(sed -nE 's/^- Spec-Version: (v[0-9.]+).*/\1/p' "$root_spec" | head -1)
readme_root=$(sed -nE 's/^- Spec-Version: (v[0-9.]+).*/\1/p' "$root_readme" | head -1)
trace_ref=$(sed -nE 's/^- Spec-Reference: `module\/binance\/spec\/SPEC.md` (v[0-9.]+).*/\1/p' "$root_trace" | head -1)
acceptance_version=$(table_value "Module-Version" "$root_acceptance")
features_version=$(table_value "Module-Version" "$root_features")
plan_version=$(sed -nE 's/^- Module-Version: (v[0-9.]+).*/\1/p' "$root_plan" | head -1)
changelog_ref=$(sed -nE 's/^- Spec-Reference: `module\/binance\/spec\/SPEC.md` (v[0-9.]+).*/\1/p' "$root_changelog" | head -1)

expect_eq "README root Spec-Version" "$spec_version" "$readme_root"
expect_eq "TRACEABILITY Spec-Reference" "$spec_version" "$trace_ref"
expect_eq "ACCEPTANCE Module-Version" "$spec_version" "$acceptance_version"
expect_eq "FEATURES Module-Version" "$spec_version" "$features_version"
expect_eq "PLAN Module-Version" "$spec_version" "$plan_version"
expect_eq "CHANGELOG Spec-Reference" "$spec_version" "$changelog_ref"

# R6 全量版本统一：顶层治理文档 Module-Version == root SPEC Spec-Version
for f in "$root_rules" "$root_naming" "$root_standard" "$root_drift_watchlist"; do
  v=$(sed -nE 's/^- Module-Version: (v[0-9.]+).*/\1/p' "$f" | head -1)
  [ -z "$v" ] && v=$(table_value "Module-Version" "$f")
  expect_eq "$f Module-Version" "$spec_version" "$v"
done

# R6 子规格对称：client/server TRACEABILITY Module-Version == 对应子 SPEC Spec-Version
client_spec_version=$(sed -nE 's/^- Spec-Version: (v[0-9.]+).*/\1/p' "$client_spec_file" | head -1)
server_spec_version=$(sed -nE 's/^\| Spec-Version \| (v[0-9.]+).*/\1/p' "$server_spec_file" | head -1)
client_trace_version=$(sed -nE 's/^- Module-Version: (v[0-9.]+).*/\1/p' "$client_trace_file" | head -1)
server_trace_version=$(sed -nE 's/^- Module-Version: (v[0-9.]+).*/\1/p' "$server_trace_file" | head -1)
client_trace_ref=$(sed -nE 's/^- Spec-Reference: `module\/binance\/spec\/client\/SPEC.md` (v[0-9.]+).*/\1/p' "$client_trace_file" | head -1)
server_trace_ref=$(sed -nE 's/^- Spec-Reference: `module\/binance\/spec\/server\/SPEC.md` (v[0-9.]+).*/\1/p' "$server_trace_file" | head -1)
expect_eq "client/TRACEABILITY Module-Version" "$client_spec_version" "$client_trace_version"
expect_eq "server/TRACEABILITY Module-Version" "$server_spec_version" "$server_trace_version"
expect_eq "client/TRACEABILITY Spec-Reference" "$client_spec_version" "$client_trace_ref"
expect_eq "server/TRACEABILITY Spec-Reference" "$server_spec_version" "$server_trace_ref"

# R6 异名字段禁用：禁止 Doc-Version / Matrix-Version / ^- Version:
while IFS= read -r f; do
  case "$f" in
    */DEEP-ANALYSIS*.md|*/goal.md|*/BOUNDARY-GATES.md|*/RUNTIME-MAPPING.md|*/README.md|*/tasks/*|*/evidence/*|*/design/ADR-*.md|*/design/STRUCTURAL-SCORING-*.md|*/schema/*|*/prompt/*) continue ;;
  esac
  if grep -qE '^[-|] (Doc-Version|Matrix-Version|Version) [:(|]' "$f" 2>/dev/null; then
    echo "FAIL $f uses deprecated version field name (Doc-Version/Matrix-Version/Version); use Module-Version or Spec-Version"
    exit 1
  fi
done < <(rg --files "$binance_root" -g '*.md' | sort)

for f in "$root_spec" "$root_trace" "$root_acceptance" "$root_features" "$root_plan" \
         "$root_runtime_mapping" "$root_boundary_gates" "$root_naming" "$root_rules" \
         "$root_drift_watchlist" "$root_changelog" "$root_standard" "$client_spec_file" \
         "$client_trace_file" "$server_spec_file" "$server_trace_file" \
         "$tasks_dir/client/README.md" "$tasks_dir/server/README.md"; do
  expect_file "$f"
done
expect_file "scripts/check-binance-docs.sh"
expect_executable "scripts/check-binance-docs.sh"

product_lines=(spot um_perp cm_perp options)
event_types=(tick trade bar depth funding_rate mark_price)

for product_line in "${product_lines[@]}"; do
  for event_type in "${event_types[@]}"; do
    expect_rg "binance\\.market\\.${product_line}\\.${event_type}" "$root_runtime_mapping" "NATS subject ${product_line}/${event_type}"
    expect_rg "binance\\.${product_line}\\.${event_type}\\.v1" "$root_runtime_mapping" "Kafka runtime mapping ${product_line}/${event_type}"
    expect_rg "binance\\.${product_line}\\.${event_type}\\.v1" "$server_kafka_task" "Kafka task ${product_line}/${event_type}"
  done
done

# Stage0 Kafka topic repair: active Kafka docs must not use the NATS subject template as Kafka topic.
reject_text "$root_acceptance" 'kafkax.*binance\.market\.\{product_line\}\.\{event_type\}' 'ACCEPTANCE Kafka topic is not old NATS template'
reject_text "$root_trace" 'kafkax.*binance\.market' 'TRACEABILITY Kafka topic is not old NATS template'
reject_text "$server_kafka_task" '[Tt]opic.*binance\.market\.\{product_line\}\.\{event_type\}' 'SERVER-014 Kafka topic is not old NATS template'
require_text "$server_kafka_task" 'binance\.\{product_line\}\.\{event_type\}\.v1' 'SERVER-014 documents versioned Kafka topic template'
require_text "$server_trace_file" 'binance\.\{product_line\}\.\{event_type\}\.v1' 'server TRACEABILITY documents versioned Kafka topic template'

# R1 naming aliases: operational docs must not reintroduce legacy product-line aliases.
legacy_alias='usdm_futures|coinm_futures|futures_usdt|futures_coin|opts'
scan_files=(
  "$root_spec"
  "$root_readme"
  "$root_trace"
  "$root_plan"
  "$root_features"
  "$root_acceptance"
  "$root_runtime_mapping"
  "$client_spec_file"
  "$server_spec_file"
  "$client_trace_file"
  "$server_trace_file"
)
for file in "${scan_files[@]}"; do
  reject_text "$file" "(^|[^[:alnum:]_])(${legacy_alias})([^[:alnum:]_]|$)" "no legacy alias in $file"
done

expect_no_rg "FR-010, BOUNDARY-GATES\\.md" "$root_spec" "SPEC boundary gate references FR-009"

implemented_functional=$(awk -F'|' '
  $2 ~ /^[[:space:]]*FR-[0-9]/ {
    id=$2
    row=$0
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", id)
    if (row ~ /\*\*Implemented\*\*/ && id != "FR-009") {
      print id
    }
  }
' "$root_trace")

if [[ -z "$implemented_functional" ]]; then
  pass "only FR-009 is Implemented in root FR table"
else
  fail "non-boundary FR marked Implemented: $implemented_functional"
fi

expect_rg 'FR-009/BR Done 的 2026-06-23.*本地 runtime 证据' "$root_trace" "FR-009 has current runtime evidence"
expect_rg '证据提交 `71e2a6e8bb5591c43e8a2ebfff8c7645bf030786`' "$root_trace" "FR-009 records published evidence commit"
expect_rg "L1 Boundary/Governance Gate" "$root_rules" "RULES documents L1/L2 status boundary"
expect_rg "bash scripts/check-binance-docs\\.sh" .github/workflows/docs-ci.yml "docs CI runs binance checker"
expect_rg 'POST /api/v1/admin/symbols/reload' "$root_standard" "STANDARD documents current symbols reload endpoint"
expect_rg 'FR-024' "$root_standard" "STANDARD documents FR-024 boundary"
expect_rg 'FR-030' "$root_spec" "SPEC includes FR-030"
expect_rg 'AC-104' "$root_trace" "TRACEABILITY includes AC-104"
expect_rg 'TC-049' "$root_trace" "TRACEABILITY includes TC-049"
expect_rg '4 product lines × 6 event types × 5 文档/checker anchors' "$root_trace" "TRACEABILITY documents R2 120-cell matrix"
expect_rg 'POST /api/v1/admin/symbols/reload' "$root_runtime_mapping" "RUNTIME-MAPPING uses current symbols reload endpoint"
expect_no_rg 'POST /api/v1/admin/catalog/reload' "$root_runtime_mapping" "RUNTIME-MAPPING drops legacy catalog reload endpoint"

if (( failures > 0 )); then
  printf '%s check(s) failed\n' "$failures" >&2
  exit 1
fi

printf 'binance docs checks passed\n'
