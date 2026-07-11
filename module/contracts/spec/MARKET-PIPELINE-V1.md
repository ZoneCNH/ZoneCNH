# contracts：Market Pipeline v1 补充规格

- Status: Proposed
- Parent: module/contracts/spec/SPEC.md
- ADR: module/ADR-five-module-production-pipeline-v1.md

## Owns

- HTTP request/response DTO；
- canonical ErrorEnvelope；
- market fact event schemas；
- market regime snapshot schemas；
- schema version、compatibility 和 golden fixtures。

## Does Not Own

- Gin handlers；
- storage clients；
- Binance DTO；
- acceptance implementation；
- regime classifier；
- strategy/risk decision。

## HTTP Endpoints

| Method | Path | Contract |
| --- | --- | --- |
| POST | /v1/market-facts:submit | SubmitMarketFactRequest → CaptureReceipt |
| POST | /v1/market-facts:submitBatch | SubmitMarketFactsRequest → BatchCaptureReceipt |
| GET | /v1/market-facts/{event_id} | FactStatusResponse |
| GET | /v1/market-data/latest | LatestMarketFactResponse |
| GET | /v1/market-data/range | MarketFactRangeResponse |
| GET | /v1/coverage | CoverageResponse |

## MarketFactEnvelopeV1

Required:

- event_id
- correlation_id
- causation_id
- idempotency_key
- schema_version
- producer
- venue
- product_line
- instrument_key
- event_type
- occurred_at
- observed_at
- available_at
- produced_at
- source_sequence
- previous_sequence
- payload_hash
- quality_flags
- payload

All timestamps are UTC RFC3339Nano. All query ranges are [from,to).

Price, quantity, money and ratio wire values use canonical decimal strings. They must not use JSON floating-point numbers.

## CaptureReceipt

Required:

- event_id
- receipt_id
- disposition: CAPTURED | DUPLICATE | REJECTED | CONFLICT
- durability_scope: CAPTURE_LOG
- payload_hash
- captured_at
- schema_version

The field Durable bool is forbidden because it does not identify the durability boundary.

## ErrorEnvelope

Required:

- code
- message
- retryable
- correlation_id
- details
- occurred_at

HTTP mapping:

- 400 malformed wire
- 401/403 identity/permission
- 409 same key, different hash
- 422 terminal contract/domain/quality violation
- 429 retry with Retry-After
- 503 capture unavailable

## Events

- market.fact.captured.v1
- market.fact.accepted.v1
- market.fact.quarantined.v1
- market.coverage.changed.v1
- market.regime.snapshot.v1

Every event includes event_id, correlation_id, causation_id, schema_version, producer, produced_at, available_at, sequence, idempotency_key and payload_hash.

## MarketRegimeSnapshotV1

Contains S state, confidence_bps, fixed-point/decimal feature scores, freshness, quality flags, event-time window, input watermark, model_version, parameter_set_id and evidence_refs.

It must not contain final TradePermission, PositionCaps, MaxLeverage or RiskPermit.

## Acceptance Criteria

- AC-CON-V1-001: golden JSON round-trip is byte-stable after canonicalization.
- AC-CON-V1-002: same schema major remains backward readable.
- AC-CON-V1-003: unknown required enum fails closed.
- AC-CON-V1-004: JSON float for price/qty/money is rejected.
- AC-CON-V1-005: CaptureReceipt cannot claim a Sink not named by durability_scope.
- AC-CON-V1-006: Binance, market_data and market_regime pass the same conformance suite.
- AC-CON-V1-007: generated OpenAPI/JSON Schema drift is zero.
- AC-CON-V1-008: market regime and decision contracts have no ownership overlap.
