#!/usr/bin/env bash
# traceability-check.sh — 校验 module/{module}/TRACEABILITY.md 的完整性
#
# 检查逻辑：
#   1. 模块覆盖：必须包含所有 Foundation 模块及已纳入治理的 L2.5 矩阵文件
#   2. FR 覆盖：每个模块的 FR 参考文件在追踪表中都有对应行
#   3. AC 非空：每个 FR 行的 Acceptance Criteria 列不为 "-"
#   4. TC 非空：每个 FR/BR 行的 Test Case 列不为 "-"
#   5. Status 有效：Status 列只能是约定枚举值
#   6. TC 引用：TRACEABILITY.md 中的 TC-### / TC-XXX-### 必须存在于
#      对应 SPEC.md 或 TRACEABILITY.md 的 TC 反向索引；
#      没有当前 SPEC.md 的快照型模块跳过此引用存在性检查
#   7. 交叉验证：TRACEABILITY.md 中的 FR 数量与对应 FR 参考文件一致
#   8. TRACEABILITY_STRICT=1 时警告升级为失败

set -euo pipefail

FAIL=0
WARN=0
STRICT="${TRACEABILITY_STRICT:-0}"
REPO_ROOT="$(git rev-parse --show-toplevel)"
SPEC_DIR="$REPO_ROOT/module"

echo "=== Traceability Check ==="
echo ""

