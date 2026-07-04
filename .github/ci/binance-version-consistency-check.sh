#!/usr/bin/env bash
# binance-version-consistency-check.sh — 校验 Runtime-Version / Spec-Version 一致性

set -euo pipefail

SCRIPT_TIMEOUT_SECONDS="${SCRIPT_TIMEOUT_SECONDS:-120}"
if ! [[ "$SCRIPT_TIMEOUT_SECONDS" =~ ^[0-9]+$ ]] || [ "$SCRIPT_TIMEOUT_SECONDS" -le 0 ]; then
  echo "FAIL: SCRIPT_TIMEOUT_SECONDS must be a positive integer" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BINANCE_DIR="$REPO_ROOT/module/binance"

FAIL=0

fail() {
  echo "FAIL: $*"
  FAIL=1
}

extract_first_semver() {
  local file="$1"
  local prefix="$2"
  awk -v key="$prefix" '
    index($0, key) == 1 {
      if (match($0, /v[0-9]+\.[0-9]+\.[0-9]+/)) {
        print substr($0, RSTART, RLENGTH)
        exit
      }
    }
  ' "$file"
}

extract_table_value() {
  local file="$1"
  local key="$2"
  awk -F'|' -v key="$key" '
    {
      left=$2
      right=$3
      gsub(/^[ \t]+|[ \t]+$/, "", left)
      gsub(/^[ \t]+|[ \t]+$/, "", right)
      if (left == key) {
        if (match(right, /v[0-9]+\.[0-9]+\.[0-9]+/)) {
          print substr(right, RSTART, RLENGTH)
          exit
        }
      }
    }
  ' "$file"
}

assert_eq() {
  local label="$1"
  local expected="$2"
  local actual="$3"
  if [ -z "$actual" ]; then
    fail "$label missing"
    return
  fi
  if [ "$expected" != "$actual" ]; then
    fail "$label expected $expected got $actual"
  fi
}

for rel in \
  "spec/SPEC.md" \
  "README.md" \
  "spec/client/SPEC.md" \
  "spec/server/SPEC.md" \
  "goal/goal.md" \
  "deploy/README.md" \
  "deploy/DEPLOY.md" \
  "matrix/TRACEABILITY.md" \
  "matrix/client/TRACEABILITY.md" \
  "matrix/server/TRACEABILITY.md" \
  "gate/BOUNDARY-GATES.md" \
  "plan/PLAN.md" \
  "design/CONFIG-SCHEMA.md" \
  "CHANGELOG.md"; do
  if [ ! -f "$BINANCE_DIR/$rel" ]; then
    fail "required file missing: module/binance/$rel"
  fi
done

if [ "$FAIL" -ne 0 ]; then
  exit 1
fi

SPEC_FILE="$BINANCE_DIR/spec/SPEC.md"
spec_version="$(extract_first_semver "$SPEC_FILE" "- Spec-Version:")"
runtime_version="$(extract_first_semver "$SPEC_FILE" "- Runtime-Version:")"

if [ -z "$spec_version" ]; then
  fail "module/binance/spec/SPEC.md missing Spec-Version"
fi
if [ -z "$runtime_version" ]; then
  fail "module/binance/spec/SPEC.md missing Runtime-Version"
fi

if [ "$FAIL" -ne 0 ]; then
  exit 1
fi

echo "Canonical Spec-Version: $spec_version"
echo "Canonical Runtime-Version: $runtime_version"

assert_eq "README Spec-Version" "$spec_version" \
  "$(extract_first_semver "$BINANCE_DIR/README.md" "- Spec-Version:")"
assert_eq "README Runtime-Version" "$runtime_version" \
  "$(extract_first_semver "$BINANCE_DIR/README.md" "- Runtime-Version:")"

assert_eq "client SPEC Spec-Version" "$spec_version" \
  "$(extract_first_semver "$BINANCE_DIR/spec/client/SPEC.md" "- Spec-Version:")"
assert_eq "client SPEC Runtime-Version" "$runtime_version" \
  "$(extract_first_semver "$BINANCE_DIR/spec/client/SPEC.md" "- Runtime-Version:")"

