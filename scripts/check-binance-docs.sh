#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"

failures=0

pass() { printf 'PASS %s\n' "$1"; }
fail() {
  printf 'FAIL %s\n' "$1"
  failures=$((failures + 1))
}

search_has() {
  local pattern=$1 path=$2
  if command -v rg >/dev/null 2>&1; then
    rg -q "$pattern" "$path"
  else
    grep -Eq -- "$pattern" "$path"
  fi
}

search_matches() {
  local pattern=$1
  shift
  if command -v rg >/dev/null 2>&1; then
    rg -n "$pattern" "$@"
  else
    grep -nE -- "$pattern" "$@"
  fi
}

filter_out() {
  local pattern=$1
  if command -v rg >/dev/null 2>&1; then
    rg -v "$pattern"
  else
    grep -Ev -- "$pattern"
  fi
}

expect_file() {
  local path=$1
  if [[ -f "$path" ]]; then
    pass "file exists: $path"
  else
    fail "missing file: $path"
  fi
}

expect_executable() {
  local path=$1
  if [[ -x "$path" ]]; then
    pass "executable: $path"
  else
    fail "not executable: $path"
  fi
}

expect_rg() {
  local pattern=$1 path=$2 label=$3
  if search_has "$pattern" "$path"; then
    pass "$label"
  else
    fail "$label"
  fi
}

expect_no_rg() {
  local pattern=$1 path=$2 label=$3
  if search_has "$pattern" "$path"; then
    fail "$label"
  else
    pass "$label"
  fi
}

reject_contract_pattern() {
  local pattern=$1 label=$2
  local matches
  matches=$(
    search_matches "$pattern" "${docs[@]}" 2>/dev/null |
      filter_out 'legacy|~~|Drift Detection|rg -n|Change History|历史别名' ||
      true
  )
  if [[ -n "$matches" ]]; then
    fail "$label"
    printf '%s\n' "$matches"
  else
    pass "$label"
  fi
}

docs=(
  module/binance/spec/SPEC.md
  module/binance/spec/NAMING.md
  module/binance/matrix/TRACEABILITY.md
  module/binance/gate/RULES.md
  module/binance/gate/STANDARD.md
)

for file in "${docs[@]}"; do
  expect_file "$file"
done
expect_file "scripts/check-binance-docs.sh"
expect_executable "scripts/check-binance-docs.sh"

expect_no_rg 'SKIP: module/binance/SPEC\.md not found|module/binance/SPEC\.md not found' \
  scripts/check-binance-docs.sh \
  "checker no longer skips goal-driven structure"

for path in "${docs[@]}"; do
  expect_rg 'module/binance/spec/SPEC\.md|Spec-Version|Source-SPEC|STANDARD|RULES|NAMING|TRACEABILITY' \
    "$path" \
    "scans goal-driven anchor in $path"
done

contract_event_types=(
  book_ticker
  trade
  kline
  depth_update
  funding_rate
  mark_price_update
  option_tick
)

extended_event_types=(
  ticker
  open_interest
  index_reference
  contract_info
)

opt_in_event_types=(
  force_order
)

product_lines=(spot um_perp cm_perp options)

for product_line in "${product_lines[@]}"; do
  expect_rg "\\b${product_line}\\b" module/binance/spec/SPEC.md "SPEC product_line ${product_line}"
  expect_rg "\\b${product_line}\\b" module/binance/spec/NAMING.md "NAMING product_line ${product_line}"
  expect_rg "\\b${product_line}\\b" module/binance/gate/RULES.md "RULES product_line ${product_line}"
  expect_rg "\\b${product_line}\\b" module/binance/gate/STANDARD.md "STANDARD product_line ${product_line}"
done

