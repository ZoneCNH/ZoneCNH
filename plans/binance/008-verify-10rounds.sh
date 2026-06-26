#!/usr/bin/env bash
# 10-round final closeout verification for Plan 008 issues (v3 — closed-state + release evidence)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
JSON="$SCRIPT_DIR/008-tasks.json"
GH_MAP="$SCRIPT_DIR/008-gh-issue-map.tsv"
BMAP="$SCRIPT_DIR/008-beads-issue-map.tsv"
REPO="ZoneCNH/ZoneCNH"
RELEASE_REPO="ZoneCNH/binance"
RELEASE_TAG="v0.2.0"
RELEASE_WORKFLOW_RUN="28126779885"
if [ -z "${BEADS_DIR:-}" ]; then
  for candidate in "$REPO_ROOT/.beads" "$REPO_ROOT/../../../../.beads"; do
    if [ -d "$candidate" ]; then
      export BEADS_DIR="$(cd "$candidate" && pwd)"
      break
    fi
  done
fi
export BEADS_DIR="${BEADS_DIR:-$REPO_ROOT/.beads}"

SSOT_COUNT=$(jq '.tasks | length' "$JSON")

# GitHub live: all issues with plan008 label, final closeout requires all CLOSED.
GH_LIVE=$(gh issue list --repo "$REPO" --state all --label plan008 --limit 200 --json number,state,title --jq '.[] | "\(.number)\t\(.state)\t\(.title)"' 2>/dev/null)
GH_LIVE_COUNT=$(echo "$GH_LIVE" | grep -c . )
GH_CLOSED_COUNT=$(echo "$GH_LIVE" | awk -F'\t' '$2=="CLOSED"{c++} END{print c+0}')
GH_NON_CLOSED_COUNT=$(echo "$GH_LIVE" | awk -F'\t' '$2!="CLOSED"{c++} END{print c+0}')

# beads live: all issues, filter plan008 label via jq; final closeout requires all closed.
BD_ALL=$(bd list --all --json 2>/dev/null)
BD_LIVE=$(echo "$BD_ALL" | jq '[.[] | select((.labels // []) | index("plan008"))]')
BD_LIVE_COUNT=$(echo "$BD_LIVE" | jq 'length')
BD_CLOSED_COUNT=$(echo "$BD_LIVE" | jq '[.[] | select(.status == "closed")] | length')
BD_NON_CLOSED_COUNT=$(echo "$BD_LIVE" | jq '[.[] | select(.status != "closed")] | length')

RELEASE_INFO=$(gh release view "$RELEASE_TAG" --repo "$RELEASE_REPO" --json tagName,isDraft,isPrerelease,url 2>/dev/null)
RELEASE_OK=$(echo "$RELEASE_INFO" | jq -r 'select(.tagName=="v0.2.0" and (.isDraft|not) and (.isPrerelease|not)) | "true"' 2>/dev/null)
RUN_INFO=$(gh run view "$RELEASE_WORKFLOW_RUN" --repo "$RELEASE_REPO" --json status,conclusion,url 2>/dev/null)
RUN_OK=$(echo "$RUN_INFO" | jq -r 'select(.status=="completed" and .conclusion=="success") | "true"' 2>/dev/null)
CLOSEOUT_039=$(bd show ZoneCNH-036r --json 2>/dev/null | jq -r '.[0] | (.notes // "") + "\n" + (.close_reason // "")' 2>/dev/null)
CLOSEOUT_040=$(bd show ZoneCNH-771j --json 2>/dev/null | jq -r '.[0] | (.notes // "") + "\n" + (.close_reason // "")' 2>/dev/null)
CLOSEOUT_TEXT="${CLOSEOUT_039}
${CLOSEOUT_040}"
HAS_RELEASE_CLOSEABLE=$(echo "$CLOSEOUT_TEXT" | grep -q "release_closeable=YES" && echo true || echo false)
HAS_RELEASE_TAG=$(echo "$CLOSEOUT_TEXT" | grep -q "v0.2.0" && echo true || echo false)
HAS_RELEASE_WORKFLOW=$(echo "$CLOSEOUT_TEXT" | grep -q "28126779885" && echo true || echo false)

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
echo "Plan 008 — 10-Round Final Closeout Verification (v3)"
echo "============================================================"
echo "SSOT tasks:         $SSOT_COUNT"
echo "GitHub live (P008):  $GH_LIVE_COUNT (closed=$GH_CLOSED_COUNT non_closed=$GH_NON_CLOSED_COUNT)"
echo "beads live (P008):   $BD_LIVE_COUNT (closed=$BD_CLOSED_COUNT non_closed=$BD_NON_CLOSED_COUNT)"
echo "Release closeout:    release_ok=${RELEASE_OK:-false} run_ok=${RUN_OK:-false} release_closeable=$HAS_RELEASE_CLOSEABLE tag_note=$HAS_RELEASE_TAG workflow_note=$HAS_RELEASE_WORKFLOW"
echo "============================================================"
echo ""

