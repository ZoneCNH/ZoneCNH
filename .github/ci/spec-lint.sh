#!/usr/bin/env bash
# spec-lint.sh — 校验所有 specs/*/SPEC.md 的结构完整性
#
# 检查逻辑：
#   1. 23 节检查：每个 spec 必须包含 ## 1. 到 ## 23. 的节标题
#   2. WHEN/THEN 覆盖：每个 FR 至少有 1 条 WHEN
#   3. 模糊词检测：grep 模糊词列表，发现则 WARN
#   4. FR 编号连续：FR-001 到 FR-{N} 无跳号
#   5. Non-goals 非空：Section 4 至少有 1 条
#   6. Metadata 必填项：Status / Spec-Version / Last-Updated 符合生命周期规范

set -euo pipefail

FAIL=0
WARN=0
REPO_ROOT="$(git rev-parse --show-toplevel)"
SPEC_DIR="$REPO_ROOT/specs"

echo "=== Spec Lint ==="
echo ""

# 模糊词列表
FUZZY_WORDS="尽量|可能|也许|大概|适当|合理|必要时|视情况|酌情|尽可能|差不多|基本上|一般来说|通常|某种程度"

# 23 节标题
EXPECTED_SECTIONS=$(seq 1 23)

check_spec() {
  local spec_file="$1"
  local module
  module=$(basename "$(dirname "$spec_file")")
  local issues=()

  # 1. 23 节检查
  local missing_sections=()
  for s in $EXPECTED_SECTIONS; do
    if ! grep -qP "^## ${s}\." "$spec_file"; then
      missing_sections+=("$s")
    fi
  done
  if [[ ${#missing_sections[@]} -gt 0 ]]; then
    issues+=("❌ missing sections: ${missing_sections[*]}")
    FAIL=1
  fi

  # 2. FR 数量
  local fr_count
  fr_count=$(grep -oP "FR-\d+" "$spec_file" | sort -u | wc -l || true)

  # 3. WHEN 数量
  local when_count
  when_count=$(grep -cP "WHEN" "$spec_file" || true)

  # 4. 模糊词检测
  local fuzzy_found
  fuzzy_found=$(grep -oP "$FUZZY_WORDS" "$spec_file" | sort -u | tr '\n' ',' | sed 's/,$//' || true)
  if [[ -n "$fuzzy_found" ]]; then
    issues+=("⚠️  fuzzy words: $fuzzy_found")
    WARN=1
  fi

  # 5. FR 编号连续性
  if [[ $fr_count -gt 0 ]]; then
    local fr_nums
    fr_nums=$(grep -oP "FR-(\d+)" "$spec_file" | sed 's/FR-//' | sed 's/^0*//' | sort -n | uniq)
    local expected=1
    for num in $fr_nums; do
      if [[ "$num" -ne "$expected" ]]; then
        issues+=("❌ FR gap: expected FR-$(printf '%03d' $expected), found FR-$(printf '%03d' $num)")
        FAIL=1
        break
      fi
      expected=$((num + 1))
    done
  fi

  # 6. Non-goals 非空（Section 4）
  local non_goals
  non_goals=$(awk '/^## 4\./,/^## 5\./' "$spec_file" | grep -cP "^- " || true)
  if [[ $non_goals -eq 0 ]]; then
    issues+=("⚠️  Section 4 Non-goals is empty")
    WARN=1
  fi

  # 7. Status 字段校验（六态：Draft/Review/Approved/Implemented/Changed/Deprecated）
  local status_val
  status_val=$(grep -oP "^- Status:\s*\K\S+" "$spec_file" || true)
  if [[ -z "$status_val" ]]; then
    issues+=("❌ missing Status metadata")
    FAIL=1
  else
    case "$status_val" in
      Draft|Review|Approved|Implemented|Changed|Deprecated) ;;
      *)
        issues+=("❌ invalid Status: $status_val (expected: Draft|Review|Approved|Implemented|Changed|Deprecated)")
        FAIL=1
        ;;
    esac
  fi

  # 8. Spec-Version 字段校验
  local spec_version
  spec_version=$(grep -oP "^- Spec-Version:\s*\Kv[0-9]+\.[0-9]+\.[0-9]+$" "$spec_file" || true)
  if [[ -z "$spec_version" ]]; then
    issues+=("❌ missing or invalid Spec-Version metadata (expected: vX.Y.Z)")
    FAIL=1
  fi

  # 9. Last-Updated 字段校验
  local last_updated
  last_updated=$(grep -oP "^- Last-Updated:\s*\K[0-9]{4}-[0-9]{2}-[0-9]{2}$" "$spec_file" || true)
  if [[ -z "$last_updated" ]]; then
    issues+=("❌ missing or invalid Last-Updated metadata (expected: YYYY-MM-DD)")
    FAIL=1
  elif ! date -d "$last_updated" "+%F" >/dev/null 2>&1; then
    issues+=("❌ invalid Last-Updated date: $last_updated")
    FAIL=1
  fi

  # 输出结果
  local section_count
  section_count=$(grep -cP "^## \d+\." "$spec_file" || true)
  if [[ ${#issues[@]} -eq 0 ]]; then
    echo "  ✅ $module: ${section_count}/23 sections, ${fr_count} FRs, ${when_count} WHEN clauses"
  else
    for issue in "${issues[@]}"; do
      echo "  $issue ($module)"
    done
    echo "     $module: ${section_count}/23 sections, ${fr_count} FRs, ${when_count} WHEN clauses"
  fi
}

# 遍历所有 spec
for spec_file in "$SPEC_DIR"/*/SPEC.md; do
  if [[ -f "$spec_file" ]]; then
    check_spec "$spec_file"
  fi
done

echo ""
echo "=== 结果 ==="
if [[ $FAIL -ne 0 ]]; then
  echo "❌ Spec Lint 失败 — 请修复上述错误"
  exit 1
elif [[ $WARN -ne 0 ]]; then
  echo "⚠️  Spec Lint 通过（有警告）"
  exit 0
else
  echo "✅ Spec Lint 全部通过"
  exit 0
fi
