# domain_market：Canonical Market Fact v2 补充规格

- Status: Proposed
- Parent: module/domain_market/spec/SPEC.md
- ADR: module/ADR-five-module-production-pipeline-v1.md

## Boundary

domain_market is a pure value-object and invariant library.

Allowed runtime dependencies: stdlib, decimalx and approved lower domain primitives.

Forbidden:

- Kafka/NATS/HTTP/Gin/TDengine/Postgres/Redis/OSS imports；
- provider clients；
- DataProvider implementation ports；
- compensation jobs；
- hidden clock reads；
- execution semantics such as PositionSide, OrderType and RuntimeMode；
- JSON/storage tags on domain entities。

## BarState

```go
type BarState uint8

const (
    BarStateUnknown BarState = iota
    BarStateOpen
    BarStateFinal
    BarStateCorrected
)
```

Bar v2 requires:

- InstrumentKey
- Interval
- OHLCV/Turnover/Count
- OpenTime
- CloseTime
- ObservedAt
- State
- Revision
- SourceID
- Quality

Legacy IsFinal bool is deprecated. Missing legacy field maps to Unknown, never automatically to Open or Final.

## Canonical Time Semantics

- OccurredAt: exchange event time.
- ObservedAt: collector receive time.
- AvailableAt: first usable by downstream.
- ProducedAt: envelope creation time.
- DecisionTime is not owned by domain_market.

Invariants:

- all times UTC；
- OpenTime < CloseTime；
- OccurredAt <= ObservedAt unless explicit ClockSkew flag；
- AvailableAt >= ObservedAt；
- no constructor silently clamps invalid future time。

## Quality

Quality is a typed set, not a free-form boolean:

- Reliable
- Recovered
- GapBefore
- Stale
- ClockSkew
- ChecksumFailed
- Corrected
- Incomplete
- Quarantined

Reliable cannot coexist with Stale, ChecksumFailed, Incomplete or Quarantined.

## Sequence

Canonical sequence metadata:

- SourceSequence
- PreviousSequence
- SourceID
- Generation

Sequence validation is pure. Storage of watermarks belongs to market_data.

## Typed Payloads

Supported v2 facts:

- Trade
- Quote
- Bar
- OrderBookSnapshot
- OrderBookDelta
- FundingRate
- MarkPrice
- OpenInterest
- Liquidation

Payload interface{} is not accepted as canonical public state. Conversion from wire payload occurs at service boundaries.

## Precision

Price, quantity, money, notional, funding and ratio values use decimalx/fixed-point domain values. float64 is forbidden for these categories.

## Acceptance Criteria

- AC-DM-V2-001: Unknown/Open/Final/Corrected round-trip without ambiguity.
- AC-DM-V2-002: old missing IsFinal fixture migrates to Unknown.
- AC-DM-V2-003: invalid time ordering fails closed.
- AC-DM-V2-004: invalid quality combinations fail closed.
- AC-DM-V2-005: negative price/qty and crossed snapshot fail closed.
- AC-DM-V2-006: canonical identity and hash inputs are deterministic.
- AC-DM-V2-007: provider/storage/transport forbidden imports equal zero.
- AC-DM-V2-008: property, fuzz and consumer compile suites pass.
