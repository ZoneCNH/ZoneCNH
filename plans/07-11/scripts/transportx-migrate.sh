#!/bin/bash
# =============================================================================
# transportx 迁移脚本: xlib-standard → transportx (特殊: 模块名完全改变)
# =============================================================================
set -euo pipefail

MODULE="transportx"
MODULE_DIR="/home/workspace/${MODULE}"
OLD_MODULE_PATH="github.com/xhyperium/xlib-standard"
NEW_MODULE_PATH="github.com/xhyperium/transportx"
OLD_NAME="xlib-standard"
NEW_NAME="transportx"
BRANCH="fix/snake-case-migration"

# ---------------------------------------------------------------------------
# DRY_RUN mode
# ---------------------------------------------------------------------------
DRY_RUN="${DRY_RUN:-0}"
if [ "$DRY_RUN" = "1" ]; then
    echo "[DRY_RUN] Would migrate ${MODULE}: ${OLD_NAME} → ${NEW_NAME}"
    echo "[DRY_RUN] Branch: ${BRANCH} from origin/main"
    echo "[DRY_RUN] go.mod: ${OLD_MODULE_PATH} → ${NEW_MODULE_PATH}"
    echo "[DRY_RUN] NOTE: Module name completely changes (special case)"
    exit 0
fi

echo "========================================="
echo "  Migration: ${OLD_NAME} → ${NEW_NAME}"
echo "  SPECIAL CASE: Complete module rename"
echo "========================================="

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
echo "[PRE-FLIGHT] Checking pre-conditions..."
if [ ! -d "$MODULE_DIR" ]; then
    echo "ERROR: Module directory ${MODULE_DIR} does not exist"
    exit 1
fi
if [ ! -f "${MODULE_DIR}/go.mod" ]; then
    echo "ERROR: go.mod not found in ${MODULE_DIR}"
    exit 1
fi

cd "$MODULE_DIR"

# Verify current go.mod has expected old path
if ! grep -q "$OLD_MODULE_PATH" go.mod; then
    echo "WARNING: Expected old module path '${OLD_MODULE_PATH}' not found in go.mod"
    grep "module " go.mod
    if [ "${NON_INTERACTIVE:-0}" = "1" ]; then
        echo "WARNING: Current branch is not main. Proceeding (non-interactive)."
    else
        echo "WARNING: Non-interactive mode — proceeding automatically"
    fi
fi

CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "WARNING: Current branch is '${CURRENT_BRANCH}', not 'main'."
    if [ "${NON_INTERACTIVE:-0}" = "1" ]; then
        echo "WARNING: Current branch is not main. Proceeding (non-interactive)."
    else
        echo "WARNING: Non-interactive mode — proceeding automatically"
    fi
fi

if ! git diff --quiet HEAD 2>/dev/null; then
    echo "ERROR: Working directory has uncommitted changes. Stash or commit first."
    exit 1
fi

# ---------------------------------------------------------------------------
# Pre-change diagnostic: check for internal xlib-standard dependency residues
# ---------------------------------------------------------------------------
echo "[PRE-FLIGHT] Checking for ${OLD_NAME} dependency residues..."
if grep -r "$OLD_NAME" --include="*.go" --include="*.mod" --include="*.sum" --include="*.md" \
    --include="*.yaml" --include="*.yml" . 2>/dev/null | grep -v "migrate\|\.git\|\b${NEW_NAME}\b" > /tmp/transportx_residue_pre.txt; then
    echo "  Files referencing ${OLD_NAME} (will be updated):"
    cat /tmp/transportx_residue_pre.txt
else
    echo "  No residue found."
fi
rm -f /tmp/transportx_residue_pre.txt

echo "[PRE-FLIGHT] OK"

# ---------------------------------------------------------------------------
# Step 1: Create branch
# ---------------------------------------------------------------------------
echo "[STEP 1/7] Creating branch ${BRANCH} from origin/main..."
git fetch origin main 2>/dev/null || git fetch origin main
if git rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
    echo "Branch ${BRANCH} already exists, checking out..."
    git checkout "$BRANCH"
else
    git checkout -b "$BRANCH" origin/main
fi
echo "[STEP 1/7] Done"

# ---------------------------------------------------------------------------
# Step 2: Fix go.mod (COMPLETE module path change)
# ---------------------------------------------------------------------------
echo "[STEP 2/7] Fixing go.mod: ${OLD_MODULE_PATH} → ${NEW_MODULE_PATH}..."
sed -i "s|${OLD_MODULE_PATH}|${NEW_MODULE_PATH}|g" go.mod
echo "[STEP 2/7] Done"

