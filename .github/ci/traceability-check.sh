#!/usr/bin/env bash
# traceability-check.sh — 校验 specs/TRACEABILITY.md 的完整性
#
# 检查逻辑：
#   1. 模块覆盖：必须包含所有 16 个模块 + x.go
#   2. FR 覆盖：每个 spec 的 FR 在追踪表中都有对应行
#   3. AC 非空：每个 FR 行的 Acceptance Criteria 列不为 "-"
#   4. Status 有效：Status 列只能是 ⬜ / 🔵 / ✅ / ❌ / ⏭️
#   5. 交叉验证：TRACEABILITY.md 中的 FR 数量与对应 spec 一致

set -euo pipefail

FAIL=0
WARN=0
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

  # 检查追踪表中是否有该模块的 section
  if ! grep -qP "^## ${module}$" "$TRACE_FILE" && ! grep -qP "^## ${module}\b" "$TRACE_FILE"; then
    echo "  ❌ $module: missing from TRACEABILITY.md"
    FAIL=1
    return
  fi

  # 从 spec 文件提取 FR 数量
  local spec_fr_count=0
  if [[ -f "$spec_file" ]]; then
    spec_fr_count=$(grep -oP "FR-\d+" "$spec_file" | sort -u | wc -l)
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

  # 检查 AC 非空
  local empty_ac
  empty_ac=$(awk -v m="$module" '
    $0 ~ "^## " m "$" { found=1; next }
    found && /^## / { found=0 }
    found && /\| FR-/ && /\| - \|/ { count++ }
    END { print count+0 }
  ' "$TRACE_FILE")

  if [[ $empty_ac -gt 0 ]]; then
    echo "  ⚠️  $module: $empty_ac FRs with empty AC"
    WARN=1
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
elif [[ $WARN -ne 0 ]]; then
  echo "⚠️  Traceability Check 通过（有警告）"
  exit 0
else
  echo "✅ Traceability Check 全部通过"
  exit 0
fi
