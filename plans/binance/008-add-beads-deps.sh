#!/usr/bin/env bash
# Add dependency links between beads issues for Plan 008 using bd link
# bd link <current> <dependency>  => dependency blocks current
set -euo pipefail

JSON="/home/ZoneCNH/plans/binance/008-tasks.json"
BMAP="/home/ZoneCNH/plans/binance/008-beads-issue-map.tsv"

export BEADS_DIR="/home/ZoneCNH/.beads"

beads_id_for() {
  awk -F'\t' -v tid="$1" '$1==tid{print $2}' "$BMAP"
}

COUNT=$(jq '.tasks | length' "$JSON")
echo "Linking dependencies via bd link..."

ADDED=0
SKIPPED=0
FAILED=0

for i in $(seq 0 $((COUNT - 1))); do
  TASK_ID=$(jq -r ".tasks[$i].id" "$JSON")
  DEPS_JSON=$(jq -c ".tasks[$i].deps" "$JSON")
  DEP_COUNT=$(echo "$DEPS_JSON" | jq 'length')

  if [ "$DEP_COUNT" -eq 0 ]; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  CURRENT_BEADS=$(beads_id_for "$TASK_ID")

  for d in $(seq 0 $((DEP_COUNT - 1))); do
    DEP_TASK=$(echo "$DEPS_JSON" | jq -r ".[$d]")
    DEP_BEADS=$(beads_id_for "$DEP_TASK")
    if [ -z "$DEP_BEADS" ]; then
      echo "  WARN: no beads id for dep $DEP_TASK (task $TASK_ID)" >&2
      FAILED=$((FAILED + 1))
      continue
    fi
    # bd link <current> <dep> => dep blocks current
    if bd link "$CURRENT_BEADS" "$DEP_BEADS" --type blocks 2>/dev/null; then
      ADDED=$((ADDED + 1))
      echo "  $TASK_ID ($CURRENT_BEADS) blocked-by $DEP_TASK ($DEP_BEADS)"
    else
      # Maybe already linked, check
      FAILED=$((FAILED + 1))
      echo "  WARN: link failed $CURRENT_BEADS <- $DEP_BEADS ($TASK_ID <- $DEP_TASK)" >&2
    fi
  done
done

echo ""
echo "=== Done. Links added: $ADDED, no-deps skipped: $SKIPPED, failed: $FAILED ==="
