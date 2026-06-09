#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/goal-self-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

PASS=0
FAIL=0

safe_name() {
  printf '%s' "$1" | tr -c 'A-Za-z0-9_' '_'
}

output_path() {
  printf '%s/%s.out' "$TMP_ROOT" "$(safe_name "$1")"
}

record_pass() {
  printf 'PASS %s\n' "$1"
  PASS=$((PASS + 1))
}

record_fail() {
  local label="$1"
  local out="$2"

  printf 'FAIL %s\n' "$label"
  if [[ -s "$out" ]]; then
    sed -n '1,80p' "$out"
  fi
  FAIL=$((FAIL + 1))
}

run_success() {
  local label="$1"
  shift
  local out
  out="$(output_path "$label")"

  if "$@" >"$out" 2>&1; then
    record_pass "$label"
  else
    record_fail "$label" "$out"
  fi
}

run_failure() {
  local label="$1"
  shift
  local out
  out="$(output_path "$label")"

  if "$@" >"$out" 2>&1; then
    printf 'FAIL %s\nexpected command to fail, but it passed\n' "$label"
    FAIL=$((FAIL + 1))
  else
    record_pass "$label"
  fi
}

for script in "$SCRIPT_DIR"/*.sh; do
  run_success "shell syntax $(basename "$script")" bash -n "$script"
done

run_success "python compile" \
  python3 -m py_compile "$SCRIPT_DIR/matrix-gen.py" "$SCRIPT_DIR/rule-drift-check.py"
run_success "goal lint baseline" bash "$SCRIPT_DIR/lint-goal.sh" "$REPO_ROOT/docs/goal"
run_success "rule drift baseline" python3 "$SCRIPT_DIR/rule-drift-check.py" --root "$REPO_ROOT" --quiet
run_success "matrix baseline" python3 "$SCRIPT_DIR/matrix-gen.py" \
  --check-only --matrix "$REPO_ROOT/.config/goal/matrix/matrix.yaml"
run_success "gate baseline" bash "$SCRIPT_DIR/gate-check.sh" "$REPO_ROOT"

bad_matrix="$TMP_ROOT/bad-matrix.yaml"
cat >"$bad_matrix" <<'YAML'
matrix:
  - source_id: GOAL-20260608-001
    target_id: TASK-GOAL-20260608-001-999
    relation: invalid_relation
    status: Verified
    evidence_id: ""
    gate_id: G7
    owner: goal-matrix
    updated_at: 2026-06-09
YAML
run_failure "matrix rejects invalid relation and missing evidence" \
  python3 "$SCRIPT_DIR/matrix-gen.py" --check-only --matrix "$bad_matrix"

drift_root="$TMP_ROOT/drift-root"
mkdir -p "$drift_root/.config" "$drift_root/docs/goal" "$drift_root/.github/workflows"
cp -R "$REPO_ROOT/.config/goal" "$drift_root/.config/"
cp -R "$SCRIPT_DIR" "$drift_root/docs/goal/tools"
cp "$REPO_ROOT/.github/workflows/goal-ci.yml" "$drift_root/.github/workflows/goal-ci.yml"
stale_literal="current""_state"
printf '\n# stale fixture: %s\n' "$stale_literal" >>"$drift_root/docs/goal/tools/lint-goal.sh"
run_failure "rule drift rejects stale state literals" \
  python3 "$drift_root/docs/goal/tools/rule-drift-check.py" --root "$drift_root" --quiet

gate_root="$TMP_ROOT/gate-root"
mkdir -p "$gate_root/.config/goal/registry" "$gate_root/.config/goal/matrix" \
  "$gate_root/.config/goal/evidence" "$gate_root/tests"
printf 'def test_fixture():\n    assert True\n' >"$gate_root/tests/test_fixture.py"
cat >"$gate_root/.config/goal/registry/tasks.yaml" <<'YAML'
tasks:
  - task_id: TASK-GOAL-20260608-001-999
    goal_id: GOAL-20260608-001
YAML
cat >"$gate_root/.config/goal/matrix/matrix.yaml" <<'YAML'
matrix:
  - source_id: TASK-GOAL-20260608-001-999
    target_id: EVID-TEST-TASK-GOAL-20260608-001-999-001-001-001
    relation: evidenced_by
    status: Verified
    evidence_id: EVID-TEST-TASK-GOAL-20260608-001-999-001-001-001
    gate_id: G8
    owner: goal-matrix
    updated_at: 2026-06-09
YAML
run_failure "gate rejects missing DoD evidence files" bash "$SCRIPT_DIR/gate-check.sh" "$gate_root"

printf '\nself-test summary: PASS=%s FAIL=%s\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