# ROUND 1: Count/state match — SSOT 40 == GitHub 40 CLOSED == beads 40 closed
R1_GH=$( [ "$SSOT_COUNT" -eq "$GH_LIVE_COUNT" ] && [ "$GH_CLOSED_COUNT" -eq 40 ] && [ "$GH_NON_CLOSED_COUNT" -eq 0 ] && echo true || echo false )
R1_BD=$( [ "$SSOT_COUNT" -eq "$BD_LIVE_COUNT" ] && [ "$BD_CLOSED_COUNT" -eq 40 ] && [ "$BD_NON_CLOSED_COUNT" -eq 0 ] && echo true || echo false )
check 1 "Count/state: SSOT($SSOT_COUNT)==GH($GH_LIVE_COUNT CLOSED)==beads($BD_LIVE_COUNT closed)" \
  "$([ "$R1_GH" = true ] && [ "$R1_BD" = true ] && echo true || echo false)" \
  "GH match=$R1_GH closed=$GH_CLOSED_COUNT non_closed=$GH_NON_CLOSED_COUNT, beads match=$R1_BD closed=$BD_CLOSED_COUNT non_closed=$BD_NON_CLOSED_COUNT"

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

# ROUND 4: GH issue numbers unique & contiguous (#1132-#1171)
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
GH_TITLES_JSON=$(gh issue list --repo "$REPO" --state all --label plan008 --limit 200 --json number,state,title 2>/dev/null)
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

# ROUND 10: Coverage — all 35 standards (S1-S35) + 4 milestones (M1-M4) referenced in map field,
# plus release/workflow closeout evidence for final documentation tasks.
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
R10_COVERAGE=$([ -z "$STANDARDS_MISSING" ] && [ -z "$MILESTONES_MISSING" ] && echo true || echo false)
R10_CLOSEOUT=$([ "${RELEASE_OK:-false}" = true ] && [ "${RUN_OK:-false}" = true ] && [ "$HAS_RELEASE_CLOSEABLE" = true ] && [ "$HAS_RELEASE_TAG" = true ] && [ "$HAS_RELEASE_WORKFLOW" = true ] && echo true || echo false)
check 10 "All 35 standards (S1-S35) + 4 milestones (M1-M4) + release closeout covered" \
  "$([ "$R10_COVERAGE" = true ] && [ "$R10_CLOSEOUT" = true ] && echo true || echo false)" \
  "standards missing:${STANDARDS_MISSING:- none} | milestones missing:${MILESTONES_MISSING:- none} | release_ok=${RELEASE_OK:-false} run_ok=${RUN_OK:-false} release_closeable=$HAS_RELEASE_CLOSEABLE release_tag_note=$HAS_RELEASE_TAG workflow_note=$HAS_RELEASE_WORKFLOW"

echo ""
echo "============================================================"
echo "SUMMARY: $PASS_COUNT/10 rounds passed, $FAIL_COUNT failed"
echo "============================================================"
[ "$FAIL_COUNT" -eq 0 ] && exit 0 || exit 1
