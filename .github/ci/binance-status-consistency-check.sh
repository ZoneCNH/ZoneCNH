#!/usr/bin/env bash
# binance-status-consistency-check.sh — 校验 binance 模块状态一致性

set -euo pipefail

FAIL=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BINANCE_DIR="$REPO_ROOT/module/binance"

fail() {
  echo "FAIL: $*"
  FAIL=1
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

for file in README.md spec/FEATURES.md spec/ACCEPTANCE.md matrix/TRACEABILITY.md prompt/README.md; do
  if [ ! -f "$BINANCE_DIR/$file" ]; then
    fail "$file not found"
  fi
done

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
if [ "$FAIL" -ne 0 ]; then
  echo "Result: FAIL"
  exit 1
fi

echo "Result: PASS"
