#!/usr/bin/env bash
# Create 40 GitHub issues for Plan 008 in ZoneCNH/binance from 008-tasks.json
# Records mapping task_id -> gh_issue_number to 008-gh-issue-map.tsv
set -euo pipefail

REPO="ZoneCNH/binance"
JSON="/home/ZoneCNH/plans/binance/008-tasks.json"
MAP="/home/ZoneCNH/plans/binance/008-gh-issue-map.tsv"

# Initialize map file with header (truncate if exists)
echo -e "task_id\tgh_issue\ttitle" > "$MAP"

COUNT=$(jq '.tasks | length' "$JSON")
echo "Creating $COUNT GitHub issues in $REPO..."

for i in $(seq 0 $((COUNT - 1))); do
  TASK_ID=$(jq -r ".tasks[$i].id" "$JSON")
  TITLE=$(jq -r ".tasks[$i].title" "$JSON")
  PHASE=$(jq -r ".tasks[$i].phase" "$JSON")
  MAP_=$(jq -r ".tasks[$i].map" "$JSON")
  GAP=$(jq -r ".tasks[$i].gap" "$JSON")
  PRIORITY=$(jq -r ".tasks[$i].priority" "$JSON")
  OWNER=$(jq -r ".tasks[$i].owner" "$JSON")
  DEPS=$(jq -r ".tasks[$i].deps | join(\", \")" "$JSON")
  ACC=$(jq -r ".tasks[$i].acceptance" "$JSON")
  SOURCE=$(jq -r ".tasks[$i].source" "$JSON")
  LABELS=$(jq -r ".tasks[$i].gh_labels | join(\",\")" "$JSON")

  # Build issue title with priority prefix and task id
  GH_TITLE="[$PRIORITY] [$TASK_ID] $TITLE"

  # Build issue body
  BODY=$(cat <<EOF
## Task: $TASK_ID

| 字段 | 值 |
| --- | --- |
| Plan | 008 — binance 生产级修复总 Plan |
| Task ID | $TASK_ID |
| Phase | $PHASE |
| 映射 | $MAP_ |
| 缺口 | $GAP |
| 优先级 | $PRIORITY |
| 责任方 | $OWNER |
| 依赖 | $DEPS |
| 来源 | $SOURCE |

## 验收标准

$ACC

## 上下文

本 issue 来自 [Plan 008](https://github.com/ZoneCNH/ZoneCNH/blob/main/plans/binance/008-binance-production-fix-master-plan.md) Task $TASK_ID。

- Runtime-Anchor: \`/home/binance@3f20be0\`
- Plan 008 覆盖 9 数据缺口 (G1-G9) + 35 标准化 (S1-S35) + 4 规模化 (M1-M4)，共 40 Task。

## 追溯

- Plan 文档: \`plans/binance/008-binance-production-fix-master-plan.md\`
- 数据源 SSOT: \`plans/binance/008-tasks.json\`
EOF
)

  # Create issue, capture URL
  ISSUE_URL=$(gh issue create --repo "$REPO" \
    --title "$GH_TITLE" \
    --body "$BODY" \
    --label "$LABELS" 2>&1) || {
      echo "ERROR creating $TASK_ID: $ISSUE_URL" >&2
      exit 1
    }

  # Extract issue number from URL
  ISSUE_NUM=$(echo "$ISSUE_URL" | grep -oE '[0-9]+$')

  echo -e "${TASK_ID}\t${ISSUE_NUM}\t${TITLE}" >> "$MAP"
  echo "[$((i+1))/$COUNT] $TASK_ID -> #$ISSUE_NUM  $TITLE"
done

echo ""
echo "=== Done. Map saved to $MAP ==="
echo "Total issues created: $(($(wc -l < "$MAP") - 1))"
