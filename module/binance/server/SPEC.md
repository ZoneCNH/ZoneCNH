# module/binance/server SPEC

## 1. Role

`module/binance/server` owns Binance-specific market-data ingest acceptance into ZoneCNH.

It receives canonicalized Binance market events from `module/binance/client`, validates them, deduplicates them, acknowledges durable acceptance, and dispatches accepted events to downstream market-data infrastructure.

## 2. Service Implementation

The server implements the contracts-defined service:

```proto
service MarketDataService {
  rpc Ingest(stream IngestRequest) returns (stream IngestAck);
}
```

This implementation is Binance-specific.

## 3. Owns

The server owns:

- gRPC server binding
- stream lifecycle
- request validation
- idempotency check
- durable acceptance boundary
- ACK/reject generation
- downstream dispatch
- server admin endpoints
- server-side contract tests

## 4. Does Not Own

The server does not own:

- Binance REST/WebSocket adapters
- exchange connectivity
- client-side spool/checkpoint
- canonical domain type definitions
- proto definitions
- physical storage engine
- query APIs
- strategy APIs
- cross-exchange generic ingestion server
- old `binance-market` compatibility

## 5. Validation

Server validation checks:

- required envelope fields
- product_line is supported
- instrument identity is structurally valid
- event type is known
- event time is valid
- idempotency key is present
- source metadata is present
- domain enum values are recognized
- payload shape matches event type

Invalid events receive reject responses.

## 6. Idempotent Acceptance

Server must accept each idempotency key at most once for downstream dispatch.

Duplicate behavior:

- duplicate already accepted key should ACK as already accepted or idempotently accepted
- duplicate with conflicting payload should reject as conflict
- retryable server errors should not mark event accepted
- terminal validation errors should not advance client checkpoint as accepted unless explicitly acknowledged as terminal consumed

## 7. Durable Acceptance

Durable acceptance means the server has completed the local action required before telling the client that checkpoint may advance.

Depending on downstream architecture, durable acceptance may mean:

- persisted idempotency record
- accepted into durable queue
- committed to downstream market-data port
- otherwise guaranteed not to be lost after ACK

The exact backing mechanism belongs to runtime implementation, but ACK semantics must be stable.

## 8. ACK / Reject

ACK includes enough data for client checkpoint progression.

Suggested fields:

- stream id
- accepted idempotency key or range
- accepted count
- duplicate count
- rejects
- retry hint
- durable acceptance indicator

Reject classification:

```text
retryable
terminal_validation
terminal_conflict
unauthorized
rate_limited
server_unavailable
```

## 9. Downstream Dispatch

Server dispatches accepted events to `module/market-data` through an exchange-neutral downstream port.

Server does not own storage implementation.

Server does not expose query APIs.

Server must not call strategy APIs.

## 10. Admin Surface

Server admin endpoints:

```text
/healthz
/readyz
/debug/*
/admin/*
```

Suggested server admin operations:

- show stream stats
- show accepted/rejected counts
- show idempotency stats
- pause/resume accepting streams
- drain mode
- downstream dispatch status

Admin must not:

- mutate client connectors
- delete client checkpoints
- bypass idempotency
- expose secrets
- trigger trading actions

## 11. Observability

Metrics:

- active streams
- ingested requests
- accepted events
- duplicate events
- rejected events
- reject reasons
- ACK latency
- downstream dispatch latency
- downstream dispatch failures

Logs must include:

- stream_id
- product_line
- instrument_key
- idempotency_key
- ack status
- reject reason where applicable

## 12. Acceptance Criteria

Server is acceptable when:

- it implements generated gRPC server interface.
- it validates required envelope fields.
- it accepts unique idempotency keys once.
- duplicate idempotency keys do not create duplicate downstream dispatch.
- it returns ACKs that can drive client checkpoint.
- it dispatches accepted events to downstream market-data port.
- it does not import client internals.
- it does not own storage/query/strategy.
- server admin mutates server-local state only.
