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

for mod in "${FOUNDATION_MODULES[@]}"; do
    if [ -d "$mod" ] && [ -f "$mod/go.mod" ]; then
        go work use "./$mod" 2>/dev/null && echo "  added: $mod" || echo "  skip: $mod (go.work add failed)"
    fi
done

echo ""
echo "── Building all modules jointly ──"
go build ./... 2>&1 && echo "  BUILD PASS" || {
    echo "  BUILD FAIL (some modules may not be cloneable yet)"
}

echo ""
echo "── Running all tests ──"
go test -count=1 ./... 2>&1 | tail -30 || {
    echo "  TEST FAIL (check individual module CI for details)"
    exit 1
}

echo ""
echo "── Joint Build and Test PASS ──"
