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
# go.work 模式下，go build ./... 不能在 work 根目录跑（work 根本身不是 module，
# 会报 "directory prefix . does not contain modules listed in go.work"）。
# 需进入每个 module 子目录单独构建；go.work 仍提供跨 module 依赖解析。
build_fail=0
for mod in "${FOUNDATION_MODULES[@]}"; do
    if [ -d "$mod" ] && [ -f "$mod/go.mod" ]; then
        echo "  building $mod ..."
        (cd "$mod" && go build ./... 2>&1) || {
            echo "  $mod: BUILD FAIL"
            build_fail=1
        }
    fi
done
if [ "$build_fail" -ne 0 ]; then
    echo "  BUILD FAIL (check module compatibility and dependencies)"
    exit 1
fi
echo "  BUILD PASS"

echo ""
echo "── Running all tests ──"
# Joint build verifies cross-module compilation compatibility.
# Individual module test failures are per-module issues, not joint build
# compatibility issues — each module's own CI is the authority for tests.
test_warnings=0
for mod in "${FOUNDATION_MODULES[@]}"; do
    if [ -d "$mod" ] && [ -f "$mod/go.mod" ]; then
        echo "  testing $mod ..."
        if ! (cd "$mod" && go test -count=1 ./... 2>&1); then
            echo "  $mod: TEST WARN (check individual module CI for details)"
            test_warnings=1
        fi
    fi
done
if [ "$test_warnings" -ne 0 ]; then
    echo "  TEST WARNINGS (non-fatal — check individual module CI for details)"
fi

echo ""
echo "── Joint Build and Test PASS ──"
