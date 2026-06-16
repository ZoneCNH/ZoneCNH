# module/binance SPEC

## 1. Status

Version: v1.0.0  
Status: Proposed Final  
Scope: Binance-specific market-data C/S module.

## 2. Role

`module/binance` defines the complete Binance-specific market-data ingest boundary for ZoneCNH.

It consists of:

```text
module/binance/client
module/binance/server
```

The module upgrades Binance integration from a passive SDK / legacy Provider model to an explicit market-data C/S ingest model.

## 3. Architecture Summary

```text
Binance Exchange
  ↓
module/binance/client
  ↓ contracts-defined gRPC stream
module/binance/server
  ↓ downstream dispatch port
module/market-data
```

## 4. Ownership

### 4.1 Root Owns

`module/binance` root owns:

- Binance module goal
- client/server split
- top-level boundary policy
- root traceability
- root implementation sequence
- root runtime mapping
- no-legacy-`binance-market` rule

### 4.2 Client Owns

`module/binance/client` owns:

- Binance exchange-facing collection
- Binance REST/WebSocket adapters
- product-line catalog
- Binance symbol parsing
- exchange-native event normalization
- raw-to-canonical mapping
- client-side idempotency key generation
- client-side SQLite spool
- client-side checkpoint
- gRPC sender
- client admin endpoints

### 4.3 Server Owns

`module/binance/server` owns:

- Binance-specific gRPC ingest server
- `MarketDataService` implementation for Binance ingest
- stream lifecycle
- event validation
- server-side idempotent acceptance
- ACK / reject classification
- durable acceptance boundary
- downstream dispatch
- server admin endpoints

## 5. Does Not Own

`module/binance` does not own:

- canonical domain model definitions
- proto compatibility governance
- market-data storage engine
- query APIs
- strategy APIs
- order execution
- trading signals
- portfolio accounting
- cross-exchange generic ingestion server
- old `binance-market` Provider compatibility

## 6. Product Lines

`module/binance` supports the following Binance product lines:

| Product Line | Description | Client Connector | Canonical Requirement |
|---|---|---|---|
| Spot | Binance spot market data | `client` Spot connector | distinct `InstrumentKey` |
| USDⓈ-M | USDT/USDC margined futures | `client` USDⓈ-M connector | distinct `ProductLine` |
| COIN-M | coin margined futures | `client` COIN-M connector | settlement-aware identity |
| Options | Binance options market data | `client` Options connector | expiry/strike/option type identity |

## 7. MarketDataService

`MarketDataService` is the contracts-defined gRPC ingest service.

For Binance-specific ingestion:

```text
module/contracts defines the service.
module/binance/server implements the service.
module/binance/client calls the service.
```

The service name may remain generic at the wire level, but the runtime implementation in this module is Binance-specific.

## 8. Delivery Semantics

`module/binance` provides:

```text
client: at-least-once delivery
server: idempotent acceptance
downstream: deduplicated dispatch/persistence handoff
```

The client must not advance checkpoint until the server returns an ACK that represents durable acceptance.

No exactly-once guarantee is claimed at the client level.

## 9. ACK Semantics

The preferred ingest protocol is bidirectional streaming:

```proto
service MarketDataService {
  rpc Ingest(stream IngestRequest) returns (stream IngestAck);
}
```

Rationale:

- client has local spool
- client needs precise checkpoint advancement
- server must distinguish accepted/rejected events
- reconnects must not create duplicate downstream effects

ACKs should include:

- stream id
- accepted idempotency keys or accepted ranges
- reject reasons
- durable acceptance indicator
- retry hint

## 10. Canonical Event Output

The client maps Binance-native events into canonical market-data envelopes defined outside this module.

Required domain concepts:

- `InstrumentKey`
- `ProductLine`
- `InstrumentType`
- `OptionType`
- `PriceKind`
- `MarketScope`
- `MarketFactEnvelope`
- `decision_time`

`module/domain-market` owns these semantics. `module/binance` consumes them.

## 11. Instrument Identity

Instrument identity must avoid collisions across Binance product lines.

The canonical identity must be able to distinguish:

```text
BTCUSDT Spot
BTCUSDT USDⓈ-M perpetual
BTCUSD COIN-M perpetual
BTC-YYYYMMDD-STRIKE-C/P Option
```

Minimum identity dimensions:

- exchange
- product_line
- instrument_type
- base_asset
- quote_asset
- margin_asset
- settlement_asset
- contract_code
- expiry
- strike
- option_type

## 12. Admin Surface

Both client and server may expose Gin admin surfaces.

Common endpoints:

```text
/healthz
/readyz
/debug/*
/admin/*
```

Rules:

- `/healthz` is process liveness only.
- `/readyz` checks module readiness, not downstream business correctness.
- `/debug/*` is read-only and must not expose secrets.
- `/admin/*` may mutate local service state only.
- Admin endpoints must be authenticated when exposed outside local trusted networks.

## 13. Observability

Both client and server must expose:

- logs with stream/product-line/instrument context
- metrics for input events, accepted events, rejected events, retries, ACK lag
- health/readiness signals
- trace correlation IDs when available

## 14. Configuration

Root configuration categories:

- Binance endpoints
- product-line enablement
- symbol allowlist/denylist
- gRPC target
- spool path
- checkpoint path
- retry policy
- admin bind address
- observability settings

Secrets must not be printed in logs or exposed through debug/admin endpoints.

## 15. Boundary Rules

Hard boundaries:

1. No `binance-market`.
2. Client must not import server internals.
3. Server must not import client internals.
4. `module/binance` must not own storage/query/strategy.
5. Client/server communication must use contracts-defined gRPC.
6. Domain semantics must come from `module/domain-market`.
7. Wire protocol must come from `module/contracts`.

## 16. Acceptance Criteria

`module/binance` v1.0.0 is acceptable when:

- `binance-market` references are removed or isolated to migration history.
- `module/binance/client` and `module/binance/server` specs exist.
- root/client/server traceability exists.
- client/server task sets are independently executable.
- delivery semantics are explicitly at-least-once plus idempotent acceptance.
- ACK/checkpoint semantics are defined.
- ProductLine and InstrumentKey collision cases are documented.
- boundary gates can be executed in CI.
- runtime mapping does not place storage/query/strategy ownership in Binance.
