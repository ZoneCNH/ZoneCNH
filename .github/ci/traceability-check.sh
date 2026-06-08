#!/usr/bin/env bash
# traceability-check.sh — 校验 specs/TRACEABILITY.md 的完整性
#
# 检查逻辑：
#   1. 模块覆盖：必须包含所有 Foundation 模块 + xgo
#   2. FR 覆盖：每个模块的 FR 参考文件在追踪表中都有对应行
#   3. AC 非空：每个 FR 行的 Acceptance Criteria 列不为 "-"
#   4. TC 非空：每个 FR/BR 行的 Test Case 列不为 "-"
#   5. Status 有效：Status 列只能是 ⬜ / 🔵 / ✅ / ❌ / ⏭️
#   6. TC 引用：TRACEABILITY.md 中的 TC-### 必须存在于对应 SPEC.md；
#      没有当前 SPEC.md 的快照型模块跳过此引用存在性检查
#   7. 交叉验证：TRACEABILITY.md 中的 FR 数量与对应 FR 参考文件一致
#   8. TRACEABILITY_STRICT=1 时警告升级为失败

set -euo pipefail

FAIL=0
WARN=0
STRICT="${TRACEABILITY_STRICT:-0}"
REPO_ROOT="$(git rev-parse --show-toplevel)"
TRACE_FILE="$REPO_ROOT/specs/TRACEABILITY.md"
SPEC_DIR="$REPO_ROOT/specs"

echo "=== Traceability Check ==="
echo ""

# 必须包含的模块
REQUIRED_MODULES="kernel configx resiliencx observex schedulex testkitx xlibgate xlib-standard redisx kafkax natsx postgresx taosx ossx clickhousex contracts xgo"