# 模块发现：从 module/*/TRACEABILITY.md 动态收集
REQUIRED_MODULES=$(for d in "$SPEC_DIR"/*/TRACEABILITY.md; do [ -f "$d" ] && basename "$(dirname "$d")"; done | sort -u | xargs)

is_required_module() {
  local candidate="$1"
  local required
  for required in $REQUIRED_MODULES; do
    if [[ "$candidate" == "$required" ]]; then
      return 0
    fi
  done
  return 1
}

tc_grep_pattern() {
  local tc="$1"
  printf '(^|[^A-Z0-9-])%s([^A-Z0-9-]|$)' "$tc"
}

traceability_defines_tc() {
  local trace_file="$1"
  local tc="$2"
  awk -F'|' -v target="$tc" '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function strip_ticks(s) { gsub(/`/, "", s); return s }
    /^\|/ {
      first=strip_ticks(trim($2))
      if (first == target) found=1
    }
    END { exit found ? 0 : 1 }
  ' "$trace_file"
}

check_module() {
  local module="$1"
  local trace_file="$SPEC_DIR/$module/TRACEABILITY.md"
  local spec_file="$SPEC_DIR/$module/SPEC.md"
  local fr_reference_file="$spec_file"
  local tc_reference_file="$spec_file"
  local snapshot_matrix=0

  # xlib-standard 当前在本仓库内是上游分析快照，不以旧 SPEC.md
  # 作为 FR 分母；52 条 FR 的行为明细以 FR-DETAIL.md 为准。
  if [[ "$module" == "xlib-standard" && -f "$SPEC_DIR/xlib-standard/FR-DETAIL.md" ]]; then
    fr_reference_file="$SPEC_DIR/xlib-standard/FR-DETAIL.md"
    tc_reference_file=""
    snapshot_matrix=1
  fi

  if [[ ! -f "$trace_file" ]]; then
    echo "  ❌ $module: missing module/$module/TRACEABILITY.md"
    FAIL=1
    return
  fi

  # 从当前模块的 FR 参考文件提取 FR 数量。
  local spec_fr_count=0
  if [[ -f "$fr_reference_file" ]]; then
    spec_fr_count=$( { grep -oP "FR-\d+" "$fr_reference_file" || true; } | sort -u | wc -l )
  fi

  # 从模块矩阵提取 Requirement 首列为 FR-### 的行数。
  local trace_fr_count
  trace_fr_count=$(awk -F'|' '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function req_id(s) { s=trim(s); gsub(/`/, "", s); return s }
    /^\|/ {
      req=req_id($2)
      ac=trim($4)
      if (req ~ /^FR-[0-9]+$/ && ac != "" && ac != "-") count++
    }
    END { print count+0 }
  ' "$trace_file")

  # FR 数量交叉验证
  if [[ $spec_fr_count -gt 0 && $trace_fr_count -ne $spec_fr_count ]]; then
    echo "  ❌ $module: FR count mismatch — spec=$spec_fr_count, traceability=$trace_fr_count"
    FAIL=1
  fi

  # 快照型矩阵由 spec-lint 对快照结构做专门校验；这里仅校验 FR 覆盖数量。
  if [[ $snapshot_matrix -eq 1 ]]; then
    echo "  ✅ $module: $trace_fr_count/$spec_fr_count FRs traced"
    return
  fi

  # 检查 AC 非空。
  local empty_ac
  empty_ac=$(awk -F'|' '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function req_id(s) { s=trim(s); gsub(/`/, "", s); return s }
    /^\|/ {
      req=req_id($2)
      ac=trim($4)
      if (req ~ /^FR-[0-9]+$/ && (ac == "-" || ac == "")) count++
    }
    END { print count+0 }
  ' "$trace_file")

  if [[ $empty_ac -gt 0 ]]; then
    echo "  ⚠️  $module: $empty_ac FRs with empty AC"
    WARN=1
  fi

  # 检查 TC 非空。TC 空缺暂作为警告，严格模式可升级为失败。
  local empty_tc
  empty_tc=$(awk -F'|' '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function req_id(s) { s=trim(s); gsub(/`/, "", s); return s }
    /^\|/ {
      req=req_id($2)
      tc=trim($5)
      if (req ~ /^(FR|BR)-[0-9]+$/ && (tc == "-" || tc == "")) count++
    }
    END { print count+0 }
  ' "$trace_file")

  if [[ $empty_tc -gt 0 ]]; then
    echo "  ⚠️  $module: $empty_tc requirements with empty TC"
    WARN=1
  fi

  # 检查 TC token 格式。允许 CI Gate/-race/import check 等非 TC 说明，
  # 但凡出现 TC-*，必须是 TC-### 或 TC-XXX-###。
  local invalid_tc_tokens
  invalid_tc_tokens=$(awk -F'|' '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function req_id(s) { s=trim(s); gsub(/`/, "", s); return s }
    /^\|/ {
      req=req_id($2)
      tc=$5
      if (req !~ /^(FR|BR)-[0-9]+$/) next
      gsub(/[；：、]/, " ", tc)
      while (match(tc, /TC-[^, \t|]+/)) {
        token=substr(tc, RSTART, RLENGTH)
        if (token !~ /^TC-([A-Z][A-Z][A-Z][A-Z]*-)?[0-9][0-9][0-9]$/) print token
        tc=substr(tc, RSTART + RLENGTH)
      }
    }
  ' "$trace_file" | sort -u)

  if [[ -n "$invalid_tc_tokens" ]]; then
    echo "  ❌ $module: invalid TC token(s)"
    printf '%s\n' "$invalid_tc_tokens" | sed 's/^/     - /'
    FAIL=1
  fi

  # 检查 TRACEABILITY.md 引用的 TC 是否存在于对应 SPEC.md 或 TC 反向索引。
  # 快照型模块可以没有本地 SPEC.md，因此跳过此引用存在性检查。
  if [[ -n "$tc_reference_file" && -f "$tc_reference_file" ]]; then
    local missing_tc=0
    local referenced_tcs
    referenced_tcs=$(awk -F'|' '
      function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      function req_id(s) { s=trim(s); gsub(/`/, "", s); return s }
      /^\|/ {
        req=req_id($2)
        tc=$5
        if (req !~ /^(FR|BR)-[0-9]+$/) next
        gsub(/[；：、]/, " ", tc)
        while (match(tc, /TC-([A-Z][A-Z][A-Z][A-Z]*-)?[0-9][0-9][0-9]/)) {
          print substr(tc, RSTART, RLENGTH)
          tc=substr(tc, RSTART + RLENGTH)
        }
      }
    ' "$trace_file" | sort -u)

    local tc
    for tc in $referenced_tcs; do
      if ! traceability_defines_tc "$trace_file" "$tc" && ! grep -Eq "$(tc_grep_pattern "$tc")" "$tc_reference_file"; then
        echo "  ❌ $module: $tc referenced in TRACEABILITY.md but missing from SPEC.md or TC registry"
        missing_tc=1
      fi
    done

    if [[ $missing_tc -ne 0 ]]; then
      FAIL=1
    fi
  fi

  # 检查 Status 只使用约定枚举值。Status 取最后一个非空表格字段。
  local invalid_status
  invalid_status=$(awk -F'|' '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function req_id(s) { s=trim(s); gsub(/`/, "", s); return s }
    /^\|/ {
      req=req_id($2)
      if (req !~ /^(FR|BR)-[0-9]+$/) next
      status=""
      for (i=NF; i>=1; i--) {
        field=trim($i)
        if (field != "") { status=field; break }
      }
      if (status != "Pending" &&
          status != "In Progress" &&
          status != "Done" &&
          status != "Failed" &&
          status != "Deferred" &&
          status != "⬜" &&
          status != "🔲" &&
          status != "🔵" &&
          status != "✅" &&
          status != "❌" &&
          status != "⏭️") count++
    }
    END { print count+0 }
  ' "$trace_file")

  if [[ $invalid_status -gt 0 ]]; then
    echo "  ❌ $module: $invalid_status rows with invalid Status"
    FAIL=1
  fi

  echo "  ✅ $module: $trace_fr_count/$spec_fr_count FRs traced"
}

# 检查所有必需模块
for module in $REQUIRED_MODULES; do
  check_module "$module"
done

# 检查模块目录中是否有额外的未知追溯矩阵。
echo ""
echo "--- 额外模块检查 ---"
while IFS= read -r trace_file; do
  module="$(basename "$(dirname "$trace_file")")"
  if ! is_required_module "$module"; then
    echo "  ⚠️  unknown module traceability: module/$module/TRACEABILITY.md"
    WARN=1
  fi
done < <(find "$SPEC_DIR" -mindepth 2 -maxdepth 2 -name TRACEABILITY.md | sort)

echo ""
echo "=== 结果 ==="
if [[ $FAIL -ne 0 ]]; then
  echo "❌ Traceability Check 失败 — 请修复上述错误"
  exit 1
elif [[ $WARN -ne 0 && "$STRICT" == "1" ]]; then
  echo "❌ Traceability Check 失败 — TRACEABILITY_STRICT=1 且存在警告"
  exit 1
elif [[ $WARN -ne 0 ]]; then
  echo "⚠️  Traceability Check 通过（有警告）"
  exit 0
else
  echo "✅ Traceability Check 全部通过"
  exit 0
fi
