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
    's/.*Code `([0-9]+ Done \/ [0-9]+ Partial \/ [0-9]+ Drifted \/ [0-9]+ Pending)`.*/\1/p'
)
features_stats=$(count_status_column "$BINANCE_DIR/spec/FEATURES.md" 4)
acceptance_stats=$(
  summary_stats "$BINANCE_DIR/spec/ACCEPTANCE.md" \
    's/.*FR Code \*\*([0-9]+ Done \/ [0-9]+ Partial \/ [0-9]+ Drifted \/ [0-9]+ Pending)\*\*.*/\1/p'
)
prompt_stats=$(
  summary_stats "$BINANCE_DIR/prompt/README.md" \
    's/.*Code `([0-9]+ Done \/ [0-9]+ Partial \/ [0-9]+ Drifted \/ [0-9]+ Pending)`.*/\1/p'
)
traceability_stats=$(count_status_column "$BINANCE_DIR/matrix/TRACEABILITY.md" 7)
traceability_summary_stats=$(
  summary_stats "$BINANCE_DIR/matrix/TRACEABILITY.md" \
    's/.*当前统计 \*\*([0-9]+ Done \/ [0-9]+ Partial \/ [0-9]+ Drifted \/ [0-9]+ Pending)\*\*.*/\1/p'
)
traceability_dashboard_stats=$(
  summary_stats "$BINANCE_DIR/matrix/TRACEABILITY.md" \
    's/.*当前有效基线分母 48 = \*\*([0-9]+ Done \/ [0-9]+ Partial \/ [0-9]+ Drifted \/ [0-9]+ Pending)\*\*.*/\1/p'
)

echo "README.md Code stats:       ${readme_stats:-NOT_FOUND}"
echo "FEATURES.md Code stats:     ${features_stats:-NOT_FOUND}"
echo "ACCEPTANCE.md Code stats:   ${acceptance_stats:-NOT_FOUND}"
echo "prompt/README.md Code stats: ${prompt_stats:-NOT_FOUND}"
echo "TRACEABILITY.md Code stats: ${traceability_stats:-NOT_FOUND}"
echo "TRACEABILITY.md Summary:    ${traceability_summary_stats:-NOT_FOUND}"
echo "TRACEABILITY.md §6 stats:   ${traceability_dashboard_stats:-NOT_FOUND}"

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
if [ -z "$traceability_dashboard_stats" ]; then
  fail "unable to extract TRACEABILITY.md §6 stats"
fi

if [ "$readme_stats" != "$features_stats" ] ||
  [ "$readme_stats" != "$acceptance_stats" ] ||
  [ "$readme_stats" != "$prompt_stats" ] ||
  [ "$readme_stats" != "$traceability_stats" ] ||
  [ "$readme_stats" != "$traceability_summary_stats" ] ||
  [ "$readme_stats" != "$traceability_dashboard_stats" ]; then
  fail "Code status stats mismatch across README / FEATURES / ACCEPTANCE / prompt README / TRACEABILITY / TRACEABILITY summary/dashboard"
fi

echo ""
readme_drifted=$(drifted_from_readme)
features_drifted=$(drifted_from_status_column "$BINANCE_DIR/spec/FEATURES.md" 4)
acceptance_drifted=$(drifted_from_acceptance)
traceability_drifted=$(drifted_from_status_column "$BINANCE_DIR/matrix/TRACEABILITY.md" 7)

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
for fr in FR-013 FR-017 FR-025; do
  require_table_status "$FEATURES_FILE" "$fr" 4 "Partial" "$fr FEATURES.md status must remain Partial"
  require_table_status "$TRACEABILITY_FILE" "$fr" 7 "Partial" "$fr TRACEABILITY.md status must remain Partial"
  require_pattern "$ACCEPTANCE_FILE" "^\\|[[:space:]]*$fr[[:space:]]*\\|.*Code-Partial" "$fr ACCEPTANCE.md must record Code-Partial"
done
require_pattern "$FEATURES_FILE" "^\\|[[:space:]]*FR-013[[:space:]]*\\|.*Partial.*X-MBX-USED-WEIGHT-1M.*429" "FR-013 Partial reason must preserve used-weight and 429 evidence"
require_pattern "$FEATURES_FILE" "^\\|[[:space:]]*FR-017[[:space:]]*\\|.*Partial.*event_type.*trade_id.*depth updateId" "FR-017 Partial reason must preserve event_type gap strategy evidence"
require_pattern "$FEATURES_FILE" "^\\|[[:space:]]*FR-025[[:space:]]*\\|.*Partial.*ThrottlePriority.*30:20:50" "FR-025 Partial reason must preserve priority throttle evidence"

echo ""
echo "Checking retired spec artifact guards..."
require_pattern "$SPEC_FILE" "^  # 已退役文件（仅保留历史参考，不作为活跃规范）" "SPEC Appendix D must keep retired file section"
for retired in spec/SPEC-exchangeinfo-sync.md spec/DATA-LIFECYCLE.md spec/DATA-QUALITY-SLA.md spec/ENDPOINTS.md; do
  require_pattern "$SPEC_FILE" "^[[:space:]]*$retired[[:space:]]+# DEPRECATED" "$retired must stay in the retired-file partition"
done
require_pattern "$SPEC_FILE" "docs/migrations/ac-bnc-legacy-mapping\\.md" "SPEC Appendix D must point to AC-BNC legacy mapping"
require_pattern "$SPEC_FILE" "module/binance/matrix/TRACEABILITY\\.md" "SPEC Appendix D must name the active TRACEABILITY registry"
require_pattern "$SPEC_FILE" "module/binance/spec/ACCEPTANCE\\.md" "SPEC Appendix D must name the active ACCEPTANCE status source"
for active_file in "$SPEC_FILE" "$TRACEABILITY_FILE" "$ACCEPTANCE_FILE" "$FEATURES_FILE"; do
  forbid_pattern "$active_file" "^\\|[[:space:]]*AC-BNC-[0-9][0-9][0-9][[:space:]]*\\|" "AC-BNC active rows must remain isolated to the legacy mapping"
done

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