for event_type in "${contract_event_types[@]}"; do
  expect_rg "\\b${event_type}\\b" module/binance/spec/SPEC.md "SPEC declares event_type contract ${event_type}"
  expect_rg "\\b${event_type}\\b" module/binance/spec/NAMING.md "NAMING declares event_type contract ${event_type}"
  expect_rg "\\b${event_type}\\b" module/binance/gate/RULES.md "RULES declares event_type contract ${event_type}"
  expect_rg "\\b${event_type}\\b" module/binance/gate/STANDARD.md "STANDARD declares event_type contract ${event_type}"
done

for event_type in "${extended_event_types[@]}"; do
  expect_rg "\\b${event_type}\\b" module/binance/spec/SPEC.md "SPEC extended implemented event_type ${event_type}"
  expect_rg "\\b${event_type}\\b" module/binance/spec/NAMING.md "NAMING extended implemented event_type ${event_type}"
  expect_rg "\\b${event_type}\\b" module/binance/gate/RULES.md "RULES extended implemented event_type ${event_type}"
  expect_rg "\\b${event_type}\\b" module/binance/gate/STANDARD.md "STANDARD extended implemented event_type ${event_type}"
done

for event_type in "${opt_in_event_types[@]}"; do
  expect_rg "\\b${event_type}\\b" module/binance/spec/SPEC.md "SPEC opt-in event_type ${event_type}"
  expect_rg "\\b${event_type}\\b" module/binance/spec/NAMING.md "NAMING opt-in event_type ${event_type}"
  expect_rg "\\b${event_type}\\b" module/binance/gate/RULES.md "RULES opt-in event_type ${event_type}"
  expect_rg "\\b${event_type}\\b" module/binance/gate/STANDARD.md "STANDARD opt-in event_type ${event_type}"
done

expect_rg 'binance\.market\.\{product_line\}\.\{event_type\}\.v1' module/binance/spec/SPEC.md \
  "SPEC documents canonical NATS subject template"
expect_rg 'binance\.market\.\{product_line\}\.\{event_type\}\.v1' module/binance/spec/NAMING.md \
  "NAMING documents canonical NATS subject template"
expect_rg 'binance\.market\.\{product_line\}\.\{event_type\}\.v1' module/binance/gate/STANDARD.md \
  "STANDARD documents canonical NATS subject template"
expect_rg 'binance\.\{product_line\}\.\{event_type\}\.v1' module/binance/spec/SPEC.md \
  "SPEC documents canonical Kafka topic template"
expect_rg 'binance\.\{product_line\}\.\{event_type\}\.v1' module/binance/spec/NAMING.md \
  "NAMING documents canonical Kafka topic template"
expect_rg 'binance\.\{product_line\}\.\{event_type\}\.v1' module/binance/gate/STANDARD.md \
  "STANDARD documents canonical Kafka topic template"
expect_rg 'Source-SPEC: `module/binance/spec/SPEC\.md`|module/binance/spec/SPEC\.md' module/binance/matrix/TRACEABILITY.md \
  "TRACEABILITY points at goal-driven SPEC"

for event_type in "${contract_event_types[@]}"; do
  expect_rg "GET /api/v1/market/${event_type}/:symbol|${event_type}" module/binance/gate/STANDARD.md \
    "STANDARD has REST/storage anchor for ${event_type}"
done

expect_rg '历史 Acceptance Criteria 登记（非当前状态源）' module/binance/spec/ACCEPTANCE.md \
  "ACCEPTANCE scopes legacy Done/PASS rows as historical"
expect_rg 'Options kline supported；trade/depth unsupported' module/binance/design/OPTIONS-HISTORY-FALLBACK.md \
  "Options history capability is explicit and type-specific"
expect_rg 'release_closeable_spec=NO.*release_closeable_runtime=NO' module/binance/spec/SPEC.md \
  "SPEC keeps both current release verdicts fail-closed"
expect_no_rg 'Options (trade|depth).*(历史|回填).*(Done|完整|supported)' module/binance/spec/SPEC.md \
  "SPEC does not claim unsupported Options trade/depth history complete"

