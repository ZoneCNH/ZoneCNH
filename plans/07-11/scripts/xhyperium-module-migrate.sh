#!/bin/bash
# xhyperium-module-migrate.sh — 单模块 org 迁移
# 用法: ./xhyperium-module-migrate.sh <module-name>
set -euo pipefail

FROM='github.com/ZoneCNH/'
TO='github.com/xhyperium/'

MODULE="${1:?usage: $0 <module-name>}"
REPO="/home/workspace/${MODULE}"
BRANCH="fix/xhyperium-org-migration"

echo "=== ${MODULE}: org migration ==="

[ ! -d "$REPO" ] && { echo "FAIL: repo not found at $REPO"; exit 1; }
cd "$REPO"

[ ! -f "go.mod" ] && { echo "SKIP: no go.mod"; exit 0; }

if [ "${DRY_RUN:-0}" != "1" ] && [ -n "$(git status --porcelain -uno 2>/dev/null)" ]; then
    echo "FAIL: tracked files modified"
    exit 1
fi

echo "Current go.mod module: $(head -1 go.mod)"

if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "DRY_RUN: would change ${MODULE}"
    grep -rn "${FROM}" --include="*.go" --include="*.mod" . 2>/dev/null | grep -v '/.git/' | grep -v '/.omx/' | grep -v '/.worktree/' | head -20 || echo "  (no refs)"
    exit 0
fi

if ! grep -rq "${FROM}" --include="*.go" --include="*.mod" . 2>/dev/null; then
    echo "SKIP: ${MODULE} has no ZoneCNH refs"
    exit 0
fi

echo "[1/6] git checkout -b ${BRANCH}"
git fetch origin main 2>/dev/null || true
git checkout -b "${BRANCH}" origin/main

echo "[2/6] fixing go.mod"
sed -i "s|${FROM}|${TO}|g" go.mod

echo "[3/6] fixing imports"
find . -name "*.go" -type f \
    -not -path '*/.git/*' -not -path '*/.omx/*' -not -path '*/.worktree/*' \
    -exec sed -i "s|${FROM}|${TO}|g" {} +

echo "[4/6] fixing docs"
find . \( -name "*.md" -o -name "*.yaml" -o -name "*.yml" \) -type f \
    -not -path '*/.git/*' -not -path '*/.omx/*' -not -path '*/.worktree/*' \
    -exec sed -i "s|${FROM}|${TO}|g" {} + 2>/dev/null || true

echo "[5/6] go mod tidy — SKIPPED (cascading dependency; module $MODULE dependents may not be migrated yet)"

echo "[6/6] git diff —stat"
git diff --stat origin/main 2>/dev/null | head -20 || echo "(no diff)"
echo "[DONE] ${MODULE}"
