#!/usr/bin/env bash
# status-consistency-check.sh — 校验 README / ARCHITECTURE / STATUS 三文件组件数量一致性
#
# 检查逻辑：
#   1. 从 README.md 提取 market-data / macro-data / L2.5 / 分析域 / 决策域 / 横切 组件数量
#   2. 从 ARCHITECTURE.md 提取相同指标
#   3. 从 STATUS.md 提取 domain-level 统计表中的组件数量
#   4. 比对三方是否一致

set -euo pipefail

FAIL=0
REPO_ROOT="$(git rev-parse --show-toplevel)"

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
  grep -cP "^\| ${domain} \| \[" "$REPO_ROOT/ARCHITECTURE.md" 2>/dev/null || echo "0"
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
STATUS_SYNC_TOTAL=$(awk -F'|' '/^\| 组件总数/{gsub(/[ \t*\r]/, "", $4); match($4, /^[0-9]+/); print substr($4, RSTART, RLENGTH)}' "$REPO_ROOT/STATUS.md")
STATUS_SYNC_MD=$(awk -F'|' '/^\| market-data/{gsub(/[ \t*\r]/, "", $4); match($4, /^[0-9]+/); print substr($4, RSTART, RLENGTH)}' "$REPO_ROOT/STATUS.md")
STATUS_SYNC_MACRO=$(awk -F'|' '/^\| macro-data/{gsub(/[ \t*\r]/, "", $4); match($4, /^[0-9]+/); print substr($4, RSTART, RLENGTH)}' "$REPO_ROOT/STATUS.md")

echo "--- 数据采集 ---"
echo "README 架构图:     market-data = $README_MD_NUM, macro-data = $README_MACRO_NUM"
echo "README 列表计数:   market-data = $README_MARKET, macro-data = $README_MACRO, L2.5 = $README_L25"
echo "ARCHITECTURE 图:   market-data = $ARCH_MD_NUM, macro-data = $ARCH_MACRO_NUM"
echo "ARCHITECTURE 表:   基座=$ARCH_BASE, L2.5=$ARCH_L25, 数据域=$ARCH_DATA, 分析域=$ARCH_ANALYSIS, 决策域=$ARCH_DECISION, 执行域=$ARCH_EXEC, 入口=$ARCH_ENTRY, 横切=$ARCH_CROSS, Rust=$ARCH_RUST, 独立=$ARCH_INDEP"
echo "STATUS 总数:       $STATUS_TOTAL"
echo "STATUS 同步表:     总计=$STATUS_SYNC_TOTAL, market-data=$STATUS_SYNC_MD, macro-data=$STATUS_SYNC_MACRO"
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
ARCH_TOTAL=$((ARCH_BASE + ARCH_L25 + ARCH_DATA + ARCH_ANALYSIS + ARCH_DECISION + ARCH_EXEC + ARCH_ENTRY + ARCH_CROSS + ARCH_RUST + ARCH_INDEP))
check "组件总数 (ARCHITECTURE 表合计 vs STATUS)" "$ARCH_TOTAL" "$STATUS_TOTAL"

# 5. STATUS 组件总数行 vs 同步表
check "STATUS (仪表盘总数 vs 同步表总计)" "$STATUS_TOTAL" "$STATUS_SYNC_TOTAL"

echo ""

# ── 结果 ─────────────────────────────────────────────────
echo "=== 结果 ==="
if [[ $FAIL -ne 0 ]]; then
  echo "❌ Status Consistency Check 失败 — 请修复上述不一致项"
  echo ""
  echo "修复提示："
  echo "  1. 确保 README.md / ARCHITECTURE.md 中的 market-data (N) / macro-data (N) 数字与实际列表条目一致"
  echo "  2. 确保 STATUS.md 的「组件总数」和「文档同步检查」表中的数字一致"
  echo "  3. 新增/删除组件时，同步更新三个文件中的所有引用"
  exit 1
else
  echo "✅ Status Consistency Check 全部通过"
  exit 0
fi
