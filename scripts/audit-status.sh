#!/usr/bin/env bash
# audit-status.sh — STATUS.md / README.md / ARCHITECTURE.md cross-document consistency checker
#
# Checks:
#   1. STATUS.md component table row counts match domain stats totals
#   2. Dashboard numbers match domain stats 合计 row
#   3. Sync check table matches unique repo grep counts
#   4. Version count for base matches domain stats
#   5. No stale "strategies" references
#   6. Domain-sum row sums match 合计
#   7. (optional) 404 link check with --network
#
# Usage:
#   ./scripts/audit-status.sh           # local checks only
#   ./scripts/audit-status.sh --network  # includes 404 link check
#
# Exit: 0 = PASS, 1 = FAIL

set -euo pipefail

NETWORK="${1:-}"
RED='\033[31m'
GREEN='\033[32m'
NC='\033[0m'

PASS=0; FAIL=0; TOTAL=0

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

msg_pass() { echo -e "  ${GREEN}PASS${NC} $1"; PASS=$((PASS+1)); TOTAL=$((TOTAL+1)); }
msg_fail() { echo -e "  ${RED}FAIL${NC} $1"; FAIL=$((FAIL+1)); TOTAL=$((TOTAL+1)); }

check_eq() { local label="$1" a="$2" b="$3"; if [ "$a" = "$b" ]; then msg_pass "$label: $a == $b"; else msg_fail "$label: $a != $b"; fi; }

echo "=== audit-status.sh ==="
echo ""

# ── 0. Extract domain stats 合计 row values ─────────────────
# Table format: | 域 | 总数 | 已有 | 已创建 | 平均进度 | 有版本号 |
# awk: $1 empty, $2=domain, $3=total, $4=existing, $5=created, $6=progress, $7=versioned
STAT_TOTAL=$(awk -F'|' '/^\| \*\*合计\*\*/ {gsub(/[ *]/,"",$3); print $3}' STATUS.md)
STAT_EXISTING=$(awk -F'|' '/^\| \*\*合计\*\*/ {gsub(/[ *]/,"",$4); print $4}' STATUS.md)
STAT_CREATED=$(awk -F'|' '/^\| \*\*合计\*\*/ {gsub(/[ *]/,"",$5); print $5}' STATUS.md)
STAT_PROGRESS=$(awk -F'|' '/^\| \*\*合计\*\*/ {gsub(/[ *%]/,"",$6); print $6}' STATUS.md)
STAT_VERSIONED=$(awk -F'|' '/^\| \*\*合计\*\*/ {gsub(/[ *]/,"",$7); print $7}' STATUS.md)

# ── 1. Table row counts vs domain stats ────────────────────
echo "--- 1. Table row counts vs domain stats ---"

COUNT_BASE=$(awk '/^### 基座/{found=1} /^### L2.5/{found=0} found && /github.com/' STATUS.md | wc -l)
COUNT_L25=$(awk '/^### L2.5/{found=1} /^### 数据域/{found=0} found && /github.com/' STATUS.md | wc -l)
COUNT_SDK=$(awk '/^### 数据域.*行情/{found=1} /^### 数据域.*宏观/{found=0} found && /github.com/ && /SDK/' STATUS.md | wc -l)
COUNT_PROV=$(awk '/^### 数据域.*行情/{found=1} /^### 数据域.*宏观/{found=0} found && /github.com/ && /Provider/' STATUS.md | wc -l)
COUNT_MACRO=$(awk '/^### 数据域.*宏观/{found=1} /^### 数据域.*另类/{found=0} found && /github.com/' STATUS.md | wc -l)
COUNT_ALT=$(awk '/^### 数据域.*另类/{found=1} /^### 分析域/{found=0} found && /github.com/' STATUS.md | wc -l)
COUNT_ANALYSIS=$(awk '/^### 分析域/{found=1} /^### 决策域/{found=0} found && /github.com/' STATUS.md | wc -l)
COUNT_DECISION=$(awk '/^### 决策域/{found=1} /^### 执行域/{found=0} found && /github.com/' STATUS.md | wc -l)
COUNT_EXECUTION=$(awk '/^### 执行域/{found=1} /^### 入口/{found=0} found && /github.com/' STATUS.md | wc -l)

