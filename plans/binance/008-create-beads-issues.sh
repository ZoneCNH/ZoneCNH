#!/usr/bin/env bash
# Create 40 beads issues for Plan 008 in ZoneCNH beads workspace
# Links each to its GitHub issue via --external-ref gh-N
# Records mapping task_id -> beads_id -> gh_issue to 008-beads-issue-map.tsv
set -euo pipefail

JSON="/home/workspace/ZoneCNH/plans/binance/008-tasks.json"
GH_MAP="/home/workspace/ZoneCNH/plans/binance/008-gh-issue-map.tsv"
BMAP="/home/workspace/ZoneCNH/plans/binance/008-beads-issue-map.tsv"

echo -e "task_id\tbeads_id\tgh_issue\ttitle" > "$BMAP"

COUNT=$(jq '.tasks | length' "$JSON")
echo "Creating $COUNT beads issues..."

export BEADS_DIR="/home/workspace/ZoneCNH/.beads"

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

  # Look up gh issue number from gh map
  GH_ISSUE=$(awk -F'\t' -v tid="$TASK_ID" '$1==tid{print $2}' "$GH_MAP")

  BD_TITLE="[Plan008 $TASK_ID] $TITLE"

  BD_DESC="Plan 008 Task $TASK_ID (Phase $PHASE) | 映射: $MAP_ | 缺口: $GAP | 优先级: $PRIORITY | 责任方: $OWNER | 依赖: $DEPS | 验收: $ACC | 来源: $SOURCE | GitHub: ZoneCNH/binance#$GH_ISSUE"

  # Priority mapping P0->0, P1->1, P2->2
  case "$PRIORITY" in
    P0) BD_PRI="0";;
    P1) BD_PRI="1";;
    P2) BD_PRI="2";;
    *)  BD_PRI="2";;
  esac

  # Type: most are feature/enhancement; use 'task' as default, bug for T003
  BD_TYPE="task"

  # Create with --silent to get just the ID
  BEADS_ID=$(bd create "$BD_TITLE" \
    --description="$BD_DESC" \
    --type="$BD_TYPE" \
    --priority="$BD_PRI" \
    --external-ref="gh-$GH_ISSUE" \
    --labels="plan008,phase$PHASE,binance" \
    --acceptance="$ACC" \
    --silent 2>/dev/null) || {
      echo "ERROR creating beads for $TASK_ID" >&2
      # retry without silent to see error
      bd create "$BD_TITLE" --description="$BD_DESC" --type="$BD_TYPE" --priority="$BD_PRI" --external-ref="gh-$GH_ISSUE" --labels="plan008,phase$PHASE,binance" --acceptance="$ACC" 2>&1 >&2
      exit 1
    }

  echo -e "${TASK_ID}\t${BEADS_ID}\t${GH_ISSUE}\t${TITLE}" >> "$BMAP"
  echo "[$((i+1))/$COUNT] $TASK_ID -> $BEADS_ID (gh-$GH_ISSUE)  $TITLE"
done

echo ""
echo "=== Done. Beads map at $BMAP ==="
echo "Total beads issues: $(($(wc -l < "$BMAP") - 1))"
