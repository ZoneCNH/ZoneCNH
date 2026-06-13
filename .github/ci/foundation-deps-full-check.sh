#!/usr/bin/env bash
set -euo pipefail

FOUNDATION_MODULES=("kernel" "configx" "observex" "resiliencx" "schedulex" "testkitx" "xlib-standard" "xlibgate")
WORKDIR="/tmp/foundation-deps-check"
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

PASS=0
FAIL=0
SKIP=0

for mod in "${FOUNDATION_MODULES[@]}"; do
    echo "── Checking $mod ──"
    repo_url="https://github.com/ZoneCNH/${mod}.git"
    clone_dir="$WORKDIR/$mod"

    if ! git clone --depth=1 "$repo_url" "$clone_dir" 2>/dev/null; then
        echo "  SKIP: Cannot clone $mod"
        SKIP=$((SKIP + 1))
        continue
    fi

    gomod="$clone_dir/go.mod"
    if [ ! -f "$gomod" ]; then
        echo "  SKIP: No go.mod found"
        SKIP=$((SKIP + 1))
        continue
    fi

    # Check Go version
    go_ver=$(head -3 "$gomod" | grep "^go " | awk '{print $2}' || echo "unknown")
    if [ "$go_ver" != "1.23" ]; then
        echo "  WARN: go $go_ver (baseline: 1.23)"
    else
        echo "  OK: go $go_ver"
    fi

    # Run boundary check if Makefile target exists
    if grep -q "^boundary:" "$clone_dir/Makefile" 2>/dev/null; then
        (cd "$clone_dir" && make boundary 2>&1 | tail -5) || {
            echo "  FAIL: boundary check failed for $mod"
            FAIL=$((FAIL + 1))
            continue
        }
    fi

    # Run secret scan if script exists
    if [ -x "$clone_dir/scripts/check_secrets.sh" ]; then
        (cd "$clone_dir" && bash scripts/check_secrets.sh 2>&1 | tail -3) || {
            echo "  FAIL: secret scan failed for $mod"
            FAIL=$((FAIL + 1))
            continue
        }
    fi

    echo "  PASS: $mod"
    PASS=$((PASS + 1))
done

echo ""
echo "── Foundation Deps Matrix Summary ──"
echo "PASS: $PASS  FAIL: $FAIL  SKIP: $SKIP"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
