# module/binance BOUNDARY GATES

## 1. Purpose

Boundary gates prevent `module/binance` from expanding beyond its intended ownership.

They must be executable in CI.

## 2. Gate: No Legacy binance-market

Forbidden references:

```text
module/binance-market
github.com/ZoneCNH/binance-market
binance-market
docs/services/binance-market-client-svc.md
```

Allowed only in:

```text
docs/migrations/remove-binance-market.md
CHANGELOG.md
```

Suggested check:

```bash
#!/usr/bin/env bash
set -euo pipefail

allow_re='docs/migrations/remove-binance-market.md|CHANGELOG.md'
forbidden_re='module/binance-market|github.com/ZoneCNH/binance-market|binance-market|docs/services/binance-market-client-svc.md'

hits="$(grep -R -n -E "$forbidden_re" . \
  --include='*.md' \
  --include='*.go' \
  --include='go.mod' \
  --include='go.sum' \
  --include='*.yaml' \
  --include='*.yml' || true)"

if [ -n "$hits" ]; then
  disallowed="$(printf '%s\n' "$hits" | grep -v -E "$allow_re" || true)"
  if [ -n "$disallowed" ]; then
    echo "Forbidden legacy binance-market references found:"
    printf '%s\n' "$disallowed"
    exit 1
  fi
fi
```

## 3. Gate: Client Must Not Import Server Internals

Forbidden:

```text
module/binance/client -> module/binance/server/*
runtime internal/client -> internal/server/*
cmd/binance-client -> internal/server/*
```

Allowed:

```text
client -> module/contracts generated gRPC client
client -> module/domain-market semantic types
client -> shared config/observability packages
```

Suggested check:

```bash
grep -R -n -E 'internal/server|module/binance/server' \
  ./internal/client ./cmd/binance-client 2>/dev/null && {
  echo "client must not import server internals"
  exit 1
} || true
```

## 4. Gate: Server Must Not Import Client Internals

Forbidden:

```text
module/binance/server -> module/binance/client/*
runtime internal/server -> internal/client/*
cmd/binance-server -> internal/client/*
```

Forbidden especially:

```text
server -> spot connector
server -> usdm connector
server -> coinm connector
server -> options connector
server -> client spool
server -> client checkpoint
```

Allowed:

```text
server -> module/contracts generated gRPC server
server -> module/domain-market semantic types
server -> module/market-data downstream port
server -> shared config/observability packages
```

Suggested check:

```bash
grep -R -n -E 'internal/client|module/binance/client' \
  ./internal/server ./cmd/binance-server 2>/dev/null && {
  echo "server must not import client internals"
  exit 1
} || true
```

## 5. Gate: Binance Must Not Own Storage/Query/Strategy

Forbidden imports or ownership language:

```text
storage engine ownership
query API ownership
strategy API ownership
trading decision ownership
order execution ownership
portfolio accounting ownership
```

Allowed:

```text
server -> downstream dispatch port
server -> market-data ingestion handoff
```

Suggested check keywords:

```bash
grep -R -n -E 'Owns.*storage|Owns.*query|Owns.*strategy|order execution|trading decision' module/binance && {
  echo "module/binance must not own storage/query/strategy/trading decisions"
  exit 1
} || true
```

## 6. Gate: Contracts Are Wire Representation Only

`module/binance` must not define its own duplicate proto or wire schema.

Allowed:

```text
module/binance -> module/contracts
```

Forbidden:

```text
module/binance/proto/*
module/binance owns proto compatibility policy
module/binance defines canonical wire enum source of truth
```

Suggested check:

```bash
#!/usr/bin/env bash
set -euo pipefail

# 6a: No local proto directory
if [ -d "module/binance/proto" ]; then
  echo "FAIL: module/binance/proto/ directory exists — proto ownership belongs to module/contracts"
  exit 1
fi

# 6b: No local .proto files in binance tree
proto_files="$(find module/binance -name '*.proto' 2>/dev/null || true)"
if [ -n "$proto_files" ]; then
  echo "FAIL: .proto files found under module/binance — wire schema belongs to module/contracts"
  echo "$proto_files"
  exit 1
fi

# 6c: No ownership language claiming proto or wire enum SSOT
ownership_hits="$(grep -R -n -E 'Owns.*proto|owns.*proto compatibility|defines canonical wire|canonical wire enum' \
  module/binance \
  --include='*.md' || true)"
if [ -n "$ownership_hits" ]; then
  echo "FAIL: module/binance claims proto/wire enum ownership — belongs to module/contracts"
  echo "$ownership_hits"
  exit 1
fi

echo "PASS: Contracts gate — no local proto, no wire SSOT claim"

## 7. Gate: Domain-Market Is Semantic Source

`module/binance` must not define canonical market semantics independently.

Allowed:

```text
module/binance -> module/domain-market
```

Forbidden:

```text
module/binance defines canonical ProductLine source of truth
module/binance defines canonical InstrumentKey source of truth
module/binance defines canonical MarketScope source of truth
```

Binance may define exchange-specific parsing and mapping, but the resulting canonical value must be a `domain-market` concept.

## 8. Gate: Admin Surface Cannot Cross Module Boundaries

Client admin may mutate only client-local state.

Server admin may mutate only server-local state.

Forbidden:

```text
client admin -> server internal state
server admin -> client connector state
admin -> storage engine mutation
admin -> strategy mutation
admin -> arbitrary checkpoint deletion without explicit protected operation
```

## 9. Gate: Checkpoint Requires ACK

Client checkpoint advancement must be causally tied to server durable ACK.

Forbidden:

```text
checkpoint advance on send attempt
checkpoint advance on local serialization only
checkpoint advance on gRPC write success only
```

Allowed:

```text
checkpoint advance after durable accepted ACK from server
```
