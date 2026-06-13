#!/usr/bin/env bash
# spec-status-report.sh — 生成 spec 体系的状态摘要报告
#
# 输出：
#   1. 每个 spec 的 FR/BR 数量和 23 节完整性
#   2. module/*/TRACEABILITY.md 中各状态的行数统计
#   3. Markdown 格式摘要（可用于 PR comment）

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
SPEC_DIR="$REPO_ROOT/module"
TRACE_ROOT="$REPO_ROOT/module"

echo "=== Spec Status Report ==="
echo ""

# ── 1. 模块规格统计 ─────────────────────────────────────

echo "| Module | Sections | FRs | BRs | Status |"
echo "|--------|----------|-----|-----|--------|"

total_fr=0
total_br=0
total_modules=0

for spec_file in "$SPEC_DIR"/*/SPEC.md; do
  if [[ ! -f "$spec_file" ]]; then
    continue
  fi

  module=$(basename "$(dirname "$spec_file")")
  content=$(cat "$spec_file")

  if [[ "$module" == "xlib-standard" && -f "$SPEC_DIR/xlib-standard/ANALYSIS.md" ]]; then
    current_files_ok=1
    for current_file in ANALYSIS.md FR-DETAIL.md TRACEABILITY.md; do
      if [[ ! -f "$SPEC_DIR/xlib-standard/$current_file" ]]; then
        current_files_ok=0
      fi
    done

    if [[ -f "$SPEC_DIR/xlib-standard/FR-DETAIL.md" ]]; then
      fr_count=$(grep -cP "^### FR-[0-9]{3}\\b" "$SPEC_DIR/xlib-standard/FR-DETAIL.md" || true)
    else
      fr_count=0
    fi
    br_count=$(echo "$content" | grep -oP "BR-\d+" | sort -u | wc -l)

    if [[ $current_files_ok -eq 1 ]]; then
      status="✅ snapshot"
    else
      status="❌ snapshot"
    fi

    echo "| $module | snapshot | $fr_count | $br_count | $status |"

    total_fr=$((total_fr + fr_count))
    total_br=$((total_br + br_count))
    total_modules=$((total_modules + 1))
    continue
  fi

  section_count=$(echo "$content" | grep -cP "^## \d+\." || true)
  fr_count=$(echo "$content" | grep -oP "FR-\d+" | sort -u | wc -l)
  br_count=$(echo "$content" | grep -oP "BR-\d+" | sort -u | wc -l)

  if [[ $section_count -eq 23 ]]; then
    status="✅"
  elif [[ $section_count -ge 20 ]]; then
    status="⚠️"
  else
    status="❌"
  fi

  echo "| $module | $section_count/23 | $fr_count | $br_count | $status |"

  total_fr=$((total_fr + fr_count))
  total_br=$((total_br + br_count))
  total_modules=$((total_modules + 1))
done

echo ""
echo "**Total:** $total_modules modules, $total_fr FRs, $total_br BRs"

# ── 2. 追踪矩阵状态统计 ─────────────────────────────────

echo ""
echo "### Traceability Status"
echo ""

count_status() {
  local pattern="$1"
  local count=0
  local matched=0
  local trace_file

  for trace_file in "$TRACE_ROOT"/*/TRACEABILITY.md; do
    [[ -f "$trace_file" ]] || continue
    matched=$(grep -Ec "\\|[[:space:]]*(${pattern})[[:space:]]*\\|" "$trace_file" || true)
    count=$((count + matched))
  done

  echo "$count"
}

trace_file_count=0
for trace_file in "$TRACE_ROOT"/*/TRACEABILITY.md; do
  [[ -f "$trace_file" ]] || continue
  trace_file_count=$((trace_file_count + 1))
done

if [[ $trace_file_count -gt 0 ]]; then
  not_started=$(count_status "Pending|⬜")
  in_progress=$(count_status "In Progress|🔵")
  completed=$(count_status "Done|✅")
  rejected=$(count_status "Failed|❌")
  deferred=$(count_status "Deferred|⏭️")

  total=$((not_started + in_progress + completed + rejected + deferred))

  echo "| Status | Count | Percentage |"
  echo "|--------|-------|------------|"

  if [[ $total -gt 0 ]]; then
    pct_not=$((not_started * 100 / total))
    pct_prog=$((in_progress * 100 / total))
    pct_done=$((completed * 100 / total))
    pct_rej=$((rejected * 100 / total))
    pct_def=$((deferred * 100 / total))
  else
    pct_not=0; pct_prog=0; pct_done=0; pct_rej=0; pct_def=0
  fi

  echo "| ⬜ Not started | $not_started | ${pct_not}% |"
  echo "| 🔵 In progress | $in_progress | ${pct_prog}% |"
  echo "| ✅ Completed | $completed | ${pct_done}% |"
  echo "| ❌ Rejected | $rejected | ${pct_rej}% |"
  echo "| ⏭️ Deferred | $deferred | ${pct_def}% |"
  echo "| **Total** | **$total** | **100%** |"
  echo ""
  echo "**Traceability files:** $trace_file_count"
else
  echo "⚠️  module/*/TRACEABILITY.md not found"
fi

echo ""
echo "=== Report Complete ==="
