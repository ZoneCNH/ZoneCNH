#!/usr/bin/env bash
set -euo pipefail

ISSUE="${1:-}"
PR="${2:-}"

if [[ -z "$ISSUE" || -z "$PR" ]]; then
  echo "Usage: module/binance/scripts/runtime-gap-close-check.sh <issue> <binance-pr>"
  exit 2
fi

echo "== runtime-gap close gate =="
echo "issue: ZoneCNH/ZoneCNH#$ISSUE"
echo "pr:    ZoneCNH/binance#$PR"

PR_STATE="$(gh pr view "$PR" -R ZoneCNH/binance --json state --jq .state)"
if [[ "$PR_STATE" != "MERGED" ]]; then
  echo "FAIL: runtime PR is not merged (state=$PR_STATE)"
  exit 1
fi

ISSUE_STATE="$(gh issue view "$ISSUE" -R ZoneCNH/ZoneCNH --json state --jq .state)"
if [[ "$ISSUE_STATE" != "OPEN" ]]; then
  echo "FAIL: issue must be OPEN before close workflow (state=$ISSUE_STATE)"
  exit 1
fi

echo "PASS: merged runtime PR + open issue gate satisfied"
echo "NEXT: close issue, then sync todo.md + plans/binance/010 + plans/binance/011 snapshots"
