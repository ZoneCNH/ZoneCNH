#!/bin/bash
# migrate-zonecnh-configs.sh — 更新 ZoneCNH 主仓 SSOT 配置：ZoneCNH → xhyperium
set -euo pipefail

ZONECNH="/home/workspace/ZoneCNH"
BRANCH="fix/xhyperium-org-configs"
FROM="github.com/xhyperium/"
TO="github.com/xhyperium/"

echo "=== ZoneCNH config: ZoneCNH → xhyperium org migration ==="
cd "$ZONECNH"

if [ -n "$(git status --porcelain -uno)" ]; then
    echo "FAIL: tracked files have uncommitted changes"
    exit 1
fi

echo ""
echo "--- Impact analysis ---"
echo "FOUNDATION-DEPS.yaml: $(grep -c "${FROM}" module/FOUNDATION-DEPS.yaml 2>/dev/null || echo 0) refs"
echo "module/registry.yaml:  $(grep -c "${FROM}" module/registry.yaml 2>/dev/null || echo 0) refs"
echo ".foundationx/status/:  $(grep -rn "${FROM}" .foundationx/status/ 2>/dev/null | wc -l) refs"
echo "plans/07-11/:          $(grep -rn "${FROM}" plans/07-11/ --include='*.md' --include='*.yaml' 2>/dev/null | wc -l) refs"
echo "docs/:                 $(grep -rn "${FROM}" docs/ --include='*.md' 2>/dev/null | wc -l) refs"
echo ""

if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "DRY_RUN: would modify configs and docs"
    exit 0
fi

echo "[1/5] git checkout -b $BRANCH"
git checkout -b "$BRANCH"

echo "[2/5] updating FOUNDATION-DEPS.yaml + registry.yaml + status"
sed -i "s|${FROM}|${TO}|g" module/FOUNDATION-DEPS.yaml
sed -i "s|${FROM}|${TO}|g" module/registry.yaml
find .foundationx/status/ -name "*.json" -exec sed -i "s|${FROM}|${TO}|g" {} +

echo "[3/5] updating plans/ documents"
find plans/ -name "*.md" -o -name "*.yaml" -o -name "*.yml" 2>/dev/null | \
    xargs -r sed -i "s|${FROM}|${TO}|g" 2>/dev/null || true

echo "[4/5] updating docs/ directory"
find docs/ -name "*.md" -o -name "*.yaml" 2>/dev/null | \
    xargs -r sed -i "s|${FROM}|${TO}|g" 2>/dev/null || true

echo "[5/5] updating scripts"
find plans/07-11/scripts/ -name "*.sh" 2>/dev/null | \
    xargs -r sed -i "s|${FROM}|${TO}|g" 2>/dev/null || true

echo ""
echo "--- Verification ---"
echo "Remaining ZoneCNH refs in SSOT configs:"
grep -rn "${FROM}" module/ .foundationx/ 2>/dev/null | grep -v '.git/' | head -5 || echo "  (clean)"

echo ""
echo "--- git diff stat ---"
git diff --stat

echo ""
echo "[DONE] ZoneCNH config migration"
echo "  Review: cd $ZONECNH && git diff"
