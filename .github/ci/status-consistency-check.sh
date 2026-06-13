#!/usr/bin/env bash
# status-consistency-check.sh — 校验 README / ARCHITECTURE / STATUS / module 数量一致性
#
# 检查逻辑：
#   1. 从 README.md 提取 market-data / macro-data / L2.5 / 分析域 / 决策域 / 横切 组件数量
#   2. 从 ARCHITECTURE.md 提取相同指标
#   3. 从 STATUS.md 提取 domain-level 统计表中的组件数量
#   4. 从 module/ 提取 Foundation 规格数量
#   5. 校验 STATUS 进度分布、版本覆盖与域统计合计
#   6. 比对各方是否一致

set -euo pipefail

FAIL=0
REPO_ROOT="$(git rev-parse --show-toplevel)"
SPEC_DIR="$REPO_ROOT/module"

echo "=== Status Consistency Check ==="
echo ""

# ── 提取工具函数 ─────────────────────────────────────────

# 从 README.md 的 "核心项目" 章节，按二级标题下的列表项计数
count_readme_section() {
  local section_title="$1"
  # 匹配 ### section_title 到下一个 ### 或文件末尾，数列表项
  awk -v sec="$section_title" '
    $0 ~ "^### " sec { found=1; next }
    found && /^### / { found=0 }
    found && /^- \[/ { count++ }
    END { print count+0 }
  ' "$REPO_ROOT/README.md"
}

# 从 ARCHITECTURE.md 状态总览表，按域列匹配
count_arch_domain() {
  local domain="$1"
  local count
  count=$(grep -cP "^\|\s*${domain}\s*\|\s*\[" "$REPO_ROOT/ARCHITECTURE.md" 2>/dev/null || true)
  printf '%s\n' "${count:-0}"
}

# 从 STATUS.md 统计表提取某域的 "总数" 列
count_status_domain() {
  local domain="$1"
  awk -F'|' -v d="$domain" '
    $0 ~ "\\| *\\*\\*" d "\\*\\*" { found=1 }
    found && /^\| \*\*合计/ { next }
    found && /^\|[^|]*\|[^|]*\|/ {
      gsub(/[ \t*\r]/, "", $2)
      if ($2 == d) {
        gsub(/[ \t*\r]/, "", $3)
        print $3
        found=0
      }
    }
  ' "$REPO_ROOT/STATUS.md"
}

# ── 实际组件数统计 ───────────────────────────────────────

# 从 README 架构图提取写死的数量
README_MD_NUM=$(grep -oP 'market-data \(\K[0-9]+' "$REPO_ROOT/README.md" | head -1)
README_MACRO_NUM=$(grep -oP 'macro-data \(\K[0-9]+' "$REPO_ROOT/README.md" | head -1)

# 从 README 列表章节精确计数
README_MARKET=$(count_readme_section "数据域 · market-data")
README_MACRO=$(count_readme_section "数据域 · macro-data")
README_L25=$(count_readme_section "L2.5 · 领域共享层")
README_ANALYSIS=$(count_readme_section "分析域")
README_DECISION=$(count_readme_section "决策域")

# 从 ARCHITECTURE 架构图提取写死的数量
ARCH_MD_NUM=$(grep -oP 'market-data \(\K[0-9]+' "$REPO_ROOT/ARCHITECTURE.md" | head -1)
ARCH_MACRO_NUM=$(grep -oP 'macro-data \(\K[0-9]+' "$REPO_ROOT/ARCHITECTURE.md" | head -1)

# 从 ARCHITECTURE 状态总览表提取域名级计数
ARCH_BASE=$(count_arch_domain "基座")
ARCH_L25=$(count_arch_domain "L2.5")
ARCH_DATA=$(count_arch_domain "数据域")
ARCH_ANALYSIS=$(count_arch_domain "分析域")
ARCH_DECISION=$(count_arch_domain "决策域")
ARCH_EXEC=$(count_arch_domain "执行域")
ARCH_ENTRY=$(count_arch_domain "入口")
ARCH_CROSS=$(count_arch_domain "横切")
ARCH_RUST=$(count_arch_domain "Rust")
ARCH_INDEP=$(count_arch_domain "独立")

# 从 STATUS.md "组件总数" 提取
STATUS_TOTAL=$(grep -oP '组件总数:\s*\K[0-9]+' "$REPO_ROOT/STATUS.md" | head -1)

# 从 STATUS.md "文档同步检查" 表提取（匹配表格行 "| 组件总数"）
STATUS_SYNC_TOTAL=$(awk -F'|' '/^\| 组件总数/{gsub(/[ \t*\r]/, "", $5); match($5, /^[0-9]+/); print substr($5, RSTART, RLENGTH)}' "$REPO_ROOT/STATUS.md")
STATUS_SYNC_MD=$(awk -F'|' '/^\| market-data/{gsub(/[ \t*\r]/, "", $5); match($5, /^[0-9]+/); print substr($5, RSTART, RLENGTH)}' "$REPO_ROOT/STATUS.md")
STATUS_SYNC_MACRO=$(awk -F'|' '/^\| macro-data/{gsub(/[ \t*\r]/, "", $5); match($5, /^[0-9]+/); print substr($5, RSTART, RLENGTH)}' "$REPO_ROOT/STATUS.md")
STATUS_PROGRESS_BUCKET_TOTAL=$(awk '/进度分布:/{found=1; next} found && /^$/{found=0} found { print }' "$REPO_ROOT/STATUS.md" | grep -oP '[0-9]+(?= 个)' | awk '{sum += $1} END { print sum+0 }')
STATUS_VERSIONED=$(grep -oP '版本覆盖:\s*有版本号\s*\K[0-9]+' "$REPO_ROOT/STATUS.md" | head -1)
STATUS_UNVERSIONED=$(grep -oP '版本覆盖:.*无版本号\s*\K[0-9]+' "$REPO_ROOT/STATUS.md" | head -1)
STATUS_DOMAIN_VERSIONED=$(awk -F'|' '/^\| \*\*合计/ {gsub(/[^0-9]/, "", $7); print $7}' "$REPO_ROOT/STATUS.md")

# 从 module/ 提取 Foundation 规格数量；L2.5/domain 规格不计入 Foundation 基座口径。
FOUNDATION_MODULES=(
  xlib-standard
  kernel
  configx
  observex
  testkitx
  resiliencx
  schedulex
  xlibgate
  redisx
  kafkax
  natsx
  postgresx
  taosx
  ossx
  clickhousex
  contracts
  transportx
)
FOUNDATION_EXPECTED_COUNT=${#FOUNDATION_MODULES[@]}
SPEC_COUNT=0
for module in "${FOUNDATION_MODULES[@]}"; do
  if [[ -f "$SPEC_DIR/$module/SPEC.md" ]]; then
    SPEC_COUNT=$((SPEC_COUNT + 1))
  fi
done
FOUNDATION_SPEC_COUNT="$SPEC_COUNT"

echo "--- 数据采集 ---"
echo "README 架构图:     market-data = $README_MD_NUM, macro-data = $README_MACRO_NUM"
echo "README 列表计数:   market-data = $README_MARKET, macro-data = $README_MACRO, L2.5 = $README_L25"
echo "ARCHITECTURE 图:   market-data = $ARCH_MD_NUM, macro-data = $ARCH_MACRO_NUM"
echo "ARCHITECTURE 表:   基座=$ARCH_BASE, L2.5=$ARCH_L25, 数据域=$ARCH_DATA, 分析域=$ARCH_ANALYSIS, 决策域=$ARCH_DECISION, 执行域=$ARCH_EXEC, 入口=$ARCH_ENTRY, 横切=$ARCH_CROSS, Rust=$ARCH_RUST, 独立=$ARCH_INDEP"
echo "STATUS 总数:       $STATUS_TOTAL"
echo "STATUS 同步表:     总计=$STATUS_SYNC_TOTAL, market-data=$STATUS_SYNC_MD, macro-data=$STATUS_SYNC_MACRO"
echo "STATUS 分布/版本:  进度分布合计=$STATUS_PROGRESS_BUCKET_TOTAL, 版本覆盖=$STATUS_VERSIONED+$STATUS_UNVERSIONED, 域统计有版本号=$STATUS_DOMAIN_VERSIONED"
echo "Spec 规格计数:     Foundation=$FOUNDATION_SPEC_COUNT, 预期=$FOUNDATION_EXPECTED_COUNT"
echo ""

# ── 一致性检查 ───────────────────────────────────────────

check() {
  local label="$1"
  local a="$2"
  local b="$3"

  if [[ "$a" == "$b" ]]; then
    echo "  ✅ $label: $a == $b"
  else
    echo "  ❌ $label: $a != $b — 不一致!"
    FAIL=1
  fi
}

echo "--- 一致性比对 ---"
echo ""

# 1. market-data 数量：README 图 == ARCHITECTURE 图 == STATUS 同步表
check "market-data (README 图 vs ARCHITECTURE 图)" "$README_MD_NUM" "$ARCH_MD_NUM"
check "market-data (README 图 vs STATUS 同步表)" "$README_MD_NUM" "$STATUS_SYNC_MD"

# 2. macro-data 数量：README 图 == ARCHITECTURE 图 == STATUS 同步表
check "macro-data (README 图 vs ARCHITECTURE 图)" "$README_MACRO_NUM" "$ARCH_MACRO_NUM"
check "macro-data (README 图 vs STATUS 同步表)" "$README_MACRO_NUM" "$STATUS_SYNC_MACRO"

# 3. README 列表实际条目 vs 图中标注数量
check "market-data (列表条目 vs 图中标注)" "$README_MARKET" "$README_MD_NUM"
check "macro-data (列表条目 vs 图中标注)" "$README_MACRO" "$README_MACRO_NUM"

# 4. ARCHITECTURE 状态表组件行总数 vs STATUS 总数
# module/ 规格数量只统计 Foundation 规格；公开组件总数仍包含入口组合根 x.go。
ARCH_TOTAL=$((ARCH_BASE + ARCH_L25 + ARCH_DATA + ARCH_ANALYSIS + ARCH_DECISION + ARCH_EXEC + ARCH_ENTRY + ARCH_CROSS + ARCH_RUST + ARCH_INDEP))
check "组件总数 (ARCHITECTURE 表合计含入口 vs STATUS)" "$ARCH_TOTAL" "$STATUS_TOTAL"

# 5. STATUS 组件总数行 vs 同步表
check "STATUS (仪表盘总数 vs 同步表总计)" "$STATUS_TOTAL" "$STATUS_SYNC_TOTAL"

# 6. module/ 数量口径：Foundation 17
check "规格总数 (Foundation $FOUNDATION_EXPECTED_COUNT)" "$SPEC_COUNT" "$FOUNDATION_EXPECTED_COUNT"
check "Foundation 规格数" "$FOUNDATION_SPEC_COUNT" "$FOUNDATION_EXPECTED_COUNT"

# 7. STATUS 内部统计应与仪表盘总数一致
check "STATUS (进度分布合计 vs 仪表盘总数)" "$STATUS_PROGRESS_BUCKET_TOTAL" "$STATUS_TOTAL"
VERSION_TOTAL=$((STATUS_VERSIONED + STATUS_UNVERSIONED))
check "STATUS (版本覆盖合计 vs 仪表盘总数)" "$VERSION_TOTAL" "$STATUS_TOTAL"
check "STATUS (版本覆盖 vs 域统计合计)" "$STATUS_VERSIONED" "$STATUS_DOMAIN_VERSIONED"

echo ""

# ── 结果 ─────────────────────────────────────────────────
echo "=== 结果 ==="
if [[ $FAIL -ne 0 ]]; then
  echo "❌ Status Consistency Check 失败 — 请修复上述不一致项"
  echo ""
  echo "修复提示："
  echo "  1. 确保 README.md / ARCHITECTURE.md 中的 market-data (N) / macro-data (N) 数字与实际列表条目一致"
  echo "  2. 确保 STATUS.md 的「组件总数」和「文档同步检查」表中的数字一致"
  echo "  3. 确保 STATUS.md 的进度分布、版本覆盖与域统计合计一致"
  echo "  4. 新增/删除规格时，同步更新 module/README.md 与 Foundation 数量口径"
  echo "  5. 新增/删除组件时，同步更新三个文件中的所有引用"
  exit 1
else
  echo "✅ Status Consistency Check 全部通过"
  exit 0
fi
