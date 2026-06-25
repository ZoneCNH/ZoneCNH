#!/usr/bin/env bash
# Update beads 40 issues' external_ref to point to new ZoneCNH/ZoneCNH issue numbers
set -euo pipefail

export BEADS_DIR="/home/ZoneCNH/.beads"
BMAP="/home/ZoneCNH/plans/binance/008-beads-issue-map.tsv"
GH_MAP="/home/ZoneCNH/plans/binance/008-gh-issue-map.tsv"

echo "=== Updating 40 beads external_ref to ZoneCNH/ZoneCNH issues ==="
UPDATED=0; FAILED=0

for i in $(seq 0 39); do
  TID=$(awk -F'\t' -v n=$((i+2)) 'NR==n{print $1}' "$BMAP")
  BD_ID=$(awk -F'\t' -v n=$((i+2)) 'NR==n{print $2}' "$BMAP")
  NEW_GH=$(awk -F'\t' -v tid="$TID" '$1==tid{print $2}' "$GH_MAP")

  if [ -z "$BD_ID" ] || [ -z "$NEW_GH" ]; then
    echo "  WARN: $TID missing bd_id=$BD_ID or gh=$NEW_GH" >&2
    FAILED=$((FAILED + 1))
    continue
  fi

  # Update external_ref to new ZoneCNH issue number
  if bd update "$BD_ID" --external-ref="gh-$NEW_GH" 2>/dev/null | grep -q "Updated\|✓"; then
    UPDATED=$((UPDATED + 1))
  else
    # bd update may output nothing on success, check exit code
    bd update "$BD_ID" --external-ref="gh-$NEW_GH" >/dev/null 2>&1 && UPDATED=$((UPDATED + 1)) || {
      FAILED=$((FAILED + 1))
      echo "  WARN: update failed $TID ($BD_ID) -> gh-$NEW_GH" >&2
    }
  fi
done

echo ""
echo "Updated: $UPDATED / 40, Failed: $FAILED"
