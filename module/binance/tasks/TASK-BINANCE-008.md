---
id: TASK-BINANCE-008
title: "Runtime client implementation slice"
priority: P0
scope: "Implement the client runtime slice for product catalogs, event mapping, spooling, checkpointing, and gRPC sending."
acceptance_criteria:
  - "AC-008: FR-001 — Client collectors cover configured Spot, USDⓈ-M, COIN-M, and Options product lines."
  - "AC-008: FR-002 — Binance-native events map to canonical MarketFactEnvelope values."
  - "AC-008: FR-004/BR-003 — Checkpoints advance only after durable_acceptance=true ACK."
---
# TASK-BINANCE-008 Runtime client implementation slice

## Machine-readable task

```yaml
task_id: TASK-BINANCE-008
module: binance
scope: "Implement the client runtime slice for product catalogs, event mapping, spooling, checkpointing, and gRPC sending."
spec_ref:
  - "module/binance/SPEC.md#FR-001"
  - "module/binance/SPEC.md#FR-002"
  - "module/binance/SPEC.md#FR-004"
files:
  - "cmd/binance-client/main.go"
  - "internal/client/catalog.go"
  - "internal/client/mapper.go"
  - "internal/client/checkpoint.go"
  - "internal/client/sender.go"
acceptance_criteria:
  - "AC-008: FR-001 — Client collectors cover configured Spot, USDⓈ-M, COIN-M, and Options product lines."
  - "AC-008: FR-002 — Binance-native events map to canonical MarketFactEnvelope values."
  - "AC-008: FR-004/BR-003 — Checkpoints advance only after durable_acceptance=true ACK."
depends_on:
  - "TASK-BINANCE-003"
  - "TASK-BINANCE-005"
  - "TASK-BINANCE-006"
priority: P0
status: pending
```

## Objective

Implement the client runtime slice for product catalogs, event mapping, spooling, checkpointing, and gRPC sending.

## Scope

- Spec references: FR-001, FR-002, FR-004
- Files likely to change:
  - `cmd/binance-client/main.go`
  - `internal/client/catalog.go`
  - `internal/client/mapper.go`
  - `internal/client/checkpoint.go`
  - `internal/client/sender.go`


## Non-scope

No server ingest pipeline, downstream dispatch, or storage/query/strategy packages.

## Acceptance Criteria

- AC-008: FR-001 — Client collectors cover configured Spot, USDⓈ-M, COIN-M, and Options product lines.
- AC-008: FR-002 — Binance-native events map to canonical MarketFactEnvelope values.
- AC-008: FR-004/BR-003 — Checkpoints advance only after durable_acceptance=true ACK.

## Test Plan

- TC-001: go test ./module/binance/client/...
- TC-004: Client checkpoint tests cover retry before ACK and advance after ACK.

## Dependencies

- `TASK-BINANCE-003`
- `TASK-BINANCE-005`
- `TASK-BINANCE-006`

