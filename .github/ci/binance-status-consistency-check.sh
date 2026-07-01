#!/usr/bin/env bash
# binance-status-consistency-check.sh — 校验 binance 模块状态一致性

set -euo pipefail

FAIL=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BINANCE_DIR="$REPO_ROOT/module/binance"
SPEC_FILE="$BINANCE_DIR/spec/SPEC.md"
FEATURES_FILE="$BINANCE_DIR/spec/FEATURES.md"
ACCEPTANCE_FILE="$BINANCE_DIR/spec/ACCEPTANCE.md"
TRACEABILITY_FILE="$BINANCE_DIR/matrix/TRACEABILITY.md"
LEGACY_MAPPING_FILE="$REPO_ROOT/docs/migrations/ac-bnc-legacy-mapping.md"
EXPECTED_STATS="48 Done / 0 Partial / 0 Drifted / 0 Pending"

fail() {
  echo "FAIL: $*"
  FAIL=1
}

require_pattern() {
  local file="$1"
  local pattern="$2"
  local message="$3"

  if ! grep -Eq -- "$pattern" "$file"; then
    fail "$message"
  fi
}

forbid_pattern() {
  local file="$1"
  local pattern="$2"
  local message="$3"

  if grep -Eq -- "$pattern" "$file"; then
    fail "$message"
  fi
}

table_status() {
  local file="$1"
  local fr="$2"
  local col="$3"

  awk -F'|' -v fr="$fr" -v col="$col" '
    {
      id = $2
      gsub(/[*`]/, "", id)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", id)
      if (id == fr) {
        status = $col
        gsub(/[*`]/, "", status)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", status)
        sub(/^Code-/, "", status)
        print status
        exit
      }
    }
  ' "$file"
}

require_table_status() {
  local file="$1"
  local fr="$2"
  local col="$3"
  local expected="$4"
  local message="$5"
  local actual

  actual="$(table_status "$file" "$fr" "$col")"
  if [ "$actual" != "$expected" ]; then
    fail "$message (actual: ${actual:-NOT_FOUND})"
  fi
}

summary_stats() {
  local file="$1"
  local pattern="$2"
  sed -nE "$pattern" "$file" | head -1
}

count_status_column() {
  local file="$1"
  local col="$2"

  awk -F'|' -v col="$col" '
    BEGIN {
      count["Done"] = 0
      count["Partial"] = 0
      count["Drifted"] = 0
      count["Pending"] = 0
    }
    /^\| FR-[0-9][0-9][0-9][a-z]? / {
      status = $col
      gsub(/[*`]/, "", status)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", status)
      sub(/^Code-/, "", status)
      sub(/[（(].*/, "", status)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", status)
      if (status in count) {
        count[status]++
      }
    }
    END {
      printf "%d Done / %d Partial / %d Drifted / %d Pending", \
        count["Done"], count["Partial"], count["Drifted"], count["Pending"]
    }
  ' "$file"
}

drifted_from_readme() {
  local line

  line=$(
    sed -nE 's/.*Drifted FR: ([^（。.]*)[（。.].*/\1/p' "$BINANCE_DIR/README.md" |
      head -1
  )
  printf '%s\n' "$line" |
    { grep -Eo 'FR-[0-9]{3}[a-z]?' || true; } |
    sort -u |
    paste -sd, -
}

drifted_from_status_column() {
  local file="$1"
  local col="$2"

  awk -F'|' -v col="$col" '
    /^\| FR-[0-9][0-9][0-9][a-z]? / {
      fr = $2
      status = $col
      gsub(/[*`]/, "", fr)
      gsub(/[*`]/, "", status)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", fr)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", status)
      sub(/^Code-/, "", status)
      if (status == "Drifted") {
        print fr
      }
    }
  ' "$file" | sort -u | paste -sd, -
}

drifted_from_acceptance() {
  awk -F'|' '
    /^\| FR-[0-9][0-9][0-9][a-z]? / && /Code-Drifted/ {
      fr = $2
      gsub(/[*`]/, "", fr)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", fr)
      print fr
    }
  ' "$BINANCE_DIR/spec/ACCEPTANCE.md" | sort -u | paste -sd, -
}

echo "=== Binance Status Consistency Check ==="
echo ""

for file in README.md spec/SPEC.md spec/FEATURES.md spec/ACCEPTANCE.md matrix/TRACEABILITY.md prompt/README.md; do
  if [ ! -f "$BINANCE_DIR/$file" ]; then
    fail "$file not found"
  fi
done
if [ ! -f "$LEGACY_MAPPING_FILE" ]; then
  fail "docs/migrations/ac-bnc-legacy-mapping.md not found"
fi

if [ "$FAIL" -ne 0 ]; then
  echo ""
  echo "Result: FAIL (missing files)"
  exit 1
fi