reject_contract_pattern 'binance\.market\.[^[:space:]`|]*\.(tick|bar|depth|mark_price)(\.|`|[[:space:]|])' \
  "no legacy event_type in NATS subject contracts"
reject_contract_pattern 'binance\.[^[:space:]`|]*\.(tick|bar|depth|mark_price)\.v1' \
  "no legacy event_type in Kafka topic contracts"
reject_contract_pattern 'st_(tick|bar|depth|mark_price)' \
  "no legacy TDengine stable names in active contracts"
reject_contract_pattern '/(ticks|bars|funding-rate|mark-price)(/|`|[[:space:]|])' \
  "no legacy REST paths in active contracts"

expect_rg 'contracts.*v0/v1|v0/v1.*contracts|contracts.*版本线' module/binance/gate/STANDARD.md \
  "STANDARD guards contracts major-version drift"
expect_rg 'stale=true' module/binance/gate/STANDARD.md \
  "STANDARD documents stale=true downstream pause rule"
expect_rg 'POST /api/v1/admin/symbols/reload' module/binance/gate/STANDARD.md \
  "STANDARD documents current symbols reload endpoint"
expect_rg 'bash scripts/check-binance-docs\.sh' module/binance/gate/STANDARD.md \
  "STANDARD documents docs gate command"

if rg -n 'evidence (needed|pending)|simulation needed|regression needed' module/binance/matrix/TRACEABILITY.md | rg '\| Done' >/dev/null; then
  fail "TRACEABILITY marks missing evidence as Done"
else
  pass "TRACEABILITY does not mark missing evidence as Done"
fi
expect_rg '^\| release_closeable \| NO' module/binance/matrix/TRACEABILITY.md \
  "TRACEABILITY keeps release_closeable blocked"

# Canonical state consistency: derive the expected projection from the Matrix
# summary and verify both the actual FR rows and every active entry document.
matrix_summary_value() {
  local key=$1
  awk -F'|' -v wanted="$key" '
    /^## 6\. Summary/ { in_summary = 1; next }
    in_summary && /^\|/ {
      field = $2
      value = $3
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", field)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      if (field == wanted) {
        print value
        exit
      }
    }
  ' module/binance/matrix/TRACEABILITY.md
}

matrix_state_count() {
  local wanted=$1
  awk -F'|' -v wanted="$wanted" '
    /^\| FR-[[:alnum:]]+/ {
      state = $6
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", state)
      if (state == wanted || index(state, wanted "（") == 1) {
        count++
      }
    }
    END { print count + 0 }
  ' module/binance/matrix/TRACEABILITY.md
}

summary_total=$(matrix_summary_value "FR total")
summary_done=$(matrix_summary_value "Done")
summary_partial=$(matrix_summary_value "Partial")
summary_drifted=$(matrix_summary_value "Drifted")
summary_pending=$(matrix_summary_value "Pending")
actual_done=$(matrix_state_count "Done")
actual_partial=$(matrix_state_count "Partial")
actual_drifted=$(matrix_state_count "Drifted")
actual_pending=$(matrix_state_count "Pending")

if [[ -n "$summary_total" && \
  "$summary_total" == "$((actual_done + actual_partial + actual_drifted + actual_pending))" && \
  "$summary_done" == "$actual_done" && "$summary_partial" == "$actual_partial" && \
  "$summary_drifted" == "$actual_drifted" && "$summary_pending" == "$actual_pending" ]]; then
  pass "TRACEABILITY summary matches canonical FR rows"
else
  fail "TRACEABILITY summary differs from canonical FR rows"
  printf 'summary total/done/partial/drifted/pending=%s/%s/%s/%s/%s actual=%s/%s/%s/%s\n' \
    "$summary_total" "$summary_done" "$summary_partial" "$summary_drifted" "$summary_pending" \
    "$actual_done" "$actual_partial" "$actual_drifted" "$actual_pending"
fi

