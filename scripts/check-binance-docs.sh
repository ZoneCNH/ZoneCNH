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
  if rg -q "$pattern" "$path"; then
    pass "$label"
  else
    fail "$label"
  fi
}

expect_no_rg() {
  local pattern=$1 path=$2 label=$3
  if rg -q "$pattern" "$path"; then
    fail "$label"
  else
    pass "$label"
  fi
}

reject_contract_pattern() {
  local pattern=$1 label=$2
  local matches
  matches=$(rg -n "$pattern" "${docs[@]}" 2>/dev/null | rg -v 'legacy|~~|Drift Detection|rg -n|Change History|历史别名' || true)
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

implemented_event_types=(
  book_ticker
  trade
  kline
  depth_update
  funding_rate
  mark_price_update
)

planned_event_types=(
  ticker
  force_order
  open_interest
  index_reference
  contract_info
)

product_lines=(spot um_perp cm_perp options)

for product_line in "${product_lines[@]}"; do
  expect_rg "\\b${product_line}\\b" module/binance/spec/SPEC.md "SPEC product_line ${product_line}"
  expect_rg "\\b${product_line}\\b" module/binance/spec/NAMING.md "NAMING product_line ${product_line}"
  expect_rg "\\b${product_line}\\b" module/binance/gate/RULES.md "RULES product_line ${product_line}"
  expect_rg "\\b${product_line}\\b" module/binance/gate/STANDARD.md "STANDARD product_line ${product_line}"
done

for event_type in "${implemented_event_types[@]}"; do
  expect_rg "\\b${event_type}\\b" module/binance/spec/SPEC.md "SPEC implemented event_type ${event_type}"
  expect_rg "\\b${event_type}\\b" module/binance/spec/NAMING.md "NAMING implemented event_type ${event_type}"
  expect_rg "\\b${event_type}\\b" module/binance/gate/RULES.md "RULES implemented event_type ${event_type}"
  expect_rg "\\b${event_type}\\b" module/binance/gate/STANDARD.md "STANDARD implemented event_type ${event_type}"
done

for event_type in "${planned_event_types[@]}"; do
  expect_rg "\\b${event_type}\\b" module/binance/spec/SPEC.md "SPEC planned event_type ${event_type}"
  expect_rg "\\b${event_type}\\b" module/binance/spec/NAMING.md "NAMING planned event_type ${event_type}"
  expect_rg "\\b${event_type}\\b" module/binance/gate/STANDARD.md "STANDARD planned event_type ${event_type}"
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

for event_type in "${implemented_event_types[@]}"; do
  expect_rg "GET /api/v1/market/${event_type}/:symbol|${event_type}" module/binance/gate/STANDARD.md \
    "STANDARD has REST/storage anchor for ${event_type}"
done

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

if (( failures > 0 )); then
  printf '%s check(s) failed\n' "$failures" >&2
  exit 1
fi

printf 'binance docs checks passed\n'