readme_stats=$(
  summary_stats "$BINANCE_DIR/README.md" \
    's/.*single state `([0-9]+ Done \/ [0-9]+ Partial \/ [0-9]+ Drifted \/ [0-9]+ Pending)`.*/\1/p'
)
features_stats=$(count_status_column "$BINANCE_DIR/spec/FEATURES.md" 4)
acceptance_stats=$(
  summary_stats "$BINANCE_DIR/spec/ACCEPTANCE.md" \
    's/.*FR \*\*([0-9]+ Done \/ [0-9]+ Partial \/ [0-9]+ Drifted \/ [0-9]+ Pending)\*\*.*/\1/p'
)
prompt_stats=$(
  summary_stats "$BINANCE_DIR/prompt/README.md" \
    's/.*单状态模型：`([0-9]+ Done \/ [0-9]+ Partial \/ [0-9]+ Drifted \/ [0-9]+ Pending)`.*/\1/p'
)
traceability_stats=$(count_status_column "$BINANCE_DIR/matrix/TRACEABILITY.md" 6)
traceability_summary_stats=$(
  summary_stats "$BINANCE_DIR/matrix/TRACEABILITY.md" \
    's/^- (\[KNOWN\] )?Current-State: ([0-9]+ Done \/ [0-9]+ Partial \/ [0-9]+ Drifted \/ [0-9]+ Pending).*/\2/p'
)

echo "README.md Code stats:       ${readme_stats:-NOT_FOUND}"
echo "FEATURES.md Code stats:     ${features_stats:-NOT_FOUND}"
echo "ACCEPTANCE.md Code stats:   ${acceptance_stats:-NOT_FOUND}"
echo "prompt/README.md Code stats: ${prompt_stats:-NOT_FOUND}"
echo "TRACEABILITY.md Code stats: ${traceability_stats:-NOT_FOUND}"
echo "TRACEABILITY.md Summary:    ${traceability_summary_stats:-NOT_FOUND}"

if [ -z "$readme_stats" ]; then
  fail "unable to extract README.md Code stats"
fi
if [ -z "$features_stats" ]; then
  fail "unable to extract FEATURES.md Code stats"
fi
if [ -z "$acceptance_stats" ]; then
  fail "unable to extract ACCEPTANCE.md Code stats"
fi
if [ -z "$prompt_stats" ]; then
  fail "unable to extract prompt/README.md Code stats"
fi
if [ -z "$traceability_stats" ]; then
  fail "unable to extract TRACEABILITY.md Code stats"
fi
if [ -z "$traceability_summary_stats" ]; then
  fail "unable to extract TRACEABILITY.md summary stats"
fi
if [ "$readme_stats" != "$features_stats" ] ||
  [ "$readme_stats" != "$acceptance_stats" ] ||
  [ "$readme_stats" != "$prompt_stats" ] ||
  [ "$readme_stats" != "$traceability_stats" ] ||
  [ "$readme_stats" != "$traceability_summary_stats" ]; then
  fail "Code status stats mismatch across README / FEATURES / ACCEPTANCE / prompt README / TRACEABILITY / TRACEABILITY summary"
fi
if [ "$readme_stats" != "$EXPECTED_STATS" ]; then
  fail "single-state stats must remain $EXPECTED_STATS"
fi

echo ""
readme_drifted=$(drifted_from_readme)
features_drifted=$(drifted_from_status_column "$BINANCE_DIR/spec/FEATURES.md" 4)
acceptance_drifted=$(drifted_from_acceptance)
traceability_drifted=$(drifted_from_status_column "$BINANCE_DIR/matrix/TRACEABILITY.md" 6)

echo "README.md Drifted FR:       ${readme_drifted:-NONE}"
echo "FEATURES.md Drifted FR:     ${features_drifted:-NONE}"
echo "ACCEPTANCE.md Drifted FR:   ${acceptance_drifted:-NONE}"
echo "TRACEABILITY.md Drifted FR: ${traceability_drifted:-NONE}"

if [ "$readme_drifted" != "$features_drifted" ] ||
  [ "$readme_drifted" != "$acceptance_drifted" ] ||
  [ "$readme_drifted" != "$traceability_drifted" ]; then
  fail "Drifted FR list mismatch across README / FEATURES / ACCEPTANCE / TRACEABILITY"
fi

echo ""
echo "Checking semantic status guards..."
require_pattern "$SPEC_FILE" "^- State-Model: single-state only$" "SPEC.md must declare single-state model"
require_pattern "$SPEC_FILE" "^## 5\\. State Model$" "SPEC.md must retain State Model section"
require_pattern "$TRACEABILITY_FILE" "^- State-Model: single-state only$" "TRACEABILITY.md must declare single-state model"
require_pattern "$SPEC_FILE" "Open-P10-Issues:" "SPEC.md must expose current P10 issue projection"
require_pattern "$TRACEABILITY_FILE" "GitHub P10 open" "TRACEABILITY.md must expose GitHub P10 open count"
require_pattern "$TRACEABILITY_FILE" "Beads P10 open" "TRACEABILITY.md must expose Beads P10 open count"