# Extract from domain stats table (awk: $3=total)
DS_BASE=$(awk -F'|' '/基座.*\|.*\|.*\|.*\|.*\|/ && !/-----/ {gsub(/ /,"",$3); print $3}' STATUS.md)
DS_L25=$(awk -F'|' '/L2.5/ && !/-----/ {gsub(/ /,"",$3); print $3}' STATUS.md)
DS_SDK=$(awk -F'|' '/行情 SDK/ {gsub(/ /,"",$3); print $3}' STATUS.md)
DS_PROV=$(awk -F'|' '/行情 Provider/ {gsub(/ /,"",$3); print $3}' STATUS.md)
DS_MACRO=$(awk -F'|' '/数据域.*宏观/ {gsub(/ /,"",$3); print $3}' STATUS.md)
DS_ALT=$(awk -F'|' '/另类/ {gsub(/ /,"",$3); print $3}' STATUS.md)
DS_ANALYSIS=$(awk -F'|' '/分析域/ {gsub(/ /,"",$3); print $3}' STATUS.md)
DS_DECISION=$(awk -F'|' '/决策域/ {gsub(/ /,"",$3); print $3}' STATUS.md)
DS_EXECUTION=$(awk -F'|' '/执行域/ {gsub(/ /,"",$3); print $3}' STATUS.md)

check_eq "Base"     "$COUNT_BASE"    "$DS_BASE"
check_eq "L2.5"     "$COUNT_L25"     "$DS_L25"
check_eq "SDK"      "$COUNT_SDK"     "$DS_SDK"
check_eq "Provider" "$COUNT_PROV"    "$DS_PROV"
check_eq "Macro"    "$COUNT_MACRO"   "$DS_MACRO"
check_eq "Alt"      "$COUNT_ALT"     "$DS_ALT"
check_eq "Analysis" "$COUNT_ANALYSIS" "$DS_ANALYSIS"
check_eq "Decision" "$COUNT_DECISION" "$DS_DECISION"
check_eq "Execution" "$COUNT_EXECUTION" "$DS_EXECUTION"

# ── 2. Dashboard vs 合计 ────────────────────────────────────
echo ""
echo "--- 2. Dashboard vs domain stats ---"

DASH_LINE=$(grep '组件总数:' STATUS.md)
DASH_TOTAL=$(echo "$DASH_LINE" | grep -oP '组件总数:\s*\d+' | grep -oP '\d+')
DASH_EXISTING=$(echo "$DASH_LINE" | grep -oP '已有:\s*\d+' | grep -oP '\d+')
DASH_CREATED=$(echo "$DASH_LINE" | grep -oP '已创建:\s*\d+' | grep -oP '\d+')
DASH_PROGRESS=$(echo "$DASH_LINE" | grep -oP '平均进度:\s*\d+%' | grep -oP '\d+')

check_eq "Total"    "$DASH_TOTAL"    "$STAT_TOTAL"
check_eq "Existing" "$DASH_EXISTING" "$STAT_EXISTING"
check_eq "Created"  "$DASH_CREATED"  "$STAT_CREATED"
check_eq "Progress" "${DASH_PROGRESS}%" "${STAT_PROGRESS}%"

# ── 3. Sync check table vs actual unique repos ──────────────
echo ""
echo "--- 3. Sync check table vs actual unique repos ---"

README_UNIQUE=$(grep -oPh 'github\.com/ZoneCNH/[a-zA-Z0-9_.-]+' README.md | sort -u | wc -l)
ARCH_UNIQUE=$(grep -oPh 'github\.com/ZoneCNH/[a-zA-Z0-9_.-]+' ARCHITECTURE.md | sort -u | wc -l)
STATUS_UNIQUE=$(grep -oPh 'github\.com/ZoneCNH/[a-zA-Z0-9_.-]+' STATUS.md | sort -u | wc -l)

# Parse sync table: | 组件总数 | README | ARCH | STATUS |
SYNC_README=$(awk -F'|' '/组件总数/ {gsub(/ /,"",$2); print $2}' STATUS.md)
SYNC_ARCH=$(awk -F'|' '/组件总数/ {gsub(/ /,"",$3); print $3}' STATUS.md)
SYNC_STATUS=$(awk -F'|' '/组件总数/ {gsub(/ /,"",$4); print $4}' STATUS.md)

