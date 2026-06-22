#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

pass() {
  echo "PASS: $*"
}

require_file() {
  [ -f "$1" ] || fail "missing file: $1"
}

SPEC="module/binance/SPEC.md"
README="module/binance/README.md"
STANDARD="module/binance/STANDARD.md"
DATA_LIFECYCLE="module/binance/DATA-LIFECYCLE.md"
FEATURES="module/binance/FEATURES.md"
GOAL="module/binance/goal.md"
DEEP_ANALYSIS="module/binance/DEEP-ANALYSIS.md"
ACCEPTANCE="module/binance/ACCEPTANCE.md"
TRACEABILITY="module/binance/TRACEABILITY.md"
RUNTIME_MAPPING="module/binance/RUNTIME-MAPPING.md"
NAMING="module/binance/NAMING.md"
RULES="module/binance/RULES.md"
SERVER_SPEC="module/binance/server/SPEC.md"
TASK_KAFKA="module/binance/server/tasks/TASK-BINANCE-SERVER-014-kafkax-dispatch.md"
MIGRATION="docs/migrations/binance-v2-upgrade.md"
REPORT_INDEX="docs/report/INDEX.md"
BINANCE_REPORT_INDEX="docs/report/binance/INDEX.md"
ITERATION_PLAN="docs/report/binance/iteration-plan-20260622.md"
COMMIT_COVERAGE="docs/report/binance/commit-coverage-audit-20260623.md"
GOVERNANCE_CLOSURE="docs/report/binance/governance-closure-20260623.md"

for doc in "$SPEC" "$README" "$STANDARD" "$DATA_LIFECYCLE" "$FEATURES" "$GOAL" "$DEEP_ANALYSIS" "$ACCEPTANCE" "$TRACEABILITY" "$RUNTIME_MAPPING" "$NAMING" "$RULES" "$SERVER_SPEC" "$TASK_KAFKA" "$MIGRATION" "$REPORT_INDEX" "$BINANCE_REPORT_INDEX" "$ITERATION_PLAN" "$COMMIT_COVERAGE" "$GOVERNANCE_CLOSURE"; do
  require_file "$doc"
done

spec_version="$(sed -n 's/^- Spec-Version: \(v[0-9][0-9.]*\).*/\1/p' "$SPEC" | head -n 1)"
readme_root_version="$(sed -n 's/^- Spec-Version: \(v[0-9][0-9.]*\) (root).*/\1/p' "$README" | head -n 1)"
acceptance_version="$(sed -n 's/^| Module-Version | \(v[0-9][0-9.]*\) |$/\1/p' "$ACCEPTANCE" | head -n 1)"

[ -n "$spec_version" ] || fail "missing root Spec-Version in $SPEC"
[ "$readme_root_version" = "$spec_version" ] || fail "$README root Spec-Version $readme_root_version != $SPEC $spec_version"
[ "$acceptance_version" = "$spec_version" ] || fail "$ACCEPTANCE Module-Version $acceptance_version != $SPEC $spec_version"
grep -Fq "Spec-Reference: \`module/binance/SPEC.md\` $spec_version" "$TRACEABILITY" || fail "$TRACEABILITY Spec-Reference does not match $spec_version"
pass "Binance root doc versions match $spec_version"

grep -Fq "### 4.1 分布式运行约束" "$SPEC" || fail "$SPEC missing canonical distributed runtime constraints section"
grep -Fq '| R1 | `binance-client` 与 `binance-server` 不得共享 Go interface 或内存。 |' "$SPEC" || fail "$SPEC missing R1 independent process constraint"
if grep -Fq "见 §0" "$SPEC"; then
  fail "$SPEC still points active distributed constraints to DEEP §0"
fi
pass "SPEC distributed constraints are canonicalized in §4.1"

product_lines=(spot um_perp cm_perp options)
event_types=(tick trade bar depth funding_rate mark_price)

