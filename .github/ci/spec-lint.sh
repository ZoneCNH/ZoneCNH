#!/usr/bin/env bash
# spec-lint.sh — 校验 module/*/SPEC.md 与特殊分析快照的结构完整性
#
# 检查逻辑：
#   1. 23 节检查：每个 spec 必须按序包含 ## 1. 到 ## 23.，其后允许 ## Appendix A: 附录
#   2. WHEN/THEN 覆盖：每个 FR 至少有 1 条 WHEN
#   3. 模糊词检测：grep 模糊词列表，发现则 WARN
#   4. FR 编号连续：FR-001 到 FR-{N} 无跳号
#   5. Non-goals 非空：Non-goals / 非目标 section 至少有 1 条
#   6. Metadata 必填项：Status / Spec-Version / Last-Updated 符合生命周期规范
#   7. Markdown fence 结束标记必须为裸 ```
#   8. xlib_standard 分析快照使用 ANALYSIS.md / FR-DETAIL.md / TRACEABILITY.md 门禁，
#      不再把归档 SPEC.md 当作当前权威规格入口

set -euo pipefail

FAIL=0
WARN=0
REPO_ROOT="$(git rev-parse --show-toplevel)"
SPEC_DIR="$REPO_ROOT/module"

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

check_numbered_h2_sequence() {
  local md_file="$1"
  local rel_path="${md_file#$REPO_ROOT/}"
  local h2_issues

  h2_issues=$(
    (grep -nP '^## [0-9]+\. ' "$md_file" || true) | awk '
      BEGIN { expected = 1 }
      {
        line_no = $0
        sub(/:.*/, "", line_no)
        line = $0
        sub(/^[0-9]+:/, "", line)
        num = line
        sub(/^## /, "", num)
        sub(/\..*/, "", num)
        if ((num + 0) != expected) {
          printf "%s: expected ## %d. as numbered H2, found: %s\n", line_no, expected, line
        }
        expected++
      }
      END {
        if (expected == 1) {
          printf "EOF: no numbered H2 sections found\n"
        }
      }
    '
  )

  if [[ -n "$h2_issues" ]]; then
    echo "  ❌ $rel_path has invalid numbered H2 sequence:"
    echo "$h2_issues" | sed 's/^/     - /'
    FAIL=1
  fi
}

check_spec() {
  local spec_file="$1"
  local module
  module=$(basename "$(dirname "$spec_file")")
  local issues=()

  # 1. 23 节检查：§1..§23 必须存在且按序；其后允许 Appendix H2
  local section_count
  local h2_issues
  h2_issues=$(
    grep -n '^## ' "$spec_file" | awk '
      BEGIN { expected = 1 }
      {
        line_no = $0
        sub(/:.*/, "", line_no)
        line = $0
        sub(/^[0-9]+:/, "", line)
        if (expected <= 23) {
          pattern = "^## " expected "\\. "
          if (line !~ pattern) {
            printf "%s: expected ## %d. as top-level section %d, found: %s\n", line_no, expected, expected, line
          }
          expected++
        } else if (line !~ /^## Appendix [A-Z]: /) {
          printf "%s: expected Appendix H2 after §23, found: %s\n", line_no, line
        }
      }
      END {
        if (expected <= 23) {
          printf "EOF: missing top-level numbered sections %d..23\n", expected
        }
      }
    '
  )
  section_count=$(grep -cP '^## ([1-9]|1[0-9]|2[0-3])\. ' "$spec_file" || true)
  if [[ -n "$h2_issues" ]]; then
    issues+=("❌ invalid H2 section order: $(echo "$h2_issues" | paste -sd ';' -)")
    FAIL=1
  fi

  local invalid_h2
  invalid_h2=$(grep -nP '^## (2[4-9]|[3-9][0-9]|[1-9][0-9]{2,})\. ' "$spec_file" || true)
  if [[ -n "$invalid_h2" ]]; then
    issues+=("❌ out-of-range numbered H2 sections: $(echo "$invalid_h2" | paste -sd ';' -)")
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

  # 6. Non-goals 非空（按标题识别，避免依赖章节编号）
  local non_goals
  non_goals=$(awk '
    /^## [0-9]+\. / {
      in_section = (tolower($0) ~ /(non-goals|非目标|不做什么)/)
      next
    }
    /^## / {
      in_section = 0
      next
    }
    in_section && /^- / { count++ }
    END { print count + 0 }
  ' "$spec_file")
  if [[ $non_goals -eq 0 ]]; then
    issues+=("⚠️  Non-goals section is empty")
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
  local xlib_dir="$SPEC_DIR/xlib_standard"
  [[ -d "$xlib_dir" ]] || return

  local required_files=(
    README.md
    ANALYSIS.md
    FR-DETAIL.md
    INDEX.md
    TRACEABILITY.md
    CONFLICT-LEDGER.md
    SNAPSHOT-BOUNDARY.md
    COVERAGE-MANIFEST.md
    REMOTE-EVIDENCE.md
    REVIEW-VERDICT.md
    analysis/rules.md
    analysis/template.md
    analysis/runtime.md
    analysis/governance.md
  )

  local rel_file
  local missing=0
  for rel_file in "${required_files[@]}"; do
    if [[ ! -f "$xlib_dir/$rel_file" ]]; then
      echo "  ❌ module/xlib_standard/$rel_file is required for the analysis snapshot"
      FAIL=1
      missing=1
    fi
  done
  [[ "$missing" -eq 0 ]] || return

  for rel_file in "${required_files[@]}"; do
    check_markdown_fences "$xlib_dir/$rel_file"
  done

  if [[ -f "$xlib_dir/SPEC.md" ]]; then
    check_markdown_fences "$xlib_dir/SPEC.md"
  fi

  check_numbered_h2_sequence "$xlib_dir/ANALYSIS.md"

  local snapshot_file
  for snapshot_file in README.md ANALYSIS.md INDEX.md analysis/rules.md analysis/template.md analysis/runtime.md analysis/governance.md; do
    if ! grep -qP '不是.*可执行规格|不.*声明.*可执行规格|不.*作为.*可执行规格' "$xlib_dir/$snapshot_file"; then
      echo "  ❌ module/xlib_standard/$snapshot_file must state that it is not an executable spec"
      FAIL=1
    fi
  done

  if ! grep -qP 'Upstream Commit \| `[0-9a-f]{40}`' "$xlib_dir/README.md"; then
    echo "  ❌ module/xlib_standard/README.md must pin the upstream commit with a full 40-char sha"
    FAIL=1
  fi

  for rel_file in ANALYSIS.md FR-DETAIL.md TRACEABILITY.md; do
    if ! grep -q "$rel_file" "$xlib_dir/README.md"; then
      echo "  ❌ module/xlib_standard/README.md must list $rel_file as a current artifact"
      FAIL=1
    fi
  done

  if [[ -f "$xlib_dir/SPEC.md" ]]; then
    if ! grep -qP 'SPEC\.md.*(旧|归档|历史)' "$xlib_dir/README.md"; then
      echo "  ❌ module/xlib_standard/README.md must classify SPEC.md as legacy/archived"
      FAIL=1
    fi
    if ! grep -qP '归档说明.*不再作为.*可执行规格' "$xlib_dir/SPEC.md"; then
      echo "  ❌ module/xlib_standard/SPEC.md must carry an archived/non-authoritative notice"
      FAIL=1
    fi
  fi

  local fr_detail_file="$xlib_dir/FR-DETAIL.md"
  local fr_detail_count
  local detail_when_count
  local detail_then_count
  fr_detail_count=$(grep -cP '^### FR-[0-9]{3}\b' "$fr_detail_file" || true)
  detail_when_count=$(grep -cP '^WHEN\b' "$fr_detail_file" || true)
  detail_then_count=$(grep -cP '^THEN\b' "$fr_detail_file" || true)

  if [[ "$fr_detail_count" -ne 52 ]]; then
    echo "  ❌ module/xlib_standard/FR-DETAIL.md has $fr_detail_count FR detail blocks, expected 52"
    FAIL=1
  fi
  if [[ "$detail_when_count" -ne 104 ]]; then
    echo "  ❌ module/xlib_standard/FR-DETAIL.md has $detail_when_count WHEN clauses, expected 104"
    FAIL=1
  fi
  if [[ "$detail_then_count" -ne 104 ]]; then
    echo "  ❌ module/xlib_standard/FR-DETAIL.md has $detail_then_count THEN clauses, expected 104"
    FAIL=1
  fi

  local trace_file="$xlib_dir/TRACEABILITY.md"
  if [[ -f "$trace_file" ]]; then
    if ! grep -qP '^\| FR \|.*\| 证据类型 \|' "$trace_file"; then
      echo "  ❌ module/xlib_standard/TRACEABILITY.md missing 证据类型 column"
      FAIL=1
    fi

    local fr_rows
    fr_rows=$(grep -cP '^\| `FR-[0-9]{3}` ' "$trace_file" || true)
    if [[ "$fr_rows" -ne 52 ]]; then
      echo "  ❌ module/xlib_standard/TRACEABILITY.md has $fr_rows FR rows, expected 52"
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
      echo "  ❌ module/xlib_standard/TRACEABILITY.md has invalid evidence types:"
      echo "$bad_types" | sed 's/^/     - /'
      FAIL=1
    fi
  fi

  local trace_ids
  local detail_ids
  local missing_in_detail
  local missing_in_trace
  trace_ids=$(mktemp)
  detail_ids=$(mktemp)
  (grep -oP '^\| `\KFR-[0-9]{3}' "$trace_file" || true) | sort -u >"$trace_ids"
  (grep -oP '^### \KFR-[0-9]{3}' "$fr_detail_file" || true) | sort -u >"$detail_ids"
  missing_in_detail=$(comm -23 "$trace_ids" "$detail_ids" || true)
  missing_in_trace=$(comm -13 "$trace_ids" "$detail_ids" || true)
  rm -f "$trace_ids" "$detail_ids"

  if [[ -n "$missing_in_detail" ]]; then
    echo "  ❌ xlib_standard FRs present in TRACEABILITY.md but missing from FR-DETAIL.md:"
    echo "$missing_in_detail" | sed 's/^/     - /'
    FAIL=1
  fi
  if [[ -n "$missing_in_trace" ]]; then
    echo "  ❌ xlib_standard FRs present in FR-DETAIL.md but missing from TRACEABILITY.md:"
    echo "$missing_in_trace" | sed 's/^/     - /'
    FAIL=1
  fi

  if grep -qP 'FR (行级追溯|行级覆盖).*100%|TRACEABILITY 行级覆盖 100%' \
    "$xlib_dir"/*.md "$xlib_dir"/analysis/*.md 2>/dev/null; then
    echo "  ❌ xlib_standard still reports mixed evidence as 100% line-level coverage"
    FAIL=1
  fi

  if [[ -f "$xlib_dir/README.md" ]] && grep -q 'Upstream Commit | `未固定`' "$xlib_dir/README.md"; then
    echo "  ❌ module/xlib_standard/README.md must pin the upstream commit"
    FAIL=1
  fi

  if [[ $FAIL -eq 0 ]]; then
    echo "  ✅ xlib_standard snapshot: ${fr_detail_count} FR details, ${detail_when_count} WHEN clauses, ${detail_then_count} THEN clauses"
  fi
}

# 遍历所有 spec：只扫描含 SPEC.md 的目录，不把分析快照当作可执行规格
for spec_file in "$SPEC_DIR"/*/SPEC.md; do
  [[ -f "$spec_file" ]] || continue
  if [[ "$(basename "$(dirname "$spec_file")")" == "xlib_standard" && -f "$SPEC_DIR/xlib_standard/ANALYSIS.md" ]]; then
    continue
  fi
  check_spec "$spec_file"
done

check_xlib_standard_artifacts

# === Analysis Lint ===
echo ""
echo "=== Analysis Lint ==="
echo ""

ANALYSIS_FAIL=0

for analysis_dir in "$SPEC_DIR"/*/; do
  [[ -f "$analysis_dir/ANALYSIS.md" ]] || continue

  module=$(basename "$analysis_dir")
  if [[ "$module" == "xlib_standard" ]]; then
    # xlib_standard is a non-executable analysis snapshot with a dedicated gate above.
    continue
  fi
  module_fail=0

  # 必备根级文件
  for required in ANALYSIS.md INDEX.md SNAPSHOT-BOUNDARY.md README.md; do
    if [[ ! -f "$analysis_dir/$required" ]]; then
      echo "  ❌ $module: 缺少必备文件 $required"
      ANALYSIS_FAIL=1
      module_fail=1
    fi
  done

  # ANALYSIS.md 元信息字段
  for field in "Snapshot-Date" "Upstream-Commit" "Analysis-Version"; do
    if ! grep -q "^- $field:" "$analysis_dir/ANALYSIS.md"; then
      echo "  ❌ $module/ANALYSIS.md: 缺少元信息字段 $field"
      ANALYSIS_FAIL=1
      module_fail=1
    fi
  done

  # ANALYSIS.md 章节序（§1..§9 单调递增）
  sections=$(grep -E "^## [0-9]+\. " "$analysis_dir/ANALYSIS.md" | sed -E 's/^## ([0-9]+)\..*/\1/' || true)
  expected=1
  for n in $sections; do
    if [[ "$n" != "$expected" ]]; then
      echo "  ❌ $module/ANALYSIS.md: 章节序错乱（期望 §$expected，实得 §$n）"
      ANALYSIS_FAIL=1
      module_fail=1
      break
    fi
    expected=$((expected + 1))
  done

  # 禁止“本规格”措辞
  if grep -rln "本规格" "$analysis_dir" >/dev/null 2>&1; then
    count=$(grep -rln "本规格" "$analysis_dir" | wc -l)
    echo "  ❌ $module: 仍有 $count 个文件含'本规格'措辞（应使用'本分析'/'上游规格'）"
    ANALYSIS_FAIL=1
    module_fail=1
  fi

  analysis_subdir="${analysis_dir%/}/analysis"

  # 子分析文件 Parent 字段
  if [[ -d "$analysis_subdir" ]]; then
    for sub in "$analysis_subdir/"*.md; do
      [[ -f "$sub" ]] || continue
      if ! grep -q "^- Parent:" "$sub"; then
        echo "  ❌ ${sub#$REPO_ROOT/}: 缺少 Parent 字段"
        ANALYSIS_FAIL=1
        module_fail=1
      fi
    done
  fi

  if [[ "$module_fail" -eq 0 ]]; then
    section_count=$(echo "$sections" | wc -w)
    if [[ -d "$analysis_subdir" ]]; then
      sub_count=$(find "$analysis_subdir" -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l)
    else
      sub_count=0
    fi
    echo "  ✅ $module: ANALYSIS $section_count sections, $sub_count sub-analyses"
  fi
done

if [[ "$ANALYSIS_FAIL" -ne 0 ]]; then
  FAIL=1
fi

echo ""
echo "=== 结果 ==="
if [[ $FAIL -ne 0 ]]; then
  echo "❌ Spec/Analysis Lint 失败 — 请修复上述错误"
  exit 1
elif [[ $WARN -ne 0 ]]; then
  echo "⚠️  Spec/Analysis Lint 通过（有警告）"
  exit 0
else
  echo "✅ Spec/Analysis Lint 全部通过"
  exit 0
fi