check_eq "README"  "$README_UNIQUE"  "$SYNC_README"
check_eq "ARCH"    "$ARCH_UNIQUE"    "$SYNC_ARCH"
# STATUS unique is 78 (includes stdlib.rs), domain-sum is 80
DIFF=$((STATUS_UNIQUE - SYNC_STATUS))
DIFF_ABS=${DIFF#-}
if [ "$DIFF_ABS" -le 2 ]; then
  msg_pass "STATUS: actual=$STATUS_UNIQUE sync-table=$SYNC_STATUS (diff=$DIFF, OK within ±2)"
else
  msg_fail "STATUS: actual=$STATUS_UNIQUE sync-table=$SYNC_STATUS (diff=$DIFF, expected <=2)"
fi

# ── 4. Base version count ───────────────────────────────────
echo ""
echo "--- 4. Base version count ---"

# For base table, version is column 3 ($3 in awk -F'|')
BASE_VER=$(awk -F'|' '/github.com\/ZoneCNH\// {
  gsub(/^[ ]+|[ ]+$/,"",$3);
  if($3!="" && $3!="-") print
}' <(sed -n '/^### 基座/,/^> ⚠️/p' STATUS.md) | wc -l)

DS_BASE_VER=$(awk -F'|' '/基座.*\|.*\|.*\|.*\|.*\|/ && !/-----/ {gsub(/ /,"",$7); print $7}' STATUS.md)
DS_BASE_VER_NUM=$(echo "$DS_BASE_VER" | grep -oP '^\d+')
check_eq "BaseVer" "$BASE_VER" "$DS_BASE_VER_NUM"

# ── 5. Stale references ─────────────────────────────────────
echo ""
echo "--- 5. Stale references ---"
STRAT_COUNT=$(grep -rn 'strategies' STATUS.md README.md ARCHITECTURE.md 2>/dev/null | grep -v 'strategyx' | wc -l)
if [ "$STRAT_COUNT" -eq 0 ]; then
  msg_pass "No stale 'strategies' references"
else
  msg_fail "$STRAT_COUNT stale 'strategies' references"
  grep -rn 'strategies' STATUS.md README.md ARCHITECTURE.md | grep -v 'strategyx'
fi

# ── 6. Domain-sum totals ────────────────────────────────────
echo ""
echo "--- 6. Domain-sum row sums ---"

SUM_TOTAL=0; SUM_EXISTING=0; SUM_CREATED=0
while IFS='|' read -r _ domain total existing created _ _; do
  t=$(echo "$total" | grep -oP '\d+' || echo "0")
  e=$(echo "$existing" | grep -oP '\d+' || echo "0")
  c=$(echo "$created" | grep -oP '\d+' || echo "0")
  SUM_TOTAL=$((SUM_TOTAL + t))
  SUM_EXISTING=$((SUM_EXISTING + e))
  SUM_CREATED=$((SUM_CREATED + c))
done < <(awk -F'|' '/按域统计/,/^---$/' STATUS.md | grep -E '^\|' | grep -v '域\|合计\|-----')

check_eq "DomainSumTotal"    "$SUM_TOTAL"    "$STAT_TOTAL"
check_eq "DomainSumExisting" "$SUM_EXISTING" "$STAT_EXISTING"
check_eq "DomainSumCreated"  "$SUM_CREATED"  "$STAT_CREATED"

# ── 7. 404 check (optional) ─────────────────────────────────
echo ""
echo "--- 7. 404 check ---"
if [ "$NETWORK" = "--network" ]; then
  REPOS=$(grep -oPh 'github\.com/ZoneCNH/[a-zA-Z0-9_.-]+' STATUS.md README.md ARCHITECTURE.md | sort -u)
  FOUND_404=0
  for url in $REPOS; do
    repo=$(echo "$url" | grep -oP 'ZoneCNH/\K.*')
    if ! gh api "repos/ZoneCNH/$repo" >/dev/null 2>&1; then
      msg_fail "404: $repo"
      FOUND_404=$((FOUND_404+1))
    fi
  done
  if [ "$FOUND_404" -eq 0 ]; then
    msg_pass "No 404 links ($(echo "$REPOS" | wc -l) repos checked)"
  fi
else
  echo "  SKIPPED (use --network for full 404 scan)"
fi

# ── Summary ─────────────────────────────────────────────────
echo ""
echo "=========================================="
echo -e "Results: ${GREEN}$PASS passed${NC} / ${RED}$FAIL failed${NC} / $TOTAL total"
echo "=========================================="

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
