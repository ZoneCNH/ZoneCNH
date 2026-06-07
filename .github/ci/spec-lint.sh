#!/usr/bin/env bash
# spec-lint.sh — 校验所有 specs/*/SPEC.md 的结构完整性
#
# 检查逻辑：
#   1. 23 节检查：每个 spec 必须包含且仅包含 ## 1. 到 ## 23. 的节标题
#   2. WHEN/THEN 覆盖：每个 FR 至少有 1 条 WHEN
#   3. 模糊词检测：grep 模糊词列表，发现则 WARN
#   4. FR 编号连续：FR-001 到 FR-{N} 无跳号
#   5. Non-goals 非空：Section 4 至少有 1 条
#   6. Metadata 必填项：Status / Spec-Version / Last-Updated 符合生命周期规范
#   7. Markdown fence 结束标记必须为裸 ```
#   8. xlib-standard 追溯证据类型与摘要口径一致

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

check_markdown_fences() {
  local md_file="$1"
  local rel_path="${md_file#$REPO_ROOT/}"
  local output

  output=$(
    awk '
      /^```/ {
        if (!inside) {
          inside = 1
          open_line = FNR
        } else {
          if ($0 != "```") {
            printf "%d: closing fence must be bare ``` (found: %s)\n", FNR, $0
          }
          inside = 0
        }
      }
      END {
        if (inside) {
          printf "%d: unclosed fenced block\n", open_line
        }
      }
    ' "$md_file"
  )

  if [[ -n "$output" ]]; then
    echo "  ❌ $rel_path has invalid fenced code block markers:"
    echo "$output" | sed 's/^/     - /'
    FAIL=1
  fi
}

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

  local section_count
  section_count=$(grep -cP "^## \d+\." "$spec_file" || true)
  if [[ "$section_count" -ne 23 ]]; then
    issues+=("❌ top-level numbered section count is $section_count, expected 23")
    FAIL=1
  fi

  local invalid_h2
  invalid_h2=$(grep -nP '^## (?!([1-9]|1[0-9]|2[0-3])\.)' "$spec_file" || true)
  if [[ -n "$invalid_h2" ]]; then
    issues+=("❌ extra or out-of-range H2 sections: $(echo "$invalid_h2" | paste -sd ';' -)")
    FAIL=1
  fi

  local invalid_subsections
  invalid_subsections=$(grep -nP '^#{3,6}\s+(0|2[4-9]|[3-9][0-9]|[1-9][0-9]{2,})\.' "$spec_file" || true)
  if [[ -n "$invalid_subsections" ]]; then
    issues+=("❌ out-of-range numbered subsections: $(echo "$invalid_subsections" | paste -sd ';' -)")
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

  # 10. 防止把静态行数或混合证据误写成行级 100%
  if grep -qP '主规格工件总行数.*(SPEC\s+[0-9]+|[0-9],[0-9]{3})' "$spec_file"; then
    issues+=("❌ static artifact line-count summary found; use a reproducible command instead")
    FAIL=1
  fi

  if grep -qP 'FR 行级覆盖 100%|TRACEABILITY 行级覆盖 100%' "$spec_file"; then
    issues+=("❌ mixed evidence is still reported as 100% line-level coverage")
    FAIL=1
  fi

  # 输出结果
  if [[ ${#issues[@]} -eq 0 ]]; then
    echo "  ✅ $module: ${section_count}/23 sections, ${fr_count} FRs, ${when_count} WHEN clauses"
  else
    for issue in "${issues[@]}"; do
      echo "  $issue ($module)"
    done
    echo "     $module: ${section_count}/23 sections, ${fr_count} FRs, ${when_count} WHEN clauses"
  fi
}

check_xlib_standard_artifacts() {
  local xlib_dir="$SPEC_DIR/xlib-standard"
  [[ -d "$xlib_dir" ]] || return

  local md_name
  for md_name in SPEC.md COVERAGE-MANIFEST.md TRACEABILITY.md README.md REVIEW-VERDICT.md; do
    if [[ -f "$xlib_dir/$md_name" ]]; then
      check_markdown_fences "$xlib_dir/$md_name"
    fi
  done

  local trace_file="$xlib_dir/TRACEABILITY.md"
  if [[ -f "$trace_file" ]]; then
    if ! grep -qP '^\| FR \|.*\| 证据类型 \|' "$trace_file"; then
      echo "  ❌ specs/xlib-standard/TRACEABILITY.md missing 证据类型 column"
      FAIL=1
    fi

    local fr_rows
    fr_rows=$(grep -cP '^\| `FR-[0-9]{3}` ' "$trace_file" || true)
    if [[ "$fr_rows" -ne 52 ]]; then
      echo "  ❌ specs/xlib-standard/TRACEABILITY.md has $fr_rows FR rows, expected 52"
      FAIL=1
    fi

    local bad_types
    bad_types=$(
      awk -F'|' '
        /^\| FR \|/ {
          evidence_idx = 0
          for (i = 1; i <= NF; i++) {
            cell = $i
            gsub(/^[ \t]+|[ \t]+$/, "", cell)
            if (cell == "证据类型") {
              evidence_idx = i
            }
          }
          next
        }
        /^\| `FR-[0-9][0-9][0-9]` / {
          if (!evidence_idx) {
            printf "%d:%s missing evidence type header\n", FNR, $2
            next
          }
          t = $evidence_idx
          gsub(/^[ \t]+|[ \t]+$/, "", t)
          if (t !~ /^(line|file|directory|validator-output|external)$/) {
            printf "%d:%s evidence_type=%s\n", FNR, $2, t
          }
        }
      ' "$trace_file"
    )
    if [[ -n "$bad_types" ]]; then
      echo "  ❌ specs/xlib-standard/TRACEABILITY.md has invalid evidence types:"
      echo "$bad_types" | sed 's/^/     - /'
      FAIL=1
    fi
  fi

  if grep -qP 'FR (行级追溯|行级覆盖).*100%|TRACEABILITY 行级覆盖 100%' \
    "$xlib_dir/SPEC.md" "$xlib_dir/TRACEABILITY.md" "$xlib_dir/README.md" 2>/dev/null; then
    echo "  ❌ xlib-standard still reports mixed evidence as 100% line-level coverage"
    FAIL=1
  fi

  if [[ -f "$xlib_dir/README.md" ]] && grep -q 'Upstream Commit | `未固定`' "$xlib_dir/README.md"; then
    echo "  ❌ specs/xlib-standard/README.md must pin the upstream commit"
    FAIL=1
  fi
}

# 遍历所有 spec
for spec_file in "$SPEC_DIR"/*/SPEC.md; do
  if [[ -f "$spec_file" ]]; then
    check_spec "$spec_file"
  fi
done
check_xlib_standard_artifacts

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