echo ""
echo "Checking release_closeable ratio consistency..."
traceability_done=$(echo "$traceability_stats" | awk '{print $1}')
traceability_partial=$(echo "$traceability_stats" | awk '{print $4}')
traceability_drifted=$(echo "$traceability_stats" | awk '{print $7}')
traceability_pending=$(echo "$traceability_stats" | awk '{print $10}')
traceability_total=$((traceability_done + traceability_partial + traceability_drifted + traceability_pending))
done_ratio=$((traceability_done * 100 / traceability_total))
echo "Code-Done ratio: ${traceability_done}/${traceability_total} = ${done_ratio}%"
echo "Drifted: ${traceability_drifted}, Pending: ${traceability_pending}"

if [ "$traceability_drifted" -eq 0 ] && [ "$traceability_pending" -eq 0 ] && [ "$done_ratio" -ge 90 ]; then
  require_pattern "$TRACEABILITY_FILE" "release_closeable: YES" "release_closeable must be YES when Code-Done ≥ 90% and Drifted=0 and Pending=0"
else
  require_pattern "$TRACEABILITY_FILE" "release_closeable: NO" "release_closeable must be NO when Code-Done < 90% or Drifted>0 or Pending>0"
fi

echo ""
echo "Checking dual-state model residue..."
for active_file in "$SPEC_FILE" "$TRACEABILITY_FILE" "$FEATURES_FILE" "$ACCEPTANCE_FILE" "$BINANCE_DIR/README.md" "$BINANCE_DIR/prompt/README.md"; do
  residue=$(grep -E 'Evidence-Done|Evidence-State|Code-State' "$active_file" 2>/dev/null | grep -Ev '废除|abolished|deprecated|历史|legacy|已删除|removed|双态' || true)
  if [ -n "$residue" ]; then
    fail "$active_file must not contain active dual-state model residue (Evidence-Done/Evidence-State/Code-State outside abolition context)"
  fi
done

echo ""
echo "Checking release_closeable formula presence..."
require_pattern "$TRACEABILITY_FILE" "release_closeable = Code-Done FR / Total FR" "TRACEABILITY.md must document the release_closeable formula"
require_pattern "$TRACEABILITY_FILE" "PRG-001~007" "TRACEABILITY.md must reference PRG-001~007 in the release_closeable formula"

echo ""
echo "Checking retired spec artifact guards..."
for retired in spec/SPEC-exchangeinfo-sync.md spec/DATA-LIFECYCLE.md spec/DATA-QUALITY-SLA.md spec/ENDPOINTS.md; do
  if [ -e "$BINANCE_DIR/$retired" ]; then
    fail "$retired must not exist as an active spec artifact"
  fi
done
if [ -d "$BINANCE_DIR/spec/deprecated" ]; then
  fail "spec/deprecated must not exist after deprecated artifact archival"
fi
if [ -e "$BINANCE_DIR/todo.md" ]; then
  if ! grep -Eq 'read-only projection|projection.only|not.*closure.*SSOT|Closure SSOT' "$BINANCE_DIR/todo.md" 2>/dev/null; then
    fail "module/binance/todo.md must be a read-only projection, not an active closure SSOT"
  fi
fi
if [ ! -f "$BINANCE_DIR/evidence/2026-06-28/todo-archived.md" ]; then
  fail "archived todo evidence must exist"
fi
for active_file in "$SPEC_FILE" "$TRACEABILITY_FILE" "$FEATURES_FILE"; do
  forbid_pattern "$active_file" "spec/(deprecated/)?(SPEC-exchangeinfo-sync|DATA-LIFECYCLE|DATA-QUALITY-SLA|ENDPOINTS)\\.md" "retired spec filenames must not appear in active specs"
  forbid_pattern "$active_file" "^\\|[[:space:]]*AC-BNC-[0-9][0-9][0-9][[:space:]]*\\|" "AC-BNC active rows must remain isolated to the legacy mapping"
done
forbid_pattern "$ACCEPTANCE_FILE" "^\\|[[:space:]]*AC-BNC-[0-9][0-9][0-9][[:space:]]*\\|" "AC-BNC active rows must remain isolated to the legacy mapping"

echo ""
echo "Checking legacy AC-BNC mapping guards..."
for n in $(seq 1 18); do
  ac="$(printf 'AC-BNC-%03d' "$n")"
  require_pattern "$LEGACY_MAPPING_FILE" "^\\|[[:space:]]*$ac[[:space:]]*\\|" "$ac legacy mapping row must exist"
done
require_pattern "$LEGACY_MAPPING_FILE" "module/binance/matrix/TRACEABILITY\\.md.*§5" "legacy mapping must point to active TRACEABILITY §5"
require_pattern "$LEGACY_MAPPING_FILE" "module/binance/spec/ACCEPTANCE\\.md.*§2" "legacy mapping must point to active ACCEPTANCE §2"
require_pattern "$LEGACY_MAPPING_FILE" "module/binance/matrix/TRACEABILITY\\.md.*§6" "legacy mapping must point to active TRACEABILITY §6"

echo ""
if [ "$FAIL" -ne 0 ]; then
  echo "Result: FAIL"
  exit 1
fi

echo "Result: PASS"
