#!/usr/bin/env bash
# sync-version.sh — 同步模块版本号到所有核心文档
#
# Usage: ./scripts/sync-version.sh <module> <new_version>
# Example: ./scripts/sync-version.sh binance v0.7.0
#
# Updates: STATUS.md, README.md, ARCHITECTURE.md, report/binance/deep-review-*.md
# Run from repo root. Dry-run with --dry-run.

set -euo pipefail

MODULE="${1:-}"
NEW_VERSION="${2:-}"
DRY_RUN=false
[[ "${3:-}" == "--dry-run" ]] && DRY_RUN=true

if [[ -z "$MODULE" || -z "$NEW_VERSION" ]]; then
  echo "Usage: $0 <module> <new_version> [--dry-run]"
  echo "Example: $0 binance v0.7.0"
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Detect current version from STATUS.md
CURRENT_VERSION=$(grep -oP "${MODULE}.*?v\d+\.\d+\.\d+" STATUS.md | grep -oP 'v\d+\.\d+\.\d+' | head -1)
if [[ -z "$CURRENT_VERSION" ]]; then
  echo "ERROR: Could not detect current version for '$MODULE' in STATUS.md"
  exit 1
fi

echo "Syncing $MODULE: $CURRENT_VERSION → $NEW_VERSION"
echo "Files to update: STATUS.md, README.md, ARCHITECTURE.md"
for f in report/${MODULE}/deep-review-*.md; do
  [[ -f "$f" ]] && echo "  + $f"
done

if $DRY_RUN; then
  echo ""
  echo "DRY RUN — no changes made. Remove --dry-run to apply."
  exit 0
fi

failures=0

# Update each file
for file in STATUS.md README.md ARCHITECTURE.md; do
  if sed -i "s/${CURRENT_VERSION}/${NEW_VERSION}/g" "$file"; then
    echo "  UPDATED: $file"
  else
    echo "  FAILED: $file"
    failures=$((failures + 1))
  fi
done

# Update deep-review report if exists
for f in report/${MODULE}/deep-review-*.md; do
  if [[ -f "$f" ]]; then
    if sed -i "s/${CURRENT_VERSION}/${NEW_VERSION}/g" "$f"; then
      echo "  UPDATED: $f"
    else
      echo "  FAILED: $f"
      failures=$((failures + 1))
    fi
  fi
done

if [[ $failures -gt 0 ]]; then
  echo ""
  echo "WARNING: $failures file(s) failed to update. Check manually."
  exit 1
fi

echo ""
echo "Done. Review changes with: git diff"
echo "Then commit: git add -A && git commit -m 'docs: bump $MODULE $CURRENT_VERSION → $NEW_VERSION'"
