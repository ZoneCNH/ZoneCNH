#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
COMMAND="preflight"
MODE="strict"
FORMAT="text"

usage() {
  cat <<'EOF'
Goal executable workflow

Usage:
  bash docs/goal/tools/goal-workflow.sh <command> [options]

Commands:
  preflight  Compile tools, check shell syntax, rule drift, and docs lint
  validate   Run preflight, strict control-plane validation, and Matrix check
  gate       Run validate plus gate readiness checks
  ci         Run validate, self-test, and gate when runtime artifacts exist
  release    Run gate plus the release hard blocker
  self-test  Run the Goal toolchain self-test only
  help       Show this help

Options:
  --root DIR          Repository root. Defaults to the detected repo root
  --mode MODE         goal-validate mode: strict or audit. Default: strict
  --format FORMAT     goal-validate output: text or json. Default: text
  -h, --help          Show this help
EOF
}

die() {
  printf 'goal-workflow: %s\n' "$*" >&2
  exit 2
}

step() {
  printf '\n==> %s\n' "$1"
}

run() {
  printf '+'
  printf ' %q' "$@"
  printf '\n'
  "$@"
}

require_file() {
  local file="$1"
  [[ -f "$file" ]] || die "required file not found: $file"
}

normalize_root() {
  [[ -d "$ROOT" ]] || die "root directory not found: $ROOT"
  ROOT="$(cd "$ROOT" && pwd)"
}

parse_args() {
  local command_set=0
  while (($#)); do
    case "$1" in
      --root)
        [[ $# -ge 2 ]] || die "--root requires a value"
        ROOT="$2"
        shift 2
        ;;
      --mode)
        [[ $# -ge 2 ]] || die "--mode requires a value"
        MODE="$2"
        shift 2
        ;;
      --format)
        [[ $# -ge 2 ]] || die "--format requires a value"
        FORMAT="$2"
        shift 2
        ;;
      -h|--help|help)
        COMMAND="help"
        command_set=1
        shift
        ;;
      -*)
        die "unknown option: $1"
        ;;
      *)
        [[ "$command_set" -eq 0 ]] || die "multiple commands provided"
        COMMAND="$1"
        command_set=1
        shift
        ;;
    esac
  done

  case "$COMMAND" in
    preflight|validate|gate|ci|release|self-test|help) ;;
    *) die "unknown command: $COMMAND" ;;
  esac
  case "$MODE" in
    strict|audit) ;;
    *) die "unknown validator mode: $MODE" ;;
  esac
  case "$FORMAT" in
    text|json) ;;
    *) die "unknown validator format: $FORMAT" ;;
  esac
}

python_compile() {
  step "Python tool compile"
  run python3 -m py_compile \
    "$SCRIPT_DIR/goal-validate.py" \
    "$SCRIPT_DIR/matrix-gen.py" \
    "$SCRIPT_DIR/rule-drift-check.py"
}

shell_syntax() {
  step "Shell tool syntax"
  require_file "$ROOT/.github/ci/goal-release-gate.sh"
  local script
  for script in \
    "$SCRIPT_DIR/gate-check.sh" \
    "$SCRIPT_DIR/lint-goal.sh" \
    "$SCRIPT_DIR/evidence-collect.sh" \
    "$SCRIPT_DIR/self-test.sh" \
    "$SCRIPT_DIR/goal-workflow.sh" \
    "$ROOT/.github/ci/goal-release-gate.sh"
  do
    run bash -n "$script"
  done
}

rule_drift() {
  step "Rule drift check"
  run python3 "$SCRIPT_DIR/rule-drift-check.py" --root "$ROOT" --quiet
}

lint_goal() {
  step "Goal docs lint"
  run bash "$SCRIPT_DIR/lint-goal.sh" "$ROOT/docs/goal"
}

goal_validate() {
  step "Goal control-plane validation"
  run python3 "$SCRIPT_DIR/goal-validate.py" --root "$ROOT" --mode "$MODE" --format "$FORMAT"
}

matrix_check() {
  step "Matrix check"
  require_file "$ROOT/.config/goal/matrix/matrix.yaml"
  run python3 "$SCRIPT_DIR/matrix-gen.py" --check-only --matrix "$ROOT/.config/goal/matrix/matrix.yaml"
}

gate_check() {
  step "Gate readiness check"
  run bash "$SCRIPT_DIR/gate-check.sh" "$ROOT"
}

runtime_artifacts_ready() {
  [[ -f "$ROOT/.config/goal/registry/tasks.yaml" ]] || return 1
  [[ -f "$ROOT/.config/goal/matrix/matrix.yaml" ]] || return 1
  [[ -d "$ROOT/.config/goal/evidence" ]] || return 1
  local evidence
  evidence="$(find "$ROOT/.config/goal/evidence" -type f -name 'EVID-*.md' -print -quit 2>/dev/null || true)"
  [[ -n "$evidence" ]]
}

gate_if_ready() {
  if runtime_artifacts_ready; then
    gate_check
  else
    step "Gate readiness check"
    printf 'skip gate-check: no complete goal runtime artifacts\n'
  fi
}

release_gate() {
  step "Release hard blocker"
  require_file "$ROOT/.github/ci/goal-release-gate.sh"
  printf '+ GOAL_VALIDATOR_SCRIPT=%q bash %q %q\n' \
    "$SCRIPT_DIR/goal-validate.py" \
    "$ROOT/.github/ci/goal-release-gate.sh" \
    "$ROOT"
  GOAL_VALIDATOR_SCRIPT="$SCRIPT_DIR/goal-validate.py" \
    bash "$ROOT/.github/ci/goal-release-gate.sh" "$ROOT"
}

self_test() {
  step "Goal toolchain self-test"
  run bash "$SCRIPT_DIR/self-test.sh"
}

preflight() {
  python_compile
  shell_syntax
  rule_drift
  lint_goal
}

validate() {
  preflight
  goal_validate
  matrix_check
}

gate() {
  validate
  gate_check
}

ci() {
  validate
  self_test
  gate_if_ready
}

release() {
  gate
  release_gate
}

parse_args "$@"

if [[ "$COMMAND" == "help" ]]; then
  usage
  exit 0
fi

normalize_root

case "$COMMAND" in
  preflight) preflight ;;
  validate) validate ;;
  gate) gate ;;
  ci) ci ;;
  release) release ;;
  self-test) self_test ;;
esac
