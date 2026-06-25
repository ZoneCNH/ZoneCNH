#!/usr/bin/env bash
# 10-round completeness verification for Plan 008 issues (v2 — fixed jq paths + range logic)
set -uo pipefail

JSON="/home/ZoneCNH/plans/binance/008-tasks.json"
GH_MAP="/home/ZoneCNH/plans/binance/008-gh-issue-map.tsv"
BMAP="/home/ZoneCNH/plans/binance/008-beads-issue-map.tsv"
REPO="ZoneCNH/ZoneCNH"
export BEADS_DIR="/home/ZoneCNH/.beads"

SSOT_COUNT=$(jq '.tasks | length' "$JSON")

# GitHub live: all open issues with plan008 label
GH_LIVE=$(gh issue list --repo "$REPO" --state open --label plan008 --limit 200 --json number,title --jq '.[] | "\(.number)\t\(.title)"' 2>/dev/null)
GH_LIVE_COUNT=$(echo "$GH_LIVE" | grep -c . )

# beads live: all issues, filter plan008 label via jq
BD_ALL=$(bd list --all --json 2>/dev/null)
BD_LIVE=$(echo "$BD_ALL" | jq '[.[] | select(.labels | index("plan008"))]')
BD_LIVE_COUNT=$(echo "$BD_LIVE" | jq 'length')

PASS_COUNT=0
FAIL_COUNT=0