assert_eq "server SPEC Spec-Version" "$spec_version" \
  "$(extract_table_value "$BINANCE_DIR/spec/server/SPEC.md" "Spec-Version")"
assert_eq "server SPEC Runtime-Version" "$runtime_version" \
  "$(extract_table_value "$BINANCE_DIR/spec/server/SPEC.md" "Runtime-Version")"

assert_eq "goal 当前版本" "$runtime_version" \
  "$(extract_table_value "$BINANCE_DIR/goal/goal.md" "当前版本")"
assert_eq "goal Spec 版本" "$spec_version" \
  "$(extract_table_value "$BINANCE_DIR/goal/goal.md" "Spec 版本")"

assert_eq "deploy README Spec-Version" "$spec_version" \
  "$(extract_first_semver "$BINANCE_DIR/deploy/README.md" "- Spec-Version:")"
assert_eq "deploy README Runtime-Version" "$runtime_version" \
  "$(extract_first_semver "$BINANCE_DIR/deploy/README.md" "- Runtime-Version:")"
assert_eq "deploy DEPLOY Runtime-Version" "$runtime_version" \
  "$(extract_first_semver "$BINANCE_DIR/deploy/DEPLOY.md" "- Runtime-Version:")"

assert_eq "root TRACEABILITY Matrix-Version" "$spec_version" \
  "$(extract_first_semver "$BINANCE_DIR/matrix/TRACEABILITY.md" "- [KNOWN] Matrix-Version:")"
assert_eq "root TRACEABILITY Source-SPEC" "$spec_version" \
  "$(extract_first_semver "$BINANCE_DIR/matrix/TRACEABILITY.md" "- Source-SPEC:")"

assert_eq "client TRACEABILITY Module-Version" "$spec_version" \
  "$(extract_first_semver "$BINANCE_DIR/matrix/client/TRACEABILITY.md" "- Module-Version:")"
assert_eq "client TRACEABILITY Spec-Reference" "$spec_version" \
  "$(extract_first_semver "$BINANCE_DIR/matrix/client/TRACEABILITY.md" "- Spec-Reference:")"

assert_eq "server TRACEABILITY Module-Version" "$spec_version" \
  "$(extract_first_semver "$BINANCE_DIR/matrix/server/TRACEABILITY.md" "- Module-Version:")"
assert_eq "server TRACEABILITY Spec-Reference" "$spec_version" \
  "$(extract_first_semver "$BINANCE_DIR/matrix/server/TRACEABILITY.md" "- Spec-Reference:")"

assert_eq "BOUNDARY-GATES Module-Version" "$spec_version" \
  "$(extract_first_semver "$BINANCE_DIR/gate/BOUNDARY-GATES.md" "> Module-Version:")"
assert_eq "PLAN Module-Version" "$spec_version" \
  "$(extract_first_semver "$BINANCE_DIR/plan/PLAN.md" "- Module-Version:")"
assert_eq "CONFIG-SCHEMA Source-SPEC" "$spec_version" \
  "$(extract_first_semver "$BINANCE_DIR/design/CONFIG-SCHEMA.md" "- Source-SPEC:")"
assert_eq "CHANGELOG Spec-Reference" "$spec_version" \
  "$(extract_first_semver "$BINANCE_DIR/CHANGELOG.md" "- Spec-Reference:")"

stale_hits=$(
  grep -REn --include='*.md' \
    '^(- Runtime-Version: v0\.(8\.0|11\.0)|- Spec-Version: v3\.9\.(0|6)|- Spec-Reference: .* v3\.9\.(0|6))' \
    "$BINANCE_DIR" \
    --exclude='CHANGELOG.md' \
    --exclude='SPEC.md' \
    --exclude-dir='evidence' || true
)

if [ -n "$stale_hits" ]; then
  fail "stale version metadata detected outside historical exceptions"
  echo "$stale_hits"
fi

if [ "$FAIL" -ne 0 ]; then
  echo "Result: FAIL"
  exit 1
fi

echo "Result: PASS"
