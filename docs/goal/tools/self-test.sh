#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/goal-self-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

PASS=0
FAIL=0
VALIDATOR_RISK_ID="RISK-GOAL-20260608-001-001"
VALIDATOR_EVIDENCE_ID="EVID-TEST-TASK-GOAL-20260608-001-001-001-001"

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

run_failure_contains() {
  local label="$1"
  local pattern="$2"
  shift 2
  local out
  out="$(output_path "$label")"

  if "$@" >"$out" 2>&1; then
    printf 'FAIL %s\nexpected command to fail, but it passed\n' "$label"
    FAIL=$((FAIL + 1))
  elif grep -q "$pattern" "$out"; then
    record_pass "$label"
  else
    printf 'FAIL %s\nexpected output to contain: %s\n' "$label" "$pattern"
    if [[ -s "$out" ]]; then
      sed -n '1,80p' "$out"
    fi
    FAIL=$((FAIL + 1))
  fi
}

toolchain_fallback="$TMP_ROOT/toolchain-fallback"
mkdir -p "$toolchain_fallback"
run_success "setup-ci-toolchain supports pip target fallback without venv" \
  env \
    RUNNER_TOOL_CACHE="$toolchain_fallback/tool-cache" \
    AGENT_TOOLSDIRECTORY="$toolchain_fallback/tool-cache" \
    GOAL_CI_FORCE_TARGET_INSTALL=1 \
    GOAL_CI_PYTHON_TARGET="$toolchain_fallback/python" \
    GOAL_CI_BIN_DIR="$toolchain_fallback/bin" \
    GITHUB_PATH="$toolchain_fallback/github_path" \
    GITHUB_ENV="$toolchain_fallback/github_env" \
    bash "$SCRIPT_DIR/setup-ci-toolchain.sh"
run_success "setup-ci-toolchain fallback imports Python deps" \
  env \
    PYTHONPATH="$toolchain_fallback/python" \
    PATH="$toolchain_fallback/bin:$PATH" \
    python3 -c "import yaml, yamllint"
run_success "setup-ci-toolchain fallback exposes yamllint wrapper" \
  env \
    PYTHONPATH="$toolchain_fallback/python" \
    PATH="$toolchain_fallback/bin:$PATH" \
    yamllint --version
run_success "goal-delivery create help lists create command" \
  bash -c '"$1" create --help | grep -q "^  create[[:space:]]"' _ "$SCRIPT_DIR/goal-delivery.sh"

write_validator_gates() {
  local root="$1"
  local with_risk="$2"
  local g10_status="$3"
  local g11_status="$4"
  local pending_gate="${5:-}"
  local risk_id="${6:-$VALIDATOR_RISK_ID}"
  local gates="$root/.config/goal/gates/state.yaml"
  local i gate status verdict

  mkdir -p "$(dirname "$gates")"
  {
    printf 'gates:\n'
    for i in $(seq 0 11); do
      gate="G$i"
      status="PASS"
      verdict="PASS"
      if [[ "$gate" == "G10" ]]; then
        status="$g10_status"
        verdict="$g10_status"
      fi
      if [[ "$gate" == "G11" ]]; then
        status="$g11_status"
        verdict="$g11_status"
      fi
      if [[ "$with_risk" == "true" && "$gate" == "G2" ]]; then
        status="PASS_WITH_RISK"
        verdict="PASS_WITH_RISK"
      fi
      if [[ -n "$pending_gate" && "$gate" == "$pending_gate" ]]; then
        status="PENDING"
        verdict="PENDING"
      fi

      printf '  %s:\n' "$gate"
      printf '    status: %s\n' "$status"
      printf '    owner: goal-reviewer\n'
      printf '    updated_at: 2026-06-09\n'
      if [[ "$with_risk" == "true" && "$gate" == "G2" ]]; then
        printf '    allow_pass_with_risk: true\n'
        cat <<YAML
    risk:
      risk_id: $risk_id
      risk_owner: goal-reviewer
      risk_level: medium
      risk_reason: fixture
      mitigation: close fixture risk
      due_at: "2026-06-10T00:00:00Z"
      review_gate: G10
      release_blocking: true
      evidence_id: $VALIDATOR_EVIDENCE_ID
      status: OPEN
YAML
      fi
      printf '    result:\n'
      printf '      verdict: %s\n' "$verdict"
      printf '      score: 100\n'
      printf '      details: fixture\n'
    done
  } >"$gates"
}