check_module() {
  local module="$1"
  local spec_file="$SPEC_DIR/$module/SPEC.md"
  local fr_reference_file="$spec_file"
  local tc_reference_file="$spec_file"

  # xlib-standard 当前在本仓库内是上游分析快照，不再以旧 SPEC.md
  # 作为 FR 分母；52 条 FR 的行为明细以 FR-DETAIL.md 为准。
  if [[ "$module" == "xlib-standard" && -f "$SPEC_DIR/xlib-standard/FR-DETAIL.md" ]]; then
    fr_reference_file="$SPEC_DIR/xlib-standard/FR-DETAIL.md"
    tc_reference_file=""
  fi

  # 检查追踪表中是否有该模块的 section
  if ! grep -qP "^## ${module}$" "$TRACE_FILE" && ! grep -qP "^## ${module}\b" "$TRACE_FILE"; then
    echo "  ❌ $module: missing from TRACEABILITY.md"
    FAIL=1
    return
  fi

  # 从当前模块的 FR 参考文件提取 FR 数量。
  local spec_fr_count=0
  if [[ -f "$fr_reference_file" ]]; then
    spec_fr_count=$(grep -oP "FR-\d+" "$fr_reference_file" | sort -u | wc -l)
  fi

  # 从追踪表提取该模块的 FR 行数
  local trace_fr_count
  trace_fr_count=$(awk -v m="$module" '
    $0 ~ "^## " m "$" { found=1; next }
    found && /^## / { found=0 }
    found && /\| FR-/ { count++ }
    END { print count+0 }
  ' "$TRACE_FILE")

  # FR 数量交叉验证
  if [[ $spec_fr_count -gt 0 && $trace_fr_count -ne $spec_fr_count ]]; then
    echo "  ❌ $module: FR count mismatch — spec=$spec_fr_count, traceability=$trace_fr_count"
    FAIL=1
  fi

  # 检查 AC 非空（匹配 AC 列为 "-" 的行，跳过 TC 列的 "-"）
  local empty_ac
  empty_ac=$(awk -v m="$module" '
    $0 ~ "^## " m "$" { found=1; next }
    found && /^## / { found=0 }
    found && /\| FR-/ && /\| FR-[^|]*\|[^|]*\| - \|/ { count++ }
    END { print count+0 }
  ' "$TRACE_FILE")

  if [[ $empty_ac -gt 0 ]]; then
    echo "  ⚠️  $module: $empty_ac FRs with empty AC"
    WARN=1
  fi

  # 检查 TC 非空。TC 空缺暂作为警告，严格模式可升级为失败。
  local empty_tc
  empty_tc=$(awk -F'|' -v m="$module" '
    $0 ~ "^## " m "$" { found=1; next }
    found && /^## / { found=0 }
    found && /\| (FR|BR)-/ {
      tc=$5
      gsub(/^[ \t]+|[ \t]+$/, "", tc)
      if (tc == "-" || tc == "") count++
    }
    END { print count+0 }
  ' "$TRACE_FILE")

  if [[ $empty_tc -gt 0 ]]; then
    echo "  ⚠️  $module: $empty_tc requirements with empty TC"
    WARN=1
  fi

  # 检查 TC token 格式。允许 CI Gate/-race/import check 等非 TC 说明，
  # 但凡出现 TC-*，必须是 TC-###。
  local invalid_tc_tokens
  invalid_tc_tokens=$(awk -F'|' -v m="$module" '
    $0 ~ "^## " m "$" { found=1; next }
    found && /^## / { found=0 }
    found && /\| (FR|BR)-/ {
      tc=$5
      while (match(tc, /TC-[^, \t|]+/)) {
        token=substr(tc, RSTART, RLENGTH)
        if (token !~ /^TC-[0-9][0-9][0-9]$/) print token
        tc=substr(tc, RSTART + RLENGTH)
      }
    }
  ' "$TRACE_FILE" | sort -u)

  if [[ -n "$invalid_tc_tokens" ]]; then
    echo "  ❌ $module: invalid TC token(s)"
    printf '%s\n' "$invalid_tc_tokens" | sed 's/^/     - /'
    FAIL=1
  fi

  # 检查 TRACEABILITY.md 引用的 TC 是否存在于对应 SPEC.md。
  # 快照型模块可以没有本地 SPEC.md，因此跳过此引用存在性检查。
  if [[ -n "$tc_reference_file" && -f "$tc_reference_file" ]]; then
    local missing_tc=0
    local referenced_tcs
    referenced_tcs=$(awk -F'|' -v m="$module" '
      $0 ~ "^## " m "$" { found=1; next }
      found && /^## / { found=0 }
      found && /\| (FR|BR)-/ {
        tc=$5
        while (match(tc, /TC-[0-9][0-9][0-9]/)) {
          print substr(tc, RSTART, RLENGTH)
          tc=substr(tc, RSTART + RLENGTH)
        }
      }
    ' "$TRACE_FILE" | sort -u)

    for tc in $referenced_tcs; do
      if ! grep -q "\\*\\*$tc:" "$tc_reference_file"; then
        echo "  ❌ $module: $tc referenced in TRACEABILITY.md but missing from SPEC.md"
        missing_tc=1
      fi
    done

    if [[ $missing_tc -ne 0 ]]; then
      FAIL=1
    fi
  fi

  # 检查 Status 只使用约定枚举值。
  local invalid_status
  invalid_status=$(awk -F'|' -v m="$module" '
    $0 ~ "^## " m "$" { found=1; next }
    found && /^## / { found=0 }
    found && /\| (FR|BR)-/ {
      status=$6
      gsub(/^[ \t]+|[ \t]+$/, "", status)
      if (status != "⬜" && status != "🔵" && status != "✅" && status != "❌" && status != "⏭️") count++
    }
    END { print count+0 }
  ' "$TRACE_FILE")

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

# 检查追踪表中是否有额外的未知模块
echo ""
echo "--- 额外模块检查 ---"
trace_modules=$(grep -oP "^## \K[a-z0-9.-]+" "$TRACE_FILE" | sort -u)
for tm in $trace_modules; do
  found=0
  for rm in $REQUIRED_MODULES; do
    if [[ "$tm" == "$rm" ]]; then
      found=1
      break
    fi
  done
  if [[ $found -eq 0 ]]; then
    echo "  ⚠️  unknown module in traceability: $tm"
    WARN=1
  fi
done

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
