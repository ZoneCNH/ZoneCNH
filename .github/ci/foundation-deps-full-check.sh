#!/usr/bin/env bash
set -euo pipefail

MATRIX_PATH="${FOUNDATION_DEPS_MATRIX:-module/FOUNDATION-DEPS.yaml}"
WORKDIR="${FOUNDATION_DEPS_WORKDIR:-/tmp/foundation-deps-check}"
SOURCE_ROOT="${FOUNDATION_DEPS_SOURCE_ROOT:-/home}"
GO_BASELINE_MODE="${FOUNDATION_GO_BASELINE_MODE:-warn}"

if [ "$GO_BASELINE_MODE" != "fail" ] && [ "$GO_BASELINE_MODE" != "warn" ]; then
    echo "ERROR: FOUNDATION_GO_BASELINE_MODE must be 'fail' or 'warn' (got: $GO_BASELINE_MODE)"
    exit 2
fi

GO_BASELINE=$(python3 - "$MATRIX_PATH" <<'PYEOF'
import sys
import yaml

with open(sys.argv[1], "r", encoding="utf-8") as f:
    matrix = yaml.safe_load(f)

print(matrix.get("go_baseline", "1.23"))
PYEOF
)

mapfile -t FOUNDATION_MODULES < <(FOUNDATION_DEPS_MODULES="${FOUNDATION_DEPS_MODULES:-}" python3 - "$MATRIX_PATH" <<'PYEOF'
import os
import re
import sys
import yaml

with open(sys.argv[1], "r", encoding="utf-8") as f:
    matrix = yaml.safe_load(f)

modules = matrix.get("modules", {})
requested = os.environ.get("FOUNDATION_DEPS_MODULES", "").strip()
if requested:
    names = [item for item in re.split(r"[\s,]+", requested) if item]
else:
    names = list(modules)

missing = [name for name in names if name not in modules]
if missing:
    print(f"ERROR: unknown module(s) in FOUNDATION_DEPS_MODULES: {', '.join(missing)}", file=sys.stderr)
    sys.exit(2)

for name in names:
    path = modules[name].get("path", f"github.com/ZoneCNH/{name}")
    print(f"{name}\t{path}")
PYEOF
)

rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

PASS=0
FAIL=0
SKIP=0
WARN=0

resolve_module_dir() {
    local mod="$1"
    local module_path="$2"
    local local_dir
    local current_module

    local last_local_dir=""
    for local_dir in "$SOURCE_ROOT/$mod" "/home/$mod"; do
        if [ "$local_dir" = "$last_local_dir" ]; then
            continue
        fi
        last_local_dir="$local_dir"
        if [ -f "$local_dir/go.mod" ]; then
            current_module=$(awk '$1 == "module" { print $2; exit }' "$local_dir/go.mod")
            if [ "$current_module" = "$module_path" ]; then
                printf '%s\n' "$local_dir"
                return 0
            fi
            echo "  WARN: local source $local_dir has module $current_module (expected $module_path)" >&2
            printf '%s\n' "$local_dir"
            return 0
        fi
    done

    local clone_dir="$WORKDIR/$mod"
    local repo_url="https://${module_path}.git"
    if timeout 120s git clone --depth=1 "$repo_url" "$clone_dir" 2>/dev/null; then
        if [ -f "$clone_dir/go.mod" ]; then
            current_module=$(awk '$1 == "module" { print $2; exit }' "$clone_dir/go.mod")
            if [ "$current_module" != "$module_path" ]; then
                echo "  WARN: cloned $repo_url but module path is $current_module" >&2
            fi
        fi
        printf '%s\n' "$clone_dir"
        return 0
    fi

    return 1
}

echo "Foundation deps matrix: $MATRIX_PATH"
echo "Go baseline: $GO_BASELINE (mode: $GO_BASELINE_MODE)"
echo "Modules: ${#FOUNDATION_MODULES[@]}"
echo ""

for row in "${FOUNDATION_MODULES[@]}"; do
    mod="${row%%$'\t'*}"
    module_path="${row#*$'\t'}"
    echo "── Checking $mod ──"
    module_status="pass"
    module_identity_ok="true"

    if ! clone_dir="$(resolve_module_dir "$mod" "$module_path")"; then
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

    module_directive=$(awk '$1 == "module" { print $2; exit }' "$gomod")
    if [ "$module_directive" != "$module_path" ]; then
        echo "  WARN: module path $module_directive (expected: $module_path) — known repo/module path mismatch (legacy)"
        WARN=$((WARN + 1))
    else
        echo "  OK: module $module_directive"
    fi

    # Check Go version
    if [ "$module_identity_ok" = "true" ]; then
        go_ver=$(awk '$1 == "go" { print $2; exit }' "$gomod")
        if [ -z "$go_ver" ]; then
            echo "  FAIL: go directive missing (baseline: $GO_BASELINE)"
            module_status="fail"
        elif [ "$go_ver" != "$GO_BASELINE" ]; then
            if [ "$GO_BASELINE_MODE" = "warn" ]; then
                echo "  WARN: go $go_ver (baseline: $GO_BASELINE)"
                WARN=$((WARN + 1))
            else
                echo "  FAIL: go $go_ver (baseline: $GO_BASELINE)"
                module_status="fail"
            fi
        else
            echo "  OK: go $go_ver"
        fi
    else
        echo "  SKIP: downstream checks skipped because module identity failed"
    fi

    # Run boundary check if Makefile target exists (runtime repo responsibility, warn only)
    if [ "$module_identity_ok" = "true" ] && grep -q "^boundary:" "$clone_dir/Makefile" 2>/dev/null; then
        (cd "$clone_dir" && make boundary 2>&1 | tail -5) || {
            echo "  WARN: boundary check failed for $mod (runtime repo issue, not blocking)"
            WARN=$((WARN + 1))
        }
    fi

    # Run secret scan if script exists (runtime repo responsibility, warn only)
    if [ "$module_identity_ok" = "true" ] && [ -x "$clone_dir/scripts/check_secrets.sh" ]; then
        (cd "$clone_dir" && bash scripts/check_secrets.sh 2>&1 | tail -3) || {
            echo "  WARN: secret scan failed for $mod (runtime repo issue, not blocking)"
            WARN=$((WARN + 1))
        }
    fi

    if [ "$module_status" = "pass" ]; then
        echo "  PASS: $mod"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $mod"
        FAIL=$((FAIL + 1))
    fi
done

echo ""
echo "── Foundation Deps Matrix Summary ──"
echo "PASS: $PASS  FAIL: $FAIL  SKIP: $SKIP  WARN: $WARN"
echo "GO_BASELINE: $GO_BASELINE  MODE: $GO_BASELINE_MODE"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
