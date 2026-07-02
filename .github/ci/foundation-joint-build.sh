#!/usr/bin/env bash
set -euo pipefail

FOUNDATION_MODULES=("kernel" "configx" "observex" "resiliencx" "schedulex" "testkitx")
WORKDIR="/tmp/foundation-joint"
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

echo "── Cloning all foundation modules ──"
for mod in "${FOUNDATION_MODULES[@]}"; do
    echo "  cloning $mod ..."
    git clone --depth=1 "https://github.com/ZoneCNH/${mod}.git" "$WORKDIR/$mod" 2>/dev/null || {
        echo "  WARNING: Cannot clone $mod (repo may not exist yet on GitHub)"
        continue
    }
done

echo ""
echo "── Creating go.work ──"
cd "$WORKDIR"
go work init 2>/dev/null || true

added_modules=0
for mod in "${FOUNDATION_MODULES[@]}"; do
    if [ -d "$mod" ] && [ -f "$mod/go.mod" ]; then
        if go work use "./$mod" 2>/dev/null; then
            echo "  added: $mod"
            added_modules=$((added_modules + 1))
        else
            echo "  skip: $mod (go.work add failed)"
        fi
    fi
done

if [ "$added_modules" -eq 0 ]; then
    echo "  ERROR: no cloneable Go modules were added to go.work"
    exit 1
fi

echo ""
echo "── Building all modules jointly ──"
for mod in "${FOUNDATION_MODULES[@]}"; do
    if [ -d "$mod" ] && [ -f "$mod/go.mod" ]; then
        echo "  building $mod ..."
        (cd "$mod" && go build ./...) || {
            echo "  BUILD FAIL in $mod (check module compatibility and dependencies)"
            exit 1
        }
    fi
done
echo "  BUILD PASS"

echo ""
echo "── Running all tests ──"
for mod in "${FOUNDATION_MODULES[@]}"; do
    if [ -d "$mod" ] && [ -f "$mod/go.mod" ]; then
        echo "  testing $mod ..."
        (cd "$mod" && go test -count=1 ./...) || {
            echo "  TEST FAIL in $mod (check individual module CI for details)"
            exit 1
        }
    fi
done
echo "  TEST PASS"

echo ""
echo "── Joint Build and Test PASS ──"
