#!/usr/bin/env bash
# four-source-check.sh — 校验 Goal 管线四源评分齐全且无 --force 绕过
#
# 默认扫描 git 已跟踪的 .omc/.omx/.copilot/state/pipeline/*/scores/ 证据。
# 设置 FOUR_SOURCE_INCLUDE_UNTRACKED=1 时，改为扫描本地未跟踪运行态。
# 已通过的阶段必须存在 claude/codex/copilot/rules 四份有效 JSON；
# 失败态/未决态的缺源保留为警告，避免历史运行态片段阻断 CI。
# 同时扫描 verdict.json 确保无 force_override=true 的绕过记录。
#
# 退出码：0=通过，1=发现缺源或绕过
#
# 用法：
#   bash .github/ci/four-source-check.sh [repo-root]
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
FAIL=0
CHECKED=0
MISSING_REPORTS=0
PARTIAL_REPORTS=0
OVERRIDE_REPORTS=0

# Runtime roots that may contain staged pipeline evidence.
RUNTIME_DIRS=(.omc/state/pipeline .omx/state/pipeline .copilot/state/pipeline)

list_scores_dirs() {
  local runtime_dir="$1"
  local pipeline_root="$2"

  if [[ "${FOUR_SOURCE_INCLUDE_UNTRACKED:-0}" != "1" ]] && git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$ROOT" ls-files "$runtime_dir" 2>/dev/null |
      while IFS= read -r tracked; do
        case "$tracked" in
          */scores/*.json) dirname "$ROOT/$tracked" ;;
        esac
      done | sort -u
  else
    find "$pipeline_root" -type d -name scores 2>/dev/null | sort
  fi
}

echo "=== Four-source score check ==="
echo "root: $ROOT"
echo

for runtime_dir in "${RUNTIME_DIRS[@]}"; do
  pipeline_root="$ROOT/$runtime_dir"
  [[ -d "$pipeline_root" ]] || continue
  while IFS= read -r scores_dir; do
    stage_dir="$(dirname "$scores_dir")"
    rel="$(realpath --relative-to="$pipeline_root" "$stage_dir")"
    CHECKED=$((CHECKED + 1))
    present=0
    missing_sources=()
    for src in claude codex copilot rules; do
      f="$scores_dir/$src.json"
      if [[ -f "$f" ]] && python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$f" 2>/dev/null; then
        present=$((present + 1))
      else
        missing_sources+=("$src")
      fi
    done
    verdict="$stage_dir/verdict.json"
    gate=""
    if [[ -f "$verdict" ]]; then
      gate="$(python3 -c "import json,sys; print(str(json.load(open(sys.argv[1])).get('gate', '')).lower())" "$verdict" 2>/dev/null || true)"
    fi
    strict_stage=0
    case "$gate" in
      pass|pass_with_risk|approved|complete|completed)
        strict_stage=1
        ;;
    esac

    if [[ $present -ne 4 ]]; then
      if [[ "$strict_stage" -eq 1 ]]; then
        MISSING_REPORTS=$((MISSING_REPORTS + 1))
        FAIL=1
        printf '  [MISSING] %s/%s: gate=%s present=%d/4 missing=%s\n' "$runtime_dir" "$rel" "$gate" "$present" "${missing_sources[*]}"
      else
        PARTIAL_REPORTS=$((PARTIAL_REPORTS + 1))
        printf '  [PARTIAL] %s/%s: gate=%s present=%d/4 missing=%s\n' "$runtime_dir" "$rel" "${gate:-none}" "$present" "${missing_sources[*]}"
      fi
    fi

    # Check verdict.json for force_override
    if [[ -f "$verdict" ]]; then
      if python3 -c "import json,sys; v=json.load(open(sys.argv[1])); sys.exit(0 if v.get('force_override') else 1)" "$verdict" 2>/dev/null; then
        OVERRIDE_REPORTS=$((OVERRIDE_REPORTS + 1))
        FAIL=1
        printf '  [OVERRIDE] %s/%s: verdict.json has force_override=true\n' "$runtime_dir" "$rel"
      fi
    fi
  done < <(list_scores_dirs "$runtime_dir" "$pipeline_root")
done

echo
echo "=== Summary ==="
echo "  stages checked:        $CHECKED"
echo "  strict missing stages: $MISSING_REPORTS"
echo "  partial/open stages:   $PARTIAL_REPORTS"
echo "  force_override stages: $OVERRIDE_REPORTS"

if [[ "$FAIL" -ne 0 ]]; then
  echo
  echo "FAIL: 已通过阶段四源评分不齐全或存在 force_override 绕过"
  echo "  修复：为通过态阶段补齐 scores/{src}.json，或重跑 arbiter.py（不带 --force）"
  exit 1
fi

echo "PASS: 所有通过态阶段四源齐全且无绕过"
exit 0
