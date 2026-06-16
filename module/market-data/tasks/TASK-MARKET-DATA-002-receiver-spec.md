# TASK-MARKET-DATA-002 Receiver SPEC

- Status: Approved
- Owner: `module/market-data`
- Last-Updated: 2026-06-17

## Objective

Specify receiver-side validation, idempotency, conflict handling, durable handoff, backpressure, ordering, and observability for the `DownstreamDispatchPort` defined in `SPEC.md` §4.

## Acceptance Criteria

1. Receiver validates `venue`, `productLine`, `instrumentKey`, `channel`, `eventTime`, `receivedAt`, `sourceSequence`, `payload`, `quality`, `idempotencyKey`, `orderingKey`, and `source` (12 fields).
2. Receiver performs atomic check-and-insert for `idempotencyKey` + payload fingerprint.
3. Receiver returns `DispatchAck` (idempotent) for same key/hash.
4. Receiver returns `DispatchReject` / `idempotency_conflict` for same key/different hash.
5. Receiver returns `DispatchFailure` (retryable) when capacity is temporarily unavailable.
6. Receiver writes accepted facts to a durable inbox/reliable queue before returning `DispatchAck`.
7. Receiver exposes metrics/logs for all outcomes: venue, productLine, channel, outcome, reason (§4.3–§4.4).
8. Receiver maps binance-native reject classifications to market-data unified reasons per §4.4.1.
