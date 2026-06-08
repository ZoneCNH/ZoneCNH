#!/usr/bin/env bash
# outer-metrics-from-git.sh
#
# 从 git 历史机械计算真实质量指标，写入当前运行时 state_root/outer-metrics/{module}.json
# 严禁由 LLM agent 调用；由 cron / CI 触发。
#
# 用法：scripts/outer-metrics-from-git.sh <module> [<since_ref>]

set -euo pipefail

MODULE="${1:?usage: $0 <module> [since_ref]}"
SINCE="${2:-HEAD~100}"
ROOT="$(git rev-parse --show-toplevel)"
RUNTIME="${SPEC_PIPELINE_RUNTIME:-claude}"
case "$RUNTIME" in
  claude)
    STATE_BASE=".omc/state"
    ;;
  codex)
    STATE_BASE=".omx/state"
    ;;
  copilot)
    STATE_BASE=".copilot/state"
    ;;
  *)
    echo "✗ 不支持的 SPEC_PIPELINE_RUNTIME: $RUNTIME" >&2
    exit 2
    ;;
esac
OUTPUT="$ROOT/$STATE_BASE/outer-metrics/${MODULE}.json"

cd "$ROOT"

# 模块路径定位
MODULE_DIR="module/${MODULE}"
if [[ ! -d "$MODULE_DIR" ]]; then
  echo "✗ 模块目录不存在: $MODULE_DIR" >&2
  exit 1
fi

# 1. rework_commit_count: SINCE 以来涉及该模块路径的 commit 数
rework_commit_count=$(git log "$SINCE..HEAD" --oneline -- "$MODULE_DIR" "module/${MODULE}/" 2>/dev/null | wc -l | tr -d ' ')

# 2. rework_loc_ratio: 新增/删除 LOC 比例（机械近似）
loc_stats=$(git log "$SINCE..HEAD" --numstat --pretty=format: -- "$MODULE_DIR" "module/${MODULE}/" 2>/dev/null \
  | awk 'NF==3 {add+=$1; del+=$2} END {if(add+del==0)print "0";else printf "%.4f", del/(add+del)}')
rework_loc_ratio="${loc_stats:-0}"

# 3. spec_sha
spec_sha=$(git log -1 --format='%H' -- "$MODULE_DIR/SPEC.md" 2>/dev/null || echo "")

# 4. developer_override_count: commit 中含 "override" / "bypass scoring" 的数量
developer_override_count=$(git log "$SINCE..HEAD" --grep='override\|bypass.scoring\|verdict-override' --oneline 2>/dev/null | wc -l | tr -d ' ')

# 现有文件（如有）保留 ship_history，否则新建
existing="{}"
if [[ -f "$OUTPUT" ]]; then
  existing=$(cat "$OUTPUT")
fi

# 生成本次记录
now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
new_entry=$(cat <<JSON
{
  "computed_at": "$now",
  "spec_sha": "$spec_sha",
  "outer_metrics": {
    "real_bug_count_30d": null,
    "real_bug_count_90d": null,
    "rework_commit_count": $rework_commit_count,
    "rework_loc_ratio": $rework_loc_ratio,
    "test_flakiness_7d": null,
    "ci_failure_rate_post_merge_7d": null,
    "production_incident_count": null,
    "p99_latency_regression_pct": null,
    "security_advisory_count": null,
    "developer_override_count": $developer_override_count,
    "rollback_occurred": null
  }
}
JSON
)

# 合并：将本次记录追加到 ship_history（如有 jq 则用 jq，否则直接覆写最新快照）
mkdir -p "$(dirname "$OUTPUT")"
if command -v jq >/dev/null 2>&1; then
  echo "$existing" | jq \
    --arg module "$MODULE" \
    --arg last_updated "$now" \
    --argjson entry "$new_entry" \
    '.module = $module
     | .last_updated = $last_updated
     | .ship_history = (.ship_history // []) + [$entry]
     | ._note = "由 scripts/outer-metrics-from-git.sh 写入。LLM agent 严禁修改。"' \
    > "$OUTPUT"
else
  cat > "$OUTPUT" <<JSON
{
  "module": "$MODULE",
  "last_updated": "$now",
  "latest_snapshot": $new_entry,
  "_note": "由 scripts/outer-metrics-from-git.sh 写入。LLM agent 严禁修改。安装 jq 可保留完整 ship_history。"
}
JSON
fi

echo "✓ 写入 $OUTPUT"
echo "  rework_commit_count=$rework_commit_count"
echo "  rework_loc_ratio=$rework_loc_ratio"
echo "  developer_override_count=$developer_override_count"
