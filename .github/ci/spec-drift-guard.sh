#!/usr/bin/env bash
# spec-drift-guard.sh — 检测 SPEC.md 的标题、Status、disclaimer 被外部篡改
#
# 已知篡改模式：
#   1. 标题被改为 "历史规格草案"、"历史整理工件" 等
#   2. Status 被改为 "Superseded"、"历史" 等非法值
#   3. 注入 disclaimer 段落（"本文件只作为历史"、"非当前主规格"）
#
# 此脚本在 spec-lint 之后运行，专门拦截这些漂移。

set -euo pipefail

FAIL=0
REPO_ROOT="$(git rev-parse --show-toplevel)"
SPEC_DIR="$REPO_ROOT/module"

echo "=== Spec Drift Guard ==="
echo ""

check_drift() {
  local spec_file="$1"
  local module
  module=$(basename "$(dirname "$spec_file")")
  local issues=()

  local first_line
  first_line=$(head -1 "$spec_file")

  # 1. 标题篡改检测
  if echo "$first_line" | grep -qiP '历史|草案|整理工件|非当前|deprecated'; then
    issues+=("❌ title drift: $first_line")
    FAIL=1
  fi

  # 2. Status 篡改检测
  local status_val
  status_val=$(grep -oP "^- Status:\s*\K.*" "$spec_file" || true)
  if echo "$status_val" | grep -qiP 'superseded|历史|非当前|historical|obsolete|draft.*非'; then
    issues+=("❌ status drift: $status_val")
    FAIL=1
  fi

  # 3. Disclaimer 注入检测（前 10 行内的块引用）
  local disclaimer
  disclaimer=$(head -10 "$spec_file" | grep -P '^>.*历史|^>.*非当前|^>.*只作为|^>.*保留.*追溯|^>.*历史工件' || true)
  if [[ -n "$disclaimer" ]]; then
    issues+=("❌ disclaimer injected: ${disclaimer:0:80}")
    FAIL=1
  fi

  # 4. Status 行后的额外 disclaimer 段落（metadata 和 --- 之间）
  local extra_disclaimer
  extra_disclaimer=$(sed -n '/^- Status:/,/^---/p' "$spec_file" | grep -P '历史|非当前|只作为|superseded' || true)
  if [[ -n "$extra_disclaimer" ]]; then
    issues+=("❌ metadata-section disclaimer: ${extra_disclaimer:0:80}")
    FAIL=1
  fi

  if [[ ${#issues[@]} -eq 0 ]]; then
    echo "  ✅ $module: no drift detected"
  else
    for issue in "${issues[@]}"; do
      echo "  $issue ($module)"
    done
  fi
}

for spec_file in "$SPEC_DIR"/*/SPEC.md; do
  if [[ -f "$spec_file" ]]; then
    module="$(basename "$(dirname "$spec_file")")"
    if [[ "$module" == "xlib-standard" && -f "$SPEC_DIR/xlib-standard/ANALYSIS.md" ]]; then
      echo "  ✅ xlib-standard: analysis snapshot uses dedicated lint gate"
      continue
    fi
    check_drift "$spec_file"
  fi
done

echo ""
echo "=== 结果 ==="
if [[ $FAIL -ne 0 ]]; then
  echo "❌ Spec Drift Guard 失败 — 检测到 SPEC.md 被篡改，请恢复后重试"
  exit 1
else
  echo "✅ Spec Drift Guard 全部通过"
  exit 0
fi
