#!/usr/bin/env bash
# spec-governance-check.sh — 跨制品治理一致性全量校验
#
# 检查维度：
#   1. 制品覆盖：SPEC.md / TRACEABILITY.md / goal.md 三件套是否存在
#   2. §0 Meta：Status / Spec-Version / Module-Version / Layer / Related 字段存在
#   3. 节编号：23 节连续，无跳号
#   4. CONSTITUTION §4.4：WHEN/THEN、Error Handling、Business Rules、AC 段存在
#   5. TRACEABILITY 列：Status 列 / TC ID(s) 列存在性
#   6. Module-Version：对齐 GitHub 最新 release（offline 时跳过）
#
# 用法：
#   bash spec-governance-check.sh           # 全量
#   bash spec-governance-check.sh resiliencx  # 单模块
#   OFFLINE=1 bash spec-governance-check.sh    # 跳过 GitHub API 调用

set -euo pipefail

FAIL=0
WARN=0
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MODULE_DIR="$REPO_ROOT/module"
OFFLINE="${OFFLINE:-0}"

echo "=== Spec Governance Check ==="
echo ""

# ── helpers ──────────────────────────────────────────────────────────────

section_count() {
  # 统计 SPEC.md 中 ## N. 格式的节数
  local spec="$1"
  grep -cP '^## \d+\. ' "$spec" 2>/dev/null || echo 0
}

has_field() {
  # 检查 §0 Meta 中是否存在某个字段
  local spec="$1" field="$2"
  grep -qE "^- $field:" "$spec" 2>/dev/null
}

github_latest_release() {
  local repo="$1"
  gh api "repos/ZoneCNH/$repo/releases/latest" --jq '.tag_name' 2>/dev/null || echo "-"
}

# ── per-module check ─────────────────────────────────────────────────────

check_module() {
  local module="$1"
  local spec="$MODULE_DIR/$module/SPEC.md"
  local trace="$MODULE_DIR/$module/TRACEABILITY.md"
  local goal="$MODULE_DIR/$module/goal.md"
  local errs=()
  local warns=()

  # 1. 制品覆盖 (FAIL)
  [[ -f "$spec" ]]  || { echo "  ❌ $module: missing SPEC.md"; FAIL=1; return; }
  [[ -f "$trace" ]] || { echo "  ❌ $module: missing TRACEABILITY.md"; FAIL=1; return; }
  [[ -f "$goal" ]]  || warns+=("missing goal.md")

  # 2. §0 Meta 字段 (FAIL)
  for field in "Status" "Spec-Version" "Last-Updated" "Layer" "Module-Version" "Related"; do
    has_field "$spec" "$field" || errs+=("§0 missing: $field")
  done

  # 3. 节编号连续性 (FAIL)
  local sec_count
  sec_count=$(section_count "$spec")
  [[ "$sec_count" -ne 23 ]] && errs+=("section count=$sec_count (expected 23)")

  # 4. CONSTITUTION §4.4 (FAIL for core chapters, WARN for AC)
  local when_count
  when_count=$(grep -c 'WHEN' "$spec" 2>/dev/null || echo 0)
  [[ "$when_count" -eq 0 ]] && errs+=("0 WHEN clauses")

  grep -qE '错误处理|Error Handling' "$spec" || errs+=("missing Error Handling")

  grep -qE '行为约束|Business Rules' "$spec" || errs+=("missing Business Rules")

  grep -qE 'AC-|验收条件|Acceptance Criteria' "$spec" || warns+=("missing AC references in SPEC")

  # 5. TRACEABILITY 列 (WARN — 标准化进行中)
  local tc_ok=0
  grep -qE 'Status' "$trace" && grep -qE 'TC ID' "$trace" && tc_ok=1
  [[ $tc_ok -eq 0 ]] && warns+=("TRACEABILITY columns not yet standardized")

  # 6. Module-Version vs GitHub (FAIL, offline 跳过)
  if [[ "$OFFLINE" -eq 0 ]]; then
    local spec_ver gh_ver
    spec_ver=$(grep 'Module-Version:' "$spec" | head -1 | sed 's/.*Module-Version: //')
    gh_ver=$(github_latest_release "$module")
    if [[ "$gh_ver" != "-" && "$spec_ver" != "$gh_ver" ]]; then
      errs+=("Module-Version mismatch: SPEC=$spec_ver GitHub=$gh_ver")
    fi
  fi

  # ── report ──
  if [[ ${#errs[@]} -eq 0 && ${#warns[@]} -eq 0 ]]; then
    echo "  ✅ $module"
  elif [[ ${#errs[@]} -eq 0 ]]; then
    echo "  ⚠️  $module (${#warns[@]} warnings)"
    for w in "${warns[@]}"; do echo "     - $w"; done
    WARN=1
  else
    echo "  ❌ $module (${#errs[@]} errors, ${#warns[@]} warnings)"
    for e in "${errs[@]}"; do echo "     ❌ $e"; done
    for w in "${warns[@]}"; do echo "     ⚠️  $w"; done
    FAIL=1
  fi
}

# ── main ──────────────────────────────────────────────────────────────────

if [[ $# -gt 0 ]]; then
  # 单模块模式
  check_module "$1"
else
  # 全量模式：遍历所有模块
  for spec_file in "$MODULE_DIR"/*/SPEC.md; do
    module="$(basename "$(dirname "$spec_file")")"
    check_module "$module"
  done
fi

# ── summary ───────────────────────────────────────────────────────────────

echo ""
echo "=== 结果 ==="
spec_count=$(find "$MODULE_DIR" -mindepth 2 -maxdepth 2 -name SPEC.md | wc -l)
trace_count=$(find "$MODULE_DIR" -mindepth 2 -maxdepth 2 -name TRACEABILITY.md | wc -l)
goal_count=$(find "$MODULE_DIR" -mindepth 2 -maxdepth 2 -name goal.md | wc -l)
echo "SPEC.md: $spec_count | TRACEABILITY.md: $trace_count | goal.md: $goal_count"

if [[ $FAIL -ne 0 ]]; then
  echo "❌ Spec Governance Check 失败 — 请修复上述错误"
  exit 1
elif [[ $WARN -ne 0 ]]; then
  echo "⚠️  Spec Governance Check 通过（有警告）"
  exit 0
else
  echo "✅ Spec Governance Check 全部通过"
  exit 0
fi
