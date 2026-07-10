#!/usr/bin/env bash
set -u -o pipefail

ZONE_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_ROOT="${BINANCE_RUNTIME_ROOT:-/home/workspace/binance/.worktree/workspaces/fix/binance-todo-closure-20260710}"
LOG_ROOT="${BINANCE_FINAL_20CHECK_LOG_DIR:-/tmp/binance-final-20check-20260710-final}"
EVIDENCE_DIR="${RUNTIME_ROOT}/release/evidence/binance/20260710"
EXPECTED_RUNTIME_SHA="3f6366728b635c32d73565874965d40c20a92caf"

mkdir -p "${LOG_ROOT}"

total_failures=0

run_check() {
  local round_dir="$1"
  local label="$2"
  local cwd="$3"
  shift 3
  local log_file="${round_dir}/${label}.log"
  if (cd "${cwd}" && "$@") >"${log_file}" 2>&1; then
    printf 'PASS\t%s\n' "${label}" >>"${round_dir}/RESULTS.tsv"
  else
    printf 'FAIL\t%s\n' "${label}" >>"${round_dir}/RESULTS.tsv"
    return 1
  fi
  return 0
}

run_expected() {
  local round_dir="$1"
  local label="$2"
  local cwd="$3"
  local expected_exit="$4"
  shift 4
  local log_file="${round_dir}/${label}.log"
  local actual_exit=0
  (cd "${cwd}" && "$@") >"${log_file}" 2>&1 || actual_exit=$?
  if [ "${actual_exit}" -eq "${expected_exit}" ]; then
    printf 'PASS\t%s\t expected_exit=%s\n' "${label}" "${expected_exit}" >>"${round_dir}/RESULTS.tsv"
    return 0
  fi
  printf 'FAIL\t%s\t expected_exit=%s actual_exit=%s\n' "${label}" "${expected_exit}" "${actual_exit}" >>"${round_dir}/RESULTS.tsv"
  return 1
}

for round in $(seq 1 20); do
  round_dir="${LOG_ROOT}/round-$(printf '%02d' "${round}")"
  mkdir -p "${round_dir}"
  : >"${round_dir}/RESULTS.tsv"
  round_failures=0

  run_check "${round_dir}" runtime-full-test "${RUNTIME_ROOT}" \
    env GOROOT=/usr/local/go GOWORK=off go test ./... -count=1 || round_failures=$((round_failures + 1))
  run_check "${round_dir}" runtime-build "${RUNTIME_ROOT}" \
    env GOROOT=/usr/local/go GOWORK=off go build ./... || round_failures=$((round_failures + 1))
  run_check "${round_dir}" runtime-vet "${RUNTIME_ROOT}" \
    env GOROOT=/usr/local/go GOWORK=off go vet ./... || round_failures=$((round_failures + 1))
  run_check "${round_dir}" runtime-boundary "${RUNTIME_ROOT}" \
    env GOROOT=/usr/local/go GOWORK=off ./scripts/boundary-gates.sh || round_failures=$((round_failures + 1))
  run_check "${round_dir}" runtime-drift "${RUNTIME_ROOT}" \
    env GOROOT=/usr/local/go GOWORK=off ./scripts/spec-runtime-drift-check.sh || round_failures=$((round_failures + 1))
  run_check "${round_dir}" runtime-e2e-fixtures "${RUNTIME_ROOT}" \
    env GOROOT=/usr/local/go GOWORK=off go test -tags=e2e ./test/e2e -count=1 -run 'TestOptionsDepth|TestE2E_' || round_failures=$((round_failures + 1))
  run_check "${round_dir}" runtime-gofmt "${RUNTIME_ROOT}" bash -c \
    'files="$(rg --files internal/client internal/eventtypes internal/server test/e2e -g "*.go")"; test -z "$(gofmt -l ${files})"' || round_failures=$((round_failures + 1))
  run_check "${round_dir}" runtime-script-syntax "${RUNTIME_ROOT}" \
    bash -n scripts/runtime-release-evidence.sh scripts/verify-kafka-staging.sh scripts/run-external-gates.sh scripts/validate-release-packet.sh || round_failures=$((round_failures + 1))
  run_check "${round_dir}" runtime-diff-check "${RUNTIME_ROOT}" git diff --check || round_failures=$((round_failures + 1))
  run_expected "${round_dir}" external-gates-blocked "${RUNTIME_ROOT}" 2 \
    env EVIDENCE_DIR="${EVIDENCE_DIR}" bash scripts/run-external-gates.sh || round_failures=$((round_failures + 1))
  run_expected "${round_dir}" packet-validator-blocked "${RUNTIME_ROOT}" 2 \
    scripts/validate-release-packet.sh --packet docs/release/release-packet.template.yaml --runtime-root . || round_failures=$((round_failures + 1))
  run_check "${round_dir}" evidence-binding "${RUNTIME_ROOT}" bash -c \
    "grep -Fq 'Runner commit: ${EXPECTED_RUNTIME_SHA}' release/evidence/binance/20260710/external-gates-manual.md" || round_failures=$((round_failures + 1))
  run_check "${round_dir}" evidence-shape "${RUNTIME_ROOT}" bash -c \
    'test "$(wc -l < release/evidence/binance/20260710/external-gates.tsv)" -eq 6; test "$(rg -c BLOCKED release/evidence/binance/20260710/external-gates.tsv)" -eq 5' || round_failures=$((round_failures + 1))
  run_check "${round_dir}" zone-diff-check "${ZONE_ROOT}" git diff --check || round_failures=$((round_failures + 1))
  run_check "${round_dir}" zone-docs-gate "${ZONE_ROOT}" bash scripts/check-binance-docs.sh || round_failures=$((round_failures + 1))
  run_check "${round_dir}" zone-version-gate "${ZONE_ROOT}" bash .github/ci/binance-version-consistency-check.sh || round_failures=$((round_failures + 1))
  run_check "${round_dir}" zone-reference-gate "${ZONE_ROOT}" bash .github/ci/binance-reference-integrity-check.sh || round_failures=$((round_failures + 1))
  run_check "${round_dir}" zone-todo-anchors "${ZONE_ROOT}" bash -c \
    'rg -q "3f6366728b635c32d73565874965d40c20a92caf" module/binance/todo.md module/binance/ALIGNMENT.md docs/migrations/binance-ALIGNMENT-SYNC.md; rg -q "release_closeable_runtime=NO" module/binance/todo.md module/binance/spec/SPEC.md' || round_failures=$((round_failures + 1))

  if [ "${round_failures}" -eq 0 ]; then
    printf 'round=%02d\tPASS\n' "${round}" | tee -a "${LOG_ROOT}/SUMMARY.tsv"
  else
    printf 'round=%02d\tFAIL\tfailures=%d\n' "${round}" "${round_failures}" | tee -a "${LOG_ROOT}/SUMMARY.tsv"
    total_failures=$((total_failures + round_failures))
  fi
done

if [ "${total_failures}" -eq 0 ]; then
  printf 'total_rounds=20\tPASS\tlog_root=%s\n' "${LOG_ROOT}"
else
  printf 'total_rounds=20\tFAIL\tfailures=%d\tlog_root=%s\n' "${total_failures}" "${LOG_ROOT}"
fi

exit "${total_failures}"
