---
scope: "Backpressure + Bulkhead"
acceptance_criteria: []
---

# TASK-TRANSPORTX-014: Backpressure + Bulkhead

- **Module**: transportx
- **spec_ref**: module/transportx/SPEC.md#FR-012

- **ACs**: AC-012
- **TCs**: TC-012
- **Phase**: Middleware + Control (Phase 3)
- **Priority**: P1
- **Dependencies**: TASK-006 (Errors), TASK-012 (Middleware)
- **Status**: Pending

## Scope

Implement BackpressurePolicy (BLOCK, DROP_OLDEST, DROP_NEWEST, FAIL_FAST, SPILL_TO_DISK) and Bulkhead concurrency limiter. Enforce queue/concurrency/rate/memory limits. Return `TX_BACKPRESSURE` or `TX_BULKHEAD_REJECTED` on saturation.


## Non-Scope

Does NOT implement broker clients, storage drivers, business event semantics, or domain DTOs.

## Files

- `middleware/backpressure.go` — Backpressure middleware
- `middleware/bulkhead.go` — Bulkhead middleware
- `middleware/backpressure_test.go` — Saturation tests

## Acceptance

- [ ] Queue saturation → configured backpressure policy applied
- [ ] Concurrency saturation → `TX_BULKHEAD_REJECTED`
- [ ] DROP_OLDEST on REALTIME_BEST_EFFORT, SPILL_TO_DISK on AUDIT
- [ ] `go test ./middleware/... -run TestBackpressure` passes

## Non-scope

- 不涉及本 Task 范围外的功能