fr_state_projection() {
  local path=$1 state_column=$2
  awk -F'|' -v state_column="$state_column" '
    /^\| FR-[[:alnum:]]+/ {
      id = $2
      state = $state_column
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", id)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", state)
      if (index(state, "Done") == 1) state = "Done"
      if (index(state, "Partial") == 1) state = "Partial"
      print id "|" state
    }
  ' "$path" | sort
}

matrix_projection=$(fr_state_projection module/binance/matrix/TRACEABILITY.md 6)
spec_projection=$(fr_state_projection module/binance/spec/SPEC.md 5)
features_projection=$(fr_state_projection module/binance/spec/FEATURES.md 4)
matrix_projection_count=$(printf '%s\n' "$matrix_projection" | awk 'NF { count++ } END { print count + 0 }')
spec_projection_count=$(printf '%s\n' "$spec_projection" | awk 'NF { count++ } END { print count + 0 }')
matrix_unique_count=$(printf '%s\n' "$matrix_projection" | cut -d'|' -f1 | sort -u | awk 'NF { count++ } END { print count + 0 }')
spec_unique_count=$(printf '%s\n' "$spec_projection" | cut -d'|' -f1 | sort -u | awk 'NF { count++ } END { print count + 0 }')
features_projection_count=$(printf '%s\n' "$features_projection" | awk 'NF { count++ } END { print count + 0 }')
features_unique_count=$(printf '%s\n' "$features_projection" | cut -d'|' -f1 | sort -u | awk 'NF { count++ } END { print count + 0 }')
if [[ "$matrix_projection_count" == "$summary_total" && "$spec_projection_count" == "$summary_total" && \
  "$matrix_unique_count" == "$summary_total" && "$spec_unique_count" == "$summary_total" && \
  "$features_projection_count" == "$summary_total" && "$features_unique_count" == "$summary_total" && \
  "$matrix_projection" == "$spec_projection" && "$matrix_projection" == "$features_projection" ]]; then
  pass "SPEC, FEATURES and TRACEABILITY have one identical state for every FR"
else
  fail "SPEC/FEATURES/TRACEABILITY per-FR state projection differs or contains duplicate/missing IDs"
  diff -u <(printf '%s\n' "$matrix_projection") <(printf '%s\n' "$spec_projection") || true
  diff -u <(printf '%s\n' "$matrix_projection") <(printf '%s\n' "$features_projection") || true
fi

expected_state="${summary_done} Done / ${summary_partial} Partial / ${summary_drifted} Drifted / ${summary_pending} Pending"
state_docs=(
  module/binance/spec/SPEC.md
  module/binance/matrix/TRACEABILITY.md
  module/binance/spec/ACCEPTANCE.md
  module/binance/spec/FEATURES.md
  module/binance/goal/goal.md
  module/binance/README.md
)
for path in "${state_docs[@]}"; do
  expect_rg "$expected_state" "$path" "current state agrees with Matrix summary in $path"
  expect_no_rg 'release_closeable_spec[=:][[:space:]]*YES|Spec-release-closeable:[[:space:]]*YES' \
    "$path" \
    "no current spec-closeable YES contradiction in $path"
done

unscoped_yes=$(
  search_matches 'release_closeable[^[:space:]]*[=:]?[^[:space:]]*\*?YES|release_closeable[[:space:]]*=[[:space:]]*\*?YES' \
    "${state_docs[@]}" 2>/dev/null |
    filter_out '历史|曾记录|曾投影|\| v[0-9]+\.' ||
    true
)
if [[ -n "$unscoped_yes" ]]; then
  fail "release_closeable YES appears outside an explicit historical context"
  printf '%s\n' "$unscoped_yes"
else
  pass "release_closeable YES appears only in explicit historical context"
fi

if (( failures > 0 )); then
  printf '%s check(s) failed\n' "$failures" >&2
  exit 1
fi

printf 'binance docs checks passed\n'
