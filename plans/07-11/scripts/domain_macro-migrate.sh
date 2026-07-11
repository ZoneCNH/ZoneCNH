#!/bin/bash
# =============================================================================
# domain_macro 迁移脚本: domain-macro → domain_macro (kebab→snake_case)
# =============================================================================
set -euo pipefail

MODULE="domain_macro"
MODULE_DIR="/home/workspace/${MODULE}"
OLD_MODULE_PATH="github.com/xhyperium/domain-macro"
NEW_MODULE_PATH="github.com/xhyperium/domain_macro"
OLD_NAME="domain-macro"
NEW_NAME="domain_macro"
BRANCH="fix/snake-case-migration"

# ---------------------------------------------------------------------------
# DRY_RUN mode
# ---------------------------------------------------------------------------
DRY_RUN="${DRY_RUN:-0}"
if [ "$DRY_RUN" = "1" ]; then
    echo "[DRY_RUN] Would migrate ${MODULE}: ${OLD_NAME} → ${NEW_NAME}"
    echo "[DRY_RUN] Branch: ${BRANCH} from origin/main"
    echo "[DRY_RUN] go.mod: ${OLD_MODULE_PATH} → ${NEW_MODULE_PATH}"
    exit 0
fi

echo "========================================="
echo "  Migration: ${OLD_NAME} → ${NEW_NAME}"
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

# Check if on clean main checkout
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "WARNING: Current branch is '${CURRENT_BRANCH}', not 'main'."
    echo "Migration should start from a clean main checkout."
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
# Step 2: Fix go.mod
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
        sed -i "s|${OLD_MODULE_PATH}|${NEW_MODULE_PATH}|g" "$f"
    done
fi
echo "[STEP 3/7] Done (processed .go files)"

# ---------------------------------------------------------------------------
# Step 4: Fix documentation references
# ---------------------------------------------------------------------------
echo "[STEP 4/7] Fixing documentation references..."
# Fix in markdown, yaml, yml, toml files
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
# Step 6: go mod tidy + build verification
# ---------------------------------------------------------------------------
echo "[STEP 6/7] Running go mod tidy..."
go mod tidy 2>&1 || { echo "ERROR: go mod tidy failed"; exit 1; }

echo "[STEP 6/7] Running go build ./..."
GOWORK=off go build ./... 2>&1 || { echo "ERROR: go build failed"; exit 1; }

echo "[STEP 6/7] Running go vet ./..."
GOWORK=off go vet ./... 2>&1 || { echo "ERROR: go vet failed"; exit 1; }

echo "[STEP 6/7] Done"

# ---------------------------------------------------------------------------
# Step 7: git diff output
# ---------------------------------------------------------------------------
echo "[STEP 7/7] Git diff output..."
echo ""
echo "--- Changed files ---"
git diff --stat origin/main
echo ""
echo "--- module path in go.mod ---"
grep -n "ZoneCNH" go.mod
echo ""

# ---------------------------------------------------------------------------
# Validation summary
# ---------------------------------------------------------------------------
echo "========================================="
echo "  Validation: ${MODULE}"
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
echo "========================================="