check() {
  local round="$1"; local desc="$2"; local condition="$3"; local detail="$4"
  if [ "$condition" = "true" ]; then
    echo "✅ Round $round PASS: $desc"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "❌ Round $round FAIL: $desc"
    echo "     detail: $detail"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

echo "============================================================"
echo "Plan 008 — 10-Round Completeness Verification (v2)"
echo "============================================================"
echo "SSOT tasks:         $SSOT_COUNT"
echo "GitHub live (P008):  $GH_LIVE_COUNT"
echo "beads live (P008):   $BD_LIVE_COUNT"
echo "============================================================"
echo ""

# ROUND 1: Count match — SSOT 40 == GitHub 40 == beads 40
R1_GH=$( [ "$SSOT_COUNT" -eq "$GH_LIVE_COUNT" ] && echo true || echo false )
R1_BD=$( [ "$SSOT_COUNT" -eq "$BD_LIVE_COUNT" ] && echo true || echo false )
check 1 "Count: SSOT($SSOT_COUNT)==GH($GH_LIVE_COUNT)==beads($BD_LIVE_COUNT)" \
  "$([ "$R1_GH" = true ] && [ "$R1_BD" = true ] && echo true || echo false)" \
  "GH match=$R1_GH, beads match=$R1_BD"

# ROUND 2: Every SSOT task_id present in GH map
MISSING_IN_GHMAP=""
for i in $(seq 0 $((SSOT_COUNT - 1))); do
  TID=$(jq -r ".tasks[$i].id" "$JSON")
  grep -qP "^${TID}\t" "$GH_MAP" || MISSING_IN_GHMAP="$MISSING_IN_GHMAP $TID"
done
check 2 "Every SSOT task_id has GH map entry" \
  "$([ -z "$MISSING_IN_GHMAP" ] && echo true || echo false)" \
  "missing in GH map:${MISSING_IN_GHMAP:- none}"

# ROUND 3: Every SSOT task_id present in beads map
MISSING_IN_BMAP=""
for i in $(seq 0 $((SSOT_COUNT - 1))); do
  TID=$(jq -r ".tasks[$i].id" "$JSON")
  grep -qP "^${TID}\t" "$BMAP" || MISSING_IN_BMAP="$MISSING_IN_BMAP $TID"
done
check 3 "Every SSOT task_id has beads map entry" \
  "$([ -z "$MISSING_IN_BMAP" ] && echo true || echo false)" \
  "missing in beads map:${MISSING_IN_BMAP:- none}"

# ROUND 4: GH issue numbers unique & contiguous (#105-#144)
GH_NUMS=$(awk -F'\t' 'NR>1{print $2}' "$GH_MAP" | sort -n)
GH_UNIQUE=$(echo "$GH_NUMS" | sort -u | wc -l)
GH_TOTAL=$(echo "$GH_NUMS" | wc -l)
GH_MIN=$(echo "$GH_NUMS" | head -1)
GH_MAX=$(echo "$GH_NUMS" | tail -1)
EXPECTED_RANGE=$((GH_MAX - GH_MIN + 1))
check 4 "GH issue numbers unique & contiguous ($GH_MIN-$GH_MAX)" \
  "$([ "$GH_UNIQUE" -eq "$GH_TOTAL" ] && [ "$GH_TOTAL" -eq 40 ] && [ "$EXPECTED_RANGE" -eq 40 ] && echo true || echo false)" \
  "unique=$GH_UNIQUE total=$GH_TOTAL range=$EXPECTED_RANGE min=$GH_MIN max=$GH_MAX"

# ROUND 5: beads IDs all unique
BD_IDS=$(awk -F'\t' 'NR>1{print $2}' "$BMAP")
BD_UNIQUE=$(echo "$BD_IDS" | sort -u | wc -l)
BD_TOTAL=$(echo "$BD_IDS" | wc -l)
check 5 "beads IDs all unique ($BD_TOTAL)" \
  "$([ "$BD_UNIQUE" -eq "$BD_TOTAL" ] && [ "$BD_TOTAL" -eq 40 ] && echo true || echo false)" \
  "unique=$BD_UNIQUE total=$BD_TOTAL"

# ROUND 6: Every beads issue has external_ref matching its GH number (using live bd show, array path .[0].external_ref)
EXTREF_MISMATCH=""
for i in $(seq 0 $((SSOT_COUNT - 1))); do
  TID=$(jq -r ".tasks[$i].id" "$JSON")
  BD_ID=$(awk -F'\t' -v t="$TID" '$1==t{print $2}' "$BMAP")
  GH_NUM=$(awk -F'\t' -v t="$TID" '$1==t{print $3}' "$BMAP")
  EXTREF=$(bd show "$BD_ID" --json 2>/dev/null | jq -r '.[0].external_ref // empty')
  if [ "$EXTREF" != "gh-$GH_NUM" ]; then
    EXTREF_MISMATCH="$EXTREF_MISMATCH $TID(beads=$BD_ID ref=$EXTREF expect=gh-$GH_NUM)"
  fi
done
check 6 "Every beads external_ref matches GH number (live query)" \
  "$([ -z "$EXTREF_MISMATCH" ] && echo true || echo false)" \
  "mismatch:${EXTREF_MISMATCH:- none}"

# ROUND 7: GitHub live issue numbers exact match map numbers
GH_LIVE_NUMS=$(echo "$GH_LIVE" | awk -F'\t' '{print $1}' | sort -n)
GH_MAP_NUMS=$(awk -F'\t' 'NR>1{print $2}' "$GH_MAP" | sort -n)
GH_DIFF=$(diff <(echo "$GH_MAP_NUMS") <(echo "$GH_LIVE_NUMS"))
check 7 "GH map numbers == GH live numbers (exact set match)" \
  "$([ -z "$GH_DIFF" ] && echo true || echo false)" \
  "diff: $GH_DIFF"

# ROUND 8: Title consistency — every live GH issue title contains its task_id
# Batch-fetch all titles in one API call to avoid rate limits
GH_TITLES_JSON=$(gh issue list --repo "$REPO" --state open --label plan008 --limit 200 --json number,title 2>/dev/null)
TITLE_MISMATCH=""
for i in $(seq 0 $((SSOT_COUNT - 1))); do
  TID=$(jq -r ".tasks[$i].id" "$JSON")
  GH_NUM=$(awk -F'\t' -v t="$TID" '$1==t{print $2}' "$GH_MAP")
  GH_TITLE=$(echo "$GH_TITLES_JSON" | jq -r --arg n "$GH_NUM" '.[] | select(.number == ($n|tonumber)) | .title')
  echo "$GH_TITLE" | grep -q "\[$TID\]" || TITLE_MISMATCH="$TITLE_MISMATCH $TID(gh#$GH_NUM)"
done
check 8 "Every GH issue title contains [task_id]" \
  "$([ -z "$TITLE_MISMATCH" ] && echo true || echo false)" \
  "mismatch:${TITLE_MISMATCH:- none}"

# ROUND 9: Coverage — all 9 gaps (G1-G9) referenced in some task's gap field
GAPS_MISSING=""
for G in G1 G2 G3 G4 G5 G6 G7 G8 G9; do
  HAS=$(jq --arg g "$G" '[.tasks[] | select(.gap | tostring | test($g))] | length' "$JSON")
  [ "$HAS" -gt 0 ] || GAPS_MISSING="$GAPS_MISSING $G(has=$HAS)"
done
check 9 "All 9 data gaps (G1-G9) covered by >=1 task" \
  "$([ -z "$GAPS_MISSING" ] && echo true || echo false)" \
  "gaps without task:${GAPS_MISSING:- none}"

# ROUND 10: Coverage — all 35 standards (S1-S35) + 4 milestones (M1-M4) referenced in map field
# map field uses: exact "S1", range "S18-S25", combo "S8/S10/S11/S15", or "M1-M4"
# Expand all map fields into a flat set of covered standard/milestone codes
expand_map() {
  local m="$1"
  # split on / and , to get individual tokens
  echo "$m" | tr '/' '\n' | tr ',' '\n' | while read -r tok; do
    tok=$(echo "$tok" | tr -d ' ')
    [ -z "$tok" ] && continue
    if echo "$tok" | grep -qE '^S[0-9]+-S[0-9]+$'; then
      # range like S18-S25
      lo=$(echo "$tok" | sed -E 's/S([0-9]+)-S([0-9]+)/\1/')
      hi=$(echo "$tok" | sed -E 's/S([0-9]+)-S([0-9]+)/\2/')
      for n in $(seq "$lo" "$hi"); do echo "S$n"; done
    elif echo "$tok" | grep -qE '^M[0-9]+-M[0-9]+$'; then
      lo=$(echo "$tok" | sed -E 's/M([0-9]+)-M([0-9]+)/\1/')
      hi=$(echo "$tok" | sed -E 's/M([0-9]+)-M([0-9]+)/\2/')
      for n in $(seq "$lo" "$hi"); do echo "M$n"; done
    else
      echo "$tok"
    fi
  done
}

# Build covered set from all tasks' map fields
COVERED=""
for i in $(seq 0 $((SSOT_COUNT - 1))); do
  MAPF=$(jq -r ".tasks[$i].map" "$JSON")
  COVERED="$COVERED
$(expand_map "$MAPF")"
done
COVERED_SORTED=$(echo "$COVERED" | grep -v '^$' | sort -u)

STANDARDS_MISSING=""
for n in $(seq 1 35); do
  S="S$n"
  echo "$COVERED_SORTED" | grep -qx "$S" || STANDARDS_MISSING="$STANDARDS_MISSING $S"
done
MILESTONES_MISSING=""
for m in 1 2 3 4; do
  M="M$m"
  echo "$COVERED_SORTED" | grep -qx "$M" || MILESTONES_MISSING="$MILESTONES_MISSING $M"
done
check 10 "All 35 standards (S1-S35) + 4 milestones (M1-M4) covered" \
  "$([ -z "$STANDARDS_MISSING" ] && [ -z "$MILESTONES_MISSING" ] && echo true || echo false)" \
  "standards missing:${STANDARDS_MISSING:- none} | milestones missing:${MILESTONES_MISSING:- none}"

echo ""
echo "============================================================"
echo "SUMMARY: $PASS_COUNT/10 rounds passed, $FAIL_COUNT failed"
echo "============================================================"
[ "$FAIL_COUNT" -eq 0 ] && exit 0 || exit 1