for product_line in "${product_lines[@]}"; do
  for event_type in "${event_types[@]}"; do
    grep -Fq "binance.market.${product_line}.${event_type}" "$RUNTIME_MAPPING" || fail "missing natsx subject binance.market.${product_line}.${event_type} in $RUNTIME_MAPPING"
    grep -Fq "binance.${product_line}.${event_type}.v1" "$RUNTIME_MAPPING" || fail "missing Kafka topic binance.${product_line}.${event_type}.v1 in $RUNTIME_MAPPING"
  done
done
pass "RUNTIME-MAPPING has complete 4x6 natsx subjects and Kafka topics"

legacy_topics="$(grep -nE 'binance\.market\.(ticks|bars|depth|events)\b' "$RUNTIME_MAPPING" "$NAMING" "$SPEC" "$ACCEPTANCE" "$TRACEABILITY" "$SERVER_SPEC" "$TASK_KAFKA" || true)"
if [ -n "$legacy_topics" ]; then
  printf '%s\n' "$legacy_topics" >&2
  fail "legacy aggregate Kafka topic remains"
fi

topic_wildcards="$(grep -nE 'binance\.market\.\*.*topic|topic.*binance\.market\.\*' "$SPEC" "$ACCEPTANCE" "$TRACEABILITY" "$SERVER_SPEC" "$TASK_KAFKA" || true)"
if [ -n "$topic_wildcards" ]; then
  printf '%s\n' "$topic_wildcards" >&2
  fail "Kafka topic wording still uses natsx binance.market.* wildcard"
fi
pass "Kafka topic wording is separated from natsx subjects"

require_file "module/binance/server/tasks/TASK-BINANCE-SERVER-016-ossx-archiver.md"

stale_tasks="$(grep -nE 'TASK-BINANCE-SERVER-014-kafkax-export|TASK-BINANCE-SERVER-016-ossx-archive\b' "$RULES" || true)"
if [ -n "$stale_tasks" ]; then
  printf '%s\n' "$stale_tasks" >&2
  fail "RULES references stale task filename"
fi
pass "RULES task filenames resolve to existing task docs"

grep -Fq "4 × 6" "$NAMING" || fail "$NAMING missing 4x6 event matrix"
grep -Fq "4 × 6" "$RULES" || fail "$RULES missing 4x6 matrix rule"
grep -Fq "24 × 5 = 120" "$RULES" || fail "$RULES missing 24x5 closure count"
grep -Fq "binance.spot.funding_rate.v1" "$TASK_KAFKA" || fail "$TASK_KAFKA missing funding_rate Kafka topic"
grep -Fq 'topic = binance.spot.tick.v1' "$TASK_KAFKA" || fail "$TASK_KAFKA acceptance still references legacy topic"
stale_matrix="$(grep -nE '4 × 4|16 × 5 = 80' "$NAMING" "$RULES" "$TASK_KAFKA" || true)"
if [ -n "$stale_matrix" ]; then
  printf '%s\n' "$stale_matrix" >&2
  fail "naming/rules/task docs still reference stale 4x4 matrix"
fi
pass "Naming matrix and Kafka task use 4x6 taxonomy"

grep -Fq 'runtime 通过状态仍以实际 `/home/binance` 测试为准' "$ACCEPTANCE" || fail "$ACCEPTANCE missing runtime status evidence caveat"
pass "Runtime status remains layered from docs readiness"

grep -Fq "## 0. 分布式架构约束（已迁移）" "$DEEP_ANALYSIS" || fail "$DEEP_ANALYSIS missing §0 archive stub"
grep -Fq "## 12. 当前代码实态审计（已迁移）" "$DEEP_ANALYSIS" || fail "$DEEP_ANALYSIS missing §12 archive stub"
grep -Fq "docs/migrations/binance-v2-upgrade.md" "$DEEP_ANALYSIS" || fail "$DEEP_ANALYSIS missing migration pointer"
pass "DEEP-ANALYSIS distributed sections are archive stubs"