write_validator_fixture() {
  local root="$1"
  local with_risk="$2"
  local registry_has_risk="$3"
  local g10_status="$4"
  local g11_status="$5"
  local pipeline_state="$6"
  local release_status="$7"
  local workflow_stale="$8"
  local matrix_legacy="$9"
  local pending_gate="${10:-}"
  local gitignore_mode="${11:-good}"
  local risk_id="${12:-$VALIDATOR_RISK_ID}"

  mkdir -p "$root/.config/goal/matrix" "$root/.config/goal/registry" \
    "$root/.config/goal/pipeline" "$root/.config/goal/schema" "$root/.github/workflows"

  case "$gitignore_mode" in
    good)
      cat >"$root/.gitignore" <<'GITIGNORE'
.config/*
!.config/goal/
!.config/goal/**
.config/cache/
GITIGNORE
      ;;
    missing_cache)
      cat >"$root/.gitignore" <<'GITIGNORE'
.config/*
!.config/goal/
!.config/goal/**
GITIGNORE
      ;;
    old_runtime)
      cat >"$root/.gitignore" <<'GITIGNORE'
.config/*
!.config/goal/
!.config/goal/**
.config/cache/
.config/goal/runtime/
GITIGNORE
      ;;
  esac

  cat >"$root/.config/goal/registry/goals.yaml" <<'YAML'
goals: []
YAML
  cat >"$root/.config/goal/registry/tasks.yaml" <<'YAML'
tasks: []
YAML
  cat >"$root/.config/goal/registry/issues.yaml" <<'YAML'
issues: []
YAML
  cat >"$root/.config/goal/registry/decisions.yaml" <<'YAML'
decisions: []
YAML

  if [[ "$matrix_legacy" == "true" ]]; then
    cat >"$root/.config/goal/matrix/matrix.yaml" <<'YAML'
matrix:
  - requirement_id: REQ-GOAL-20260608-001-001
    target_id: TASK-GOAL-20260608-001-001
    relation: implements
    status: Verified
    evidence_ids: []
    gate_id: G2
    owner: goal-matrix
    updated_at: 2026-06-09
YAML
  else
    cat >"$root/.config/goal/matrix/matrix.yaml" <<YAML
matrix:
  - source_id: GOAL-20260608-001
    target_id: TASK-GOAL-20260608-001-001
    relation: decomposes_to
    status: Verified
    evidence_id: $VALIDATOR_EVIDENCE_ID
    gate_id: G1
    owner: goal-matrix
    updated_at: 2026-06-09
YAML
  fi

  write_validator_gates "$root" "$with_risk" "$g10_status" "$g11_status" "$pending_gate" "$risk_id"

  if [[ "$registry_has_risk" == "true" ]]; then
    cat >"$root/.config/goal/registry/risks.yaml" <<YAML
risks:
  - risk_id: $risk_id
    status: Open
    release_blocking: true
    owner: goal-reviewer
YAML
  else
    printf 'risks: []\n' >"$root/.config/goal/registry/risks.yaml"
  fi

  cat >"$root/.config/goal/pipeline/state.yaml" <<YAML
pipeline:
  - goal_id: GOAL-20260608-001
    pipeline_state: $pipeline_state
YAML

  cat >"$root/.config/goal/registry/releases.yaml" <<YAML
releases:
  - release_id: REL-20260608-goal-system
    status: $release_status
YAML

  if [[ "$workflow_stale" == "true" ]]; then
    cat >"$root/.github/workflows/goal-ci.yml" <<'YAML'
name: Goal fixture
on: [push]
env:
  GOAL_CI_RUNNER_CLASS: self-hosted
  RUNNER_TOOL_CACHE: ${{ github.workspace }}/.goal-runner-tool-cache
  AGENT_TOOLSDIRECTORY: ${{ github.workspace }}/.goal-runner-tool-cache
jobs:
  goal-validator:
    runs-on: [self-hosted, Linux, X64, ci-governance]
    steps:
      - run: mkdir -p "$RUNNER_TOOL_CACHE" "$AGENT_TOOLSDIRECTORY"
      - run: bash docs/goal/tools/setup-ci-toolchain.sh
      - run: |
          required = ['requirement_id', 'evidence_ids']
          valid_gate_statuses = ['PASS', 'PASS_WITH_RISK', 'FAIL', 'BLOCKED', 'PENDING']
          valid_result_verdicts = ['PASS', 'PASS_WITH_RISK', 'FAIL']
  goal-toolchain-check:
    runs-on: [self-hosted, Linux, X64, ci-governance]
    steps:
      - run: mkdir -p "$RUNNER_TOOL_CACHE" "$AGENT_TOOLSDIRECTORY"
      - run: bash docs/goal/tools/setup-ci-toolchain.sh
YAML
  else
    cat >"$root/.github/workflows/goal-ci.yml" <<'YAML'
name: Goal fixture
on: [push]
env:
  GOAL_CI_RUNNER_CLASS: self-hosted
  RUNNER_TOOL_CACHE: ${{ github.workspace }}/.goal-runner-tool-cache
  AGENT_TOOLSDIRECTORY: ${{ github.workspace }}/.goal-runner-tool-cache
jobs:
  goal-validator:
    runs-on: [self-hosted, Linux, X64, ci-governance]
    steps:
      - run: mkdir -p "$RUNNER_TOOL_CACHE" "$AGENT_TOOLSDIRECTORY"
      - run: bash docs/goal/tools/setup-ci-toolchain.sh
      - run: python3 docs/goal/tools/goal-validate.py --root . --mode strict --format text
      - run: echo "source_id target_id evidence_id BLOCKED"
  goal-toolchain-check:
    runs-on: [self-hosted, Linux, X64, ci-governance]
    steps:
      - run: mkdir -p "$RUNNER_TOOL_CACHE" "$AGENT_TOOLSDIRECTORY"
      - run: bash docs/goal/tools/setup-ci-toolchain.sh
YAML
  fi

  cat >"$root/.config/goal/schema/rules.yaml" <<'YAML'
ci:
  workflow: ".github/workflows/goal-ci.yml"
  runner:
    required_labels:
      - self-hosted
      - Linux
      - X64
      - ci-governance
    accepted_runner_classes:
      - [self-hosted, Linux, X64, ci-governance]
      - [ubuntu-latest]
    required_env:
      - RUNNER_TOOL_CACHE
      - AGENT_TOOLSDIRECTORY
    toolchain_setup: "docs/goal/tools/setup-ci-toolchain.sh"
    python_dependency_isolation:
      primary: job-local-venv
      fallback: workspace-local-pip-target
      fallback_env:
        - GOAL_CI_PYTHON_TARGET
        - GOAL_CI_BIN_DIR
  required_jobs:
    - goal-validator
    - goal-toolchain-check
YAML
}

write_release_gate_fixture() {
  local root="$1"
  local with_risk="$2"
  local registry_has_risk="$3"
  local g10_status="$4"
  local g11_status="$5"
  local evidence_mode="${6:-present}"
  local pipeline_state="DONE"
  local release_status="released"

  if [[ "$with_risk" == "true" || "$registry_has_risk" == "true" || "$g10_status" != "PASS" || "$g11_status" != "PASS" ]]; then
    pipeline_state="BLOCKED"
    release_status="in_review"
  fi

  write_validator_fixture "$root" "$with_risk" "$registry_has_risk" \
    "$g10_status" "$g11_status" "$pipeline_state" "$release_status" false false "" good

  if [[ "$evidence_mode" == "present" ]]; then
    mkdir -p "$root/.config/goal/evidence/2026-06-09/TASK-GOAL-20260608-001-001"
    cat >"$root/.config/goal/evidence/2026-06-09/TASK-GOAL-20260608-001-001/$VALIDATOR_EVIDENCE_ID.md" <<'MD'
# Evidence Fixture

- **Evidence ID**: EVID-TEST-TASK-GOAL-20260608-001-001-001-001
- **Task ID**: TASK-GOAL-20260608-001-001
- **Test ID**: TEST-TASK-GOAL-20260608-001-001-001
- **Goal ID**: GOAL-20260608-001
- **Spec ID**: SPEC-GOAL-20260608-001
- **Acceptance Criteria ID**: AC-GOAL-20260608-001-001
- **Date**: 2026-06-09
- **Status**: PASS
- **Files Changed**: fixture
- **Commands Run**: self-test
MD
  fi
}

run_goal_release_gate() {
  GOAL_VALIDATOR_SCRIPT="$SCRIPT_DIR/goal-validate.py" \
    bash "$REPO_ROOT/.github/ci/goal-release-gate.sh" "$1"
}

for script in "$SCRIPT_DIR"/*.sh; do
  run_success "shell syntax $(basename "$script")" bash -n "$script"
done

run_success "python compile" \
  python3 -m py_compile "$SCRIPT_DIR/goal-validate.py" "$SCRIPT_DIR/matrix-gen.py" "$SCRIPT_DIR/rule-drift-check.py"
run_success "goal lint baseline" bash "$SCRIPT_DIR/lint-goal.sh" "$REPO_ROOT/docs/goal"
run_success "rule drift baseline" python3 "$SCRIPT_DIR/rule-drift-check.py" --root "$REPO_ROOT" --quiet
run_success "goal validator strict baseline" \
  python3 "$SCRIPT_DIR/goal-validate.py" --root "$REPO_ROOT" --mode strict --format json
run_success "goal workflow validate baseline" bash "$SCRIPT_DIR/goal-workflow.sh" validate --root "$REPO_ROOT"
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

validator_base="$TMP_ROOT/validator-base"
write_validator_fixture "$validator_base" false false PASS PASS DONE released false false "" good
run_success "goal validator strict fixture baseline" \
  python3 "$SCRIPT_DIR/goal-validate.py" --root "$validator_base" --mode strict --format text

validator_ubuntu_ci="$TMP_ROOT/validator-ubuntu-ci"
write_validator_fixture "$validator_ubuntu_ci" false false PASS PASS DONE released false false "" good
cat >"$validator_ubuntu_ci/.github/workflows/goal-ci.yml" <<'YAML'
name: Goal fixture
on: [push]
env:
  GOAL_CI_RUNNER_CLASS: ubuntu-latest
  RUNNER_TOOL_CACHE: ${{ github.workspace }}/.goal-runner-tool-cache
  AGENT_TOOLSDIRECTORY: ${{ github.workspace }}/.goal-runner-tool-cache
jobs:
  goal-validator:
    runs-on: ubuntu-latest
    steps:
      - run: mkdir -p "$RUNNER_TOOL_CACHE" "$AGENT_TOOLSDIRECTORY"
      - run: bash docs/goal/tools/setup-ci-toolchain.sh
      - run: python3 docs/goal/tools/goal-validate.py --root . --mode strict --format text
      - run: echo "source_id target_id evidence_id BLOCKED"
  goal-toolchain-check:
    runs-on: ubuntu-latest
    steps:
      - run: mkdir -p "$RUNNER_TOOL_CACHE" "$AGENT_TOOLSDIRECTORY"
      - run: bash docs/goal/tools/setup-ci-toolchain.sh
YAML
run_success "goal validator accepts ubuntu-latest runner class" \
  python3 "$SCRIPT_DIR/goal-validate.py" --root "$validator_ubuntu_ci" --mode strict --format text

validator_missing_cache="$TMP_ROOT/validator-missing-cache"
write_validator_fixture "$validator_missing_cache" false false PASS PASS DONE released false false "" missing_cache
run_failure "goal validator rejects missing runtime cache ignore" \
  python3 "$SCRIPT_DIR/goal-validate.py" --root "$validator_missing_cache" --mode strict --format text

validator_old_runtime="$TMP_ROOT/validator-old-runtime"
write_validator_fixture "$validator_old_runtime" false false PASS PASS DONE released false false "" old_runtime
run_failure "goal validator rejects old goal runtime root" \
  python3 "$SCRIPT_DIR/goal-validate.py" --root "$validator_old_runtime" --mode strict --format text

validator_legacy_matrix="$TMP_ROOT/validator-legacy-matrix"
write_validator_fixture "$validator_legacy_matrix" false false PASS PASS DONE released false true "" good
run_failure "goal validator rejects legacy matrix fields" \
  python3 "$SCRIPT_DIR/goal-validate.py" --root "$validator_legacy_matrix" --mode strict --format text

validator_pending_gate="$TMP_ROOT/validator-pending-gate"
write_validator_fixture "$validator_pending_gate" false false PASS PASS DONE released false false G3 good
run_failure "goal validator rejects pending gate status" \
  python3 "$SCRIPT_DIR/goal-validate.py" --root "$validator_pending_gate" --mode strict --format text

validator_missing_registry="$TMP_ROOT/validator-missing-registry"
write_validator_fixture "$validator_missing_registry" true false BLOCKED BLOCKED BLOCKED in_review false false "" good
run_failure "goal validator rejects missing release-blocking risk registry entry" \
  python3 "$SCRIPT_DIR/goal-validate.py" --root "$validator_missing_registry" --mode strict --format text

validator_bad_risk_id="$TMP_ROOT/validator-bad-risk-id"
write_validator_fixture "$validator_bad_risk_id" true true BLOCKED BLOCKED BLOCKED in_review false false "" good RISK-G2-BAD
run_failure_contains "goal validator rejects malformed gate risk id" "GV-GATE-RISK-ID-FORMAT" \
  python3 "$SCRIPT_DIR/goal-validate.py" --root "$validator_bad_risk_id" --mode strict --format text

validator_bad_registry_risk_id="$TMP_ROOT/validator-bad-registry-risk-id"
write_validator_fixture "$validator_bad_registry_risk_id" false true BLOCKED BLOCKED BLOCKED in_review false false "" good RISK-GOAL-BAD
run_failure_contains "goal validator rejects malformed registry risk id" "GV-RISK-ID-FORMAT" \
  python3 "$SCRIPT_DIR/goal-validate.py" --root "$validator_bad_registry_risk_id" --mode strict --format text

validator_duplicate_risk="$TMP_ROOT/validator-duplicate-risk"
write_validator_fixture "$validator_duplicate_risk" true true BLOCKED BLOCKED BLOCKED in_review false false "" good
cat >>"$validator_duplicate_risk/.config/goal/registry/risks.yaml" <<YAML
  - risk_id: $VALIDATOR_RISK_ID
    status: Open
    release_blocking: true
    owner: duplicate-fixture
YAML
run_failure_contains "goal validator rejects duplicate risk id" "GV-RISK-DUPLICATE-ID" \
  python3 "$SCRIPT_DIR/goal-validate.py" --root "$validator_duplicate_risk" --mode strict --format text

validator_duplicate_gate="$TMP_ROOT/validator-duplicate-gate"
write_validator_fixture "$validator_duplicate_gate" false false PASS PASS DONE released false false "" good
cat >>"$validator_duplicate_gate/.config/goal/gates/state.yaml" <<'YAML'
  G0:
    status: PASS
    result:
      verdict: PASS
YAML
run_failure_contains "goal validator rejects duplicate gate id" "GV-GATE-DUPLICATE-ID" \
  python3 "$SCRIPT_DIR/goal-validate.py" --root "$validator_duplicate_gate" --mode strict --format text

validator_g10_pass="$TMP_ROOT/validator-g10-pass"
write_validator_fixture "$validator_g10_pass" true true PASS BLOCKED BLOCKED in_review false false "" good
run_failure "goal validator rejects G10 pass with unresolved release-blocking risk" \
  python3 "$SCRIPT_DIR/goal-validate.py" --root "$validator_g10_pass" --mode strict --format text

validator_g11_after_g10="$TMP_ROOT/validator-g11-after-g10"
write_validator_fixture "$validator_g11_after_g10" true true BLOCKED PASS BLOCKED in_review false false "" good
run_failure "goal validator rejects G11 pass before G10 pass" \
  python3 "$SCRIPT_DIR/goal-validate.py" --root "$validator_g11_after_g10" --mode strict --format text

validator_stale_release_snapshot="$TMP_ROOT/validator-stale-release-snapshot"
write_validator_fixture "$validator_stale_release_snapshot" false false PASS PASS BLOCKED in_review false false "" good
run_failure_contains "goal validator rejects stale blocked release snapshot after G11 pass" "GV-CONSISTENCY-PIPELINE-STALE-BLOCKED" \
  python3 "$SCRIPT_DIR/goal-validate.py" --root "$validator_stale_release_snapshot" --mode strict --format text

validator_stale_release_status="$TMP_ROOT/validator-stale-release-status"
write_validator_fixture "$validator_stale_release_status" false false PASS PASS DONE in_review false false "" good
run_failure_contains "goal validator rejects stale release registry status after G11 pass" "GV-CONSISTENCY-RELEASE-STALE-STATUS" \
  python3 "$SCRIPT_DIR/goal-validate.py" --root "$validator_stale_release_status" --mode strict --format text

validator_pipeline_done="$TMP_ROOT/validator-pipeline-done"
write_validator_fixture "$validator_pipeline_done" true true BLOCKED BLOCKED DONE in_review false false "" good
run_failure "goal validator rejects pipeline done with unresolved release-blocking risk" \
  python3 "$SCRIPT_DIR/goal-validate.py" --root "$validator_pipeline_done" --mode strict --format text

validator_released="$TMP_ROOT/validator-released"
write_validator_fixture "$validator_released" true true BLOCKED BLOCKED BLOCKED released false false "" good
run_failure "goal validator rejects released status with unresolved release-blocking risk" \
  python3 "$SCRIPT_DIR/goal-validate.py" --root "$validator_released" --mode strict --format text

validator_stale_ci="$TMP_ROOT/validator-stale-ci"
write_validator_fixture "$validator_stale_ci" false false PASS PASS DONE released true false "" good
run_failure_contains "goal validator rejects stale CI validation vocabulary" "GV-CONSISTENCY-CI-STALE-CONTRACT" \
  python3 "$SCRIPT_DIR/goal-validate.py" --root "$validator_stale_ci" --mode strict --format text

validator_hosted_ci="$TMP_ROOT/validator-hosted-ci"
write_validator_fixture "$validator_hosted_ci" false false PASS PASS DONE released false false "" good
cat >"$validator_hosted_ci/.github/workflows/goal-ci.yml" <<'YAML'
name: Goal fixture
on: [push]
env:
  GOAL_CI_RUNNER_CLASS: hosted
  RUNNER_TOOL_CACHE: ${{ github.workspace }}/.goal-runner-tool-cache
  AGENT_TOOLSDIRECTORY: ${{ github.workspace }}/.goal-runner-tool-cache
jobs:
  goal-validator:
    runs-on: macos-latest
    steps:
      - run: bash docs/goal/tools/setup-ci-toolchain.sh
      - run: python3 docs/goal/tools/goal-validate.py --root . --mode strict --format text
  goal-toolchain-check:
    runs-on: macos-latest
    steps:
      - run: bash docs/goal/tools/setup-ci-toolchain.sh
YAML
run_failure_contains "goal validator rejects macos Goal CI runner" "GV-CONSISTENCY-CI-RUNNER-CLASS" \
  python3 "$SCRIPT_DIR/goal-validate.py" --root "$validator_hosted_ci" --mode strict --format text

validator_unpinned_self_hosted_ci="$TMP_ROOT/validator-unpinned-self-hosted-ci"
write_validator_fixture "$validator_unpinned_self_hosted_ci" false false PASS PASS DONE released false false "" good
cat >"$validator_unpinned_self_hosted_ci/.github/workflows/goal-ci.yml" <<'YAML'
name: Goal fixture
on: [push]
env:
  GOAL_CI_RUNNER_CLASS: hosted
  RUNNER_TOOL_CACHE: ${{ github.workspace }}/.goal-runner-tool-cache
  AGENT_TOOLSDIRECTORY: ${{ github.workspace }}/.goal-runner-tool-cache
jobs:
  goal-validator:
    runs-on: windows-latest
    steps:
      - run: mkdir -p "$RUNNER_TOOL_CACHE" "$AGENT_TOOLSDIRECTORY"
      - run: bash docs/goal/tools/setup-ci-toolchain.sh
      - run: python3 docs/goal/tools/goal-validate.py --root . --mode strict --format text
  goal-toolchain-check:
    runs-on: windows-latest
    steps:
      - run: mkdir -p "$RUNNER_TOOL_CACHE" "$AGENT_TOOLSDIRECTORY"
      - run: bash docs/goal/tools/setup-ci-toolchain.sh
YAML
run_failure_contains "goal validator rejects windows Goal CI runner" "GV-CONSISTENCY-CI-RUNNER-CLASS" \
  python3 "$SCRIPT_DIR/goal-validate.py" --root "$validator_unpinned_self_hosted_ci" --mode strict --format text

validator_missing_ci_validator="$TMP_ROOT/validator-missing-ci-validator"
write_validator_fixture "$validator_missing_ci_validator" false false PASS PASS DONE released false false "" good
cat >"$validator_missing_ci_validator/.github/workflows/goal-ci.yml" <<'YAML'
name: Goal fixture
on: [push]
env:
  GOAL_CI_RUNNER_CLASS: self-hosted
  RUNNER_TOOL_CACHE: ${{ github.workspace }}/.goal-runner-tool-cache
  AGENT_TOOLSDIRECTORY: ${{ github.workspace }}/.goal-runner-tool-cache
jobs:
  current:
    runs-on: [self-hosted, Linux, X64, ci-governance]
    steps:
      - run: mkdir -p "$RUNNER_TOOL_CACHE" "$AGENT_TOOLSDIRECTORY"
      - run: bash docs/goal/tools/setup-ci-toolchain.sh
      - run: echo "source_id target_id evidence_id BLOCKED"
  goal-toolchain-check:
    runs-on: [self-hosted, Linux, X64, ci-governance]
    steps:
      - run: mkdir -p "$RUNNER_TOOL_CACHE" "$AGENT_TOOLSDIRECTORY"
      - run: bash docs/goal/tools/setup-ci-toolchain.sh
YAML
run_failure_contains "goal validator rejects missing CI strict validator" "GV-CONSISTENCY-CI-MISSING-GOAL-VALIDATOR" \
  python3 "$SCRIPT_DIR/goal-validate.py" --root "$validator_missing_ci_validator" --mode strict --format text

validator_missing_required_job="$TMP_ROOT/validator-missing-required-job"
write_validator_fixture "$validator_missing_required_job" false false PASS PASS DONE released false false "" good
cat >"$validator_missing_required_job/.config/goal/schema/rules.yaml" <<'YAML'
ci:
  workflow: ".github/workflows/goal-ci.yml"
  runner:
    required_labels:
      - self-hosted
      - Linux
      - X64
      - ci-governance
    required_env:
      - RUNNER_TOOL_CACHE
      - AGENT_TOOLSDIRECTORY
    toolchain_setup: "docs/goal/tools/setup-ci-toolchain.sh"
    python_dependency_isolation:
      primary: job-local-venv
      fallback: workspace-local-pip-target
      fallback_env:
        - GOAL_CI_PYTHON_TARGET
        - GOAL_CI_BIN_DIR
  required_jobs:
    - summary
YAML
run_failure_contains "goal validator rejects missing strict validator required job" "GV-CONSISTENCY-CI-MISSING-GOAL-VALIDATOR" \
  python3 "$SCRIPT_DIR/goal-validate.py" --root "$validator_missing_required_job" --mode strict --format text

release_gate_ready="$TMP_ROOT/release-gate-ready"
write_release_gate_fixture "$release_gate_ready" false false PASS BLOCKED present
run_success "goal release gate accepts G10 pass with evidence" \
  run_goal_release_gate "$release_gate_ready"

release_gate_open_risk="$TMP_ROOT/release-gate-open-risk"
write_release_gate_fixture "$release_gate_open_risk" true true BLOCKED BLOCKED present
run_failure_contains "goal release gate blocks unresolved release risk" "GRG-OPEN-RELEASE-RISK" \
  run_goal_release_gate "$release_gate_open_risk"

release_gate_missing_evidence="$TMP_ROOT/release-gate-missing-evidence"
write_release_gate_fixture "$release_gate_missing_evidence" false false PASS BLOCKED missing
run_failure_contains "goal release gate blocks missing evidence package" "GRG-EVIDENCE-MISSING" \
  run_goal_release_gate "$release_gate_missing_evidence"

release_gate_missing_ci="$TMP_ROOT/release-gate-missing-ci"
write_release_gate_fixture "$release_gate_missing_ci" false false PASS BLOCKED present
cat >"$release_gate_missing_ci/.github/workflows/goal-ci.yml" <<'YAML'
name: Goal fixture
on: [push]
env:
  GOAL_CI_RUNNER_CLASS: self-hosted
  RUNNER_TOOL_CACHE: ${{ github.workspace }}/.goal-runner-tool-cache
  AGENT_TOOLSDIRECTORY: ${{ github.workspace }}/.goal-runner-tool-cache
jobs:
  summary:
    runs-on: [self-hosted, Linux, X64, ci-governance]
    steps:
      - run: mkdir -p "$RUNNER_TOOL_CACHE" "$AGENT_TOOLSDIRECTORY"
      - run: bash docs/goal/tools/setup-ci-toolchain.sh
      - run: echo "source_id target_id evidence_id BLOCKED"
YAML
run_failure_contains "goal release gate requires goal-validator job" "GV-CONSISTENCY-CI-MISSING-GOAL-VALIDATOR" \
  run_goal_release_gate "$release_gate_missing_ci"

printf '\nself-test summary: PASS=%s FAIL=%s\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