# ---------------------------------------------------------------------------
# Step 3: Fix import paths in all .go files
# ---------------------------------------------------------------------------
echo "[STEP 3/7] Fixing import paths in .go files..."
GO_FILES=$(find . -name "*.go" -type f 2>/dev/null || true)
if [ -n "$GO_FILES" ]; then
    for f in $GO_FILES; do
        # Replace full import paths
        sed -i "s|${OLD_MODULE_PATH}|${NEW_MODULE_PATH}|g" "$f"
        # Also replace bare xlib-standard references in comments/strings
        sed -i "s|${OLD_NAME}|${NEW_NAME}|g" "$f"
    done
fi
echo "[STEP 3/7] Done"

# ---------------------------------------------------------------------------
# Step 4: Fix documentation references
# ---------------------------------------------------------------------------
echo "[STEP 4/7] Fixing documentation references..."
find . \( -name "*.md" -o -name "*.yaml" -o -name "*.yml" -o -name "*.toml" \) -type f 2>/dev/null | while read -r f; do
    if grep -q "$OLD_NAME" "$f" 2>/dev/null; then
        sed -i "s|${OLD_NAME}|${NEW_NAME}|g" "$f"
        echo "  fixed: $f"
    fi
done
echo "[STEP 4/7] Done"

# ---------------------------------------------------------------------------
# Step 5: Fix CI workflow references
# ---------------------------------------------------------------------------
echo "[STEP 5/7] Fixing CI workflow references..."
if [ -d ".github/workflows" ]; then
    for f in .github/workflows/*.yml .github/workflows/*.yaml; do
        [ -f "$f" ] || continue
        if grep -q "$OLD_NAME" "$f" 2>/dev/null; then
            sed -i "s|${OLD_NAME}|${NEW_NAME}|g" "$f"
            echo "  fixed: $f"
        fi
    done
fi
echo "[STEP 5/7] Done"

# ---------------------------------------------------------------------------
# Step 6: go mod tidy (regenerates go.sum) + build verification
# ---------------------------------------------------------------------------
echo "[STEP 6/7] Running go mod tidy (will regenerate go.sum)..."
go mod tidy 2>&1 || { echo "ERROR: go mod tidy failed"; exit 1; }

echo "[STEP 6/7] Running go build ./..."
GOWORK=off go build ./... 2>&1 || { echo "ERROR: go build failed"; exit 1; }

echo "[STEP 6/7] Running go vet ./..."
GOWORK=off go vet ./... 2>&1 || { echo "ERROR: go vet failed"; exit 1; }

echo "[STEP 6/7] Done"

# ---------------------------------------------------------------------------
# Step 7: git diff + post-change verification
# ---------------------------------------------------------------------------
echo "[STEP 7/7] Git diff output..."
echo ""
echo "--- Changed files ---"
git diff --stat origin/main
echo ""
echo "--- module path in go.mod ---"
grep -n "ZoneCNH" go.mod
echo ""

# Check no xlib-standard residue remains
echo "--- Checking for remaining ${OLD_NAME} references ---"
if grep -rn "$OLD_NAME" --include="*.go" --include="*.mod" . 2>/dev/null | grep -v "\.git\|migrate"; then
    echo "WARNING: Found remaining ${OLD_NAME} references"
    RESIDUE_COUNT=$(grep -rn "$OLD_NAME" --include="*.go" --include="*.mod" . 2>/dev/null | grep -v "\.git\|migrate" | wc -l)
    echo "  Count: ${RESIDUE_COUNT}"
else
    echo "  OK - no residue"
fi

# ---------------------------------------------------------------------------
# Validation summary
# ---------------------------------------------------------------------------
echo "========================================="
echo "  Validation: ${MODULE} (SPECIAL CASE)"
echo "========================================="
echo "--- go build ./... ---"
GOWORK=off go build ./... 2>&1 || echo "BUILD FAILED"
echo ""
echo "--- go vet ./... ---"
GOWORK=off go vet ./... 2>&1 || echo "VET FAILED"
echo ""
echo "--- git diff --stat origin/main ---"
git diff --stat origin/main
echo ""
echo "--- Module path ---"
grep -rn "ZoneCNH" go.mod
echo ""
echo "========================================="
echo "  Migration complete: ${OLD_NAME} → ${NEW_NAME}"
echo "  Branch: ${BRANCH}"
echo "  Review with: git diff origin/main"
echo "  NOTE: go.sum has been regenerated by go mod tidy"
echo "========================================="