grep -Fq '| `STANDARD.md` |' "$RULES" || fail "$RULES missing STANDARD.md in R9"
grep -Fq '| `DATA-LIFECYCLE.md` |' "$RULES" || fail "$RULES missing DATA-LIFECYCLE.md in R9"
grep -Fq 'scripts/check-binance-docs.sh' "$STANDARD" || fail "$STANDARD missing doc gate command"
pass "STANDARD and DATA-LIFECYCLE are covered by doc governance"

active_legacy="$(grep -nF 'binance-market' "$README" "$FEATURES" "$GOAL" "$STANDARD" 2>/dev/null | grep -v 'docs/migrations/remove-binance-market.md' || true)"
if [ -n "$active_legacy" ]; then
  printf '%s\n' "$active_legacy" >&2
  fail "active docs still carry unscoped binance-market references"
fi
pass "active summary docs avoid unscoped binance-market references"

grep -Fq "binance/governance-closure-20260623.md" "$REPORT_INDEX" || fail "$REPORT_INDEX missing governance closure row"
grep -Fq "binance/commit-coverage-audit-20260623.md" "$REPORT_INDEX" || fail "$REPORT_INDEX missing commit coverage row"
grep -Fq "governance-closure-20260623.md" "$BINANCE_REPORT_INDEX" || fail "$BINANCE_REPORT_INDEX missing governance closure row"
grep -Fq "commit-coverage-audit-20260623.md" "$BINANCE_REPORT_INDEX" || fail "$BINANCE_REPORT_INDEX missing commit coverage row"
pass "report indexes include governance closure and commit coverage audits"

grep -Fq "§4.1" "$MIGRATION" || fail "$MIGRATION missing SPEC §4.1 pointer"
grep -Fq "Migration contract" "$MIGRATION" || fail "$MIGRATION missing migration contract"
grep -Fq "DEEP §0/§12 are stubs" "$MIGRATION" || fail "$MIGRATION missing DEEP stub wording"
pass "migration anchor points to SPEC §4.1 and archive stubs"

grep -Fq '**Local runtime evidence closed for this audit slice.**' "$GOVERNANCE_CLOSURE" || fail "$GOVERNANCE_CLOSURE missing #869 local runtime closure"
grep -Fq 'go test ./... -race -count=1' "$GOVERNANCE_CLOSURE" || fail "$GOVERNANCE_CLOSURE missing race evidence"
grep -Fq 'golangci-lint run' "$GOVERNANCE_CLOSURE" || fail "$GOVERNANCE_CLOSURE missing lint evidence"
grep -Fq 'LOCAL-EVIDENCE CLOSED' "$ITERATION_PLAN" || fail "$ITERATION_PLAN missing #869 local evidence closure"
stale_checksum="checksum"" mismatch"
stale_runtime_status="BLOCKED(runtime"" evidence)"
if grep -Fq "$stale_checksum" "$GOVERNANCE_CLOSURE" || grep -Fq "$stale_runtime_status" "$ITERATION_PLAN"; then
  fail "binance reports still contain stale #869 runtime evidence wording"
fi
pass "governance closure report records #869 local runtime evidence"

coverage_declared="$(sed -n 's/^- Local candidate count from command: \([0-9][0-9]*\)\.$/\1/p' "$COMMIT_COVERAGE" | head -n 1)"
coverage_actual="$(git log --all --date=short --format=%H --grep="preserve\|stash\|backup\|保存\|临时\|WIP" -i | wc -l | tr -d ' ')"
[ -n "$coverage_declared" ] || fail "$COMMIT_COVERAGE missing local candidate count"
[ "$coverage_declared" = "$coverage_actual" ] || fail "$COMMIT_COVERAGE count $coverage_declared != git log count $coverage_actual"
coverage_rows="$(grep -cE '^\| [0-9]+ \| `' "$COMMIT_COVERAGE" || true)"
[ "$coverage_rows" -ge 50 ] || fail "$COMMIT_COVERAGE has fewer than 50 coverage rows"
pass "commit coverage audit count and matrix are present"
