#!/usr/bin/env bash
# Validate the stage0-stage2 Binance documentation gates from
# docs/report/binance/goal-execution-plan-20260622.md.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

failures=0

pass() { printf 'PASS %s\n' "$1"; }
fail() {
  printf 'FAIL %s\n' "$1"
  failures=$((failures + 1))
}

require_file() {
  local file="$1"
  if [ -f "$file" ]; then
    pass "$file exists"
  else
    fail "$file: missing required file"
  fi
}

require_grep() {
  local pattern="$1"
  local file="$2"
  local label="$3"
  if grep -Eq "$pattern" "$file" 2>/dev/null; then
    pass "$label"
  else
    fail "$file: missing $label"
  fi
}

extract_value() {
  local label="$1"
  local file="$2"
  sed -n "s/.*${label}[[:space:]]*[:|][[:space:]]*\([^ |`)]*\).*/\1/p" "$file" | head -n 1
}

require_equal() {
  local actual="$1"
  local expected="$2"
  local file="$3"
  local label="$4"
  if [ "$actual" = "$expected" ]; then
    pass "$label = $expected"
  else
    fail "$file: $label is '$actual', expected '$expected'"
  fi
}

required_files=(
  docs/report/binance/goal-execution-plan-20260622.md
  docs/report/INDEX.md
  module/binance/README.md
  module/binance/SPEC.md
  module/binance/TRACEABILITY.md
  module/binance/ACCEPTANCE.md
  module/binance/FEATURES.md
  module/binance/RULES.md
  module/binance/NAMING.md
  module/binance/RUNTIME-MAPPING.md
  module/binance/BOUNDARY-GATES.md
  module/binance/DATA-LIFECYCLE.md
)
for file in "${required_files[@]}"; do
  require_file "$file"
done

plan=docs/report/binance/goal-execution-plan-20260622.md
index=docs/report/INDEX.md
rules=module/binance/RULES.md
naming=module/binance/NAMING.md
runtime=module/binance/RUNTIME-MAPPING.md
lifecycle=module/binance/DATA-LIFECYCLE.md
spec=module/binance/SPEC.md
readme=module/binance/README.md
trace=module/binance/TRACEABILITY.md
acceptance=module/binance/ACCEPTANCE.md
features=module/binance/FEATURES.md

require_grep 'AC-1' "$plan" 'goal plan AC-1 present'
require_grep 'AC-2' "$plan" 'goal plan AC-2 present'
require_grep 'AC-3' "$plan" 'goal plan AC-3 present'
require_grep '阶段 0' "$plan" 'stage 0 present'
require_grep '阶段 1' "$plan" 'stage 1 present'
require_grep '阶段 2' "$plan" 'stage 2 present'
require_grep 'CI 集成方案|CI integration' "$plan" 'CI integration plan drafted'
require_grep 'binance/goal-execution-plan-20260622\.md' "$index" 'report INDEX links goal plan'

for rule in R1 R2 R3 R4 R5 R6 R7 R8 R9 R10; do
  require_grep "^## ${rule}" "$rules" "RULES ${rule} machine-detectable"
done

spec_version="$(extract_value 'Spec-Version' "$spec")"
readme_root_version="$(sed -n 's/^- Spec-Version: \([^ ]*\).*/\1/p' "$readme" | head -n 1)"
trace_matrix_version="$(extract_value 'Matrix-Version' "$trace")"
trace_spec_ref=$(sed -n 's/^- Spec-Reference: `module\/binance\/SPEC\.md` \(v[0-9][^ ]*\).*/\1/p' "$trace" | head -n 1)
acceptance_version="$(extract_value 'Module-Version' "$acceptance")"
features_version="$(extract_value 'Module-Version' "$features")"

require_equal "$readme_root_version" "$spec_version" "$readme" 'README root Spec-Version'
require_equal "$trace_matrix_version" "$spec_version" "$trace" 'TRACEABILITY Matrix-Version'
require_equal "$trace_spec_ref" "$spec_version" "$trace" 'TRACEABILITY Spec-Reference'
require_equal "$acceptance_version" "$spec_version" "$acceptance" 'ACCEPTANCE Module-Version'
require_equal "$features_version" "$spec_version" "$features" 'FEATURES Module-Version'

products=(spot um_perp cm_perp options)
events=(tick trade bar depth)
for product in "${products[@]}"; do
  for event in "${events[@]}"; do
    subject="binance.market.${product}.${event}"
    topic="binance.${product}.${event}.v1"
    require_grep "${subject}" "$naming" "NAMING NATS ${subject}"
    require_grep "${subject}" "$runtime" "RUNTIME-MAPPING NATS ${subject}"
    require_grep "${topic}" "$naming" "NAMING Kafka ${topic}"
    require_grep "${topic}" "$runtime" "RUNTIME-MAPPING Kafka ${topic}"
  done
done

while IFS= read -r task_file; do
  [ -n "$task_file" ] || continue
  if find module/binance -path '*/tasks/*' -type f -name "$task_file" | grep -q .; then
    pass "RULES task ref ${task_file} exists"
  else
    fail "$rules: task ref ${task_file} has no matching task file"
  fi
done < <(grep -Eo 'TASK-BINANCE-[A-Z]+-[0-9]+-[A-Za-z0-9-]+\.md' "$rules" | sort -u)

require_grep '15 .*缺口|15 gaps' "$lifecycle" 'DATA-LIFECYCLE lists 15 gaps'
for fr in FR-012 FR-013 FR-014 FR-015 FR-016 FR-017 FR-018 FR-019 FR-020 FR-021 FR-022 FR-023 FR-024; do
  require_grep "$fr" "$lifecycle" "DATA-LIFECYCLE ${fr} landing point"
done
require_grep 'SPEC\.md.*未修改|not modify.*SPEC\.md|not a SPEC change' "$lifecycle" 'DATA-LIFECYCLE declares no SPEC change'
require_grep 'bump|Bump' "$lifecycle" 'DATA-LIFECYCLE records bump levels'
require_grep '依赖|Dependencies' "$lifecycle" 'DATA-LIFECYCLE records dependencies'

if [ "$failures" -eq 0 ]; then
  printf 'PASS binance docs stage0-stage2 gates: 0 fail\n'
else
  printf 'FAIL binance docs stage0-stage2 gates: %s fail\n' "$failures"
fi
exit "$failures"
