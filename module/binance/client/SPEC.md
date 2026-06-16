# module/binance/client SPEC

## 1. Role

`module/binance/client` owns Binance exchange-facing market-data collection.

It collects data from Binance, normalizes exchange-native payloads, maps them into canonical market-data envelopes, persists local delivery state, and sends them to `module/binance/server`.

## 2. Product Lines

Client must support:

- Spot
- USDⓈ-M Futures
- COIN-M Futures
- Options

Product lines must be individually configurable.

## 3. Connector Model

Each product-line connector must expose a consistent internal event stream.

Minimum connector responsibilities:

- endpoint selection
- subscription lifecycle
- reconnect handling
- rate-limit aware recovery
- raw payload capture
- local timestamp capture
- product-line annotation

## 4. Product-Line Catalog

The client maintains a Binance-specific product-line catalog.

Catalog entries must include enough data to produce canonical identities:

- exchange
- product_line
- instrument_type
- symbol
- base_asset
- quote_asset
- margin_asset
- settlement_asset
- expiry
- strike
- option_type
- contract_code
- price precision
- quantity precision
- status

## 5. Instrument Parser

The parser converts Binance-native symbols and exchange metadata into canonical identity components.

It must distinguish:

```text
BTCUSDT Spot
BTCUSDT USDⓈ-M Perpetual
BTCUSD COIN-M Perpetual
BTC-YYYYMMDD-STRIKE-C Option
BTC-YYYYMMDD-STRIKE-P Option
```

Parser output is not the canonical source of truth. It is Binance-specific input to `domain-market` canonical types.

## 6. Raw Event Normalization

Raw events must be normalized into internal client events before canonical mapping.

Normalized events must preserve:

- product_line
- source stream
- raw symbol
- event type
- exchange event time
- local receive time
- raw payload reference or compact payload
- sequence/update ids when available

## 7. Canonical Mapping

The mapper converts normalized client events to canonical market events.

Mapping must use domain semantics from `module/domain-market`.

Mapping must not define independent canonical enums.

## 8. Idempotency Key Generation

The client generates idempotency keys that are stable across retry.

Key dimensions should include:

- exchange
- product_line
- instrument_key
- event_type
- event_time or source sequence
- interval/open time for bars
- trade id for trades where available
- update id range for depth where available

Different event types may use different key strategies.

## 9. Spool

The client must persist events before attempting remote send.

Spool states:

```text
pending
sending
acked
failed_retryable
failed_terminal
```

The spool must survive process restart.

## 10. Checkpoint

Checkpoint records the last durable server-accepted position.

Checkpoint must not advance on:

- serialization success
- local enqueue success
- gRPC write success
- send attempt success

Checkpoint may advance only after server durable ACK.

## 11. gRPC Sender

The sender streams `IngestRequest` messages to `module/binance/server`.

The sender must handle:

- connection retry
- backpressure
- stream restart
- partial ACK
- reject classification
- checkpoint progression
- spool cleanup policy

## 12. Admin Surface

Client admin endpoints:

```text
/healthz
/readyz
/debug/*
/admin/*
```

Suggested client admin operations:

- list enabled product lines
- list active streams
- pause/resume product-line collection
- show spool stats
- show checkpoint stats
- trigger safe catalog reload

Admin must not:

- mutate server state
- delete checkpoints without protected explicit operation
- expose secrets
- trigger trading actions

## 13. Observability

Metrics:

- raw events received
- events normalized
- events mapped
- events spooled
- events sent
- ACK lag
- retry count
- stream reconnects
- connector error count
- per-product-line throughput

Logs must include:

- product_line
- stream_id
- raw symbol
- instrument_key where known
- idempotency_key where safe
- checkpoint position

## 14. Acceptance Criteria

Client is acceptable when:

- all four product lines can be represented in catalog
- parser distinguishes Spot/USDM/COINM/Options identities
- mapper emits canonical events using domain-market types
- events are spooled before sending
- checkpoint advances only after server ACK
- gRPC sender reconnects without duplicate downstream effects when paired with server idempotency
- client admin is local-state only
- client imports no server internals
