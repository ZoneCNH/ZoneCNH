---
scope: "Execution Modes"
acceptance_criteria: []
---

# TASK-TRANSPORTX-019: Execution Modes

- **Module**: transportx
- **spec_ref**: module/transportx/SPEC.md#FR-021

- **BR_ref**: module/transportx/SPEC.md#BR-016
- **ACs**: AC-021
- **TCs**: TC-021
- **Phase**: Advanced Features (Phase 4)
- **Priority**: P1
- **Dependencies**: TASK-004 (Runtime), TASK-012 (Middleware)
- **Status**: Pending

## Scope

Implement ExecutionMode enum (LIVE, PAPER, REPLAY, DRY_RUN) with gate enforcement. LIVE requires auth+deadline+idempotency+audit. PAPER allows paper order adapter. REPLAY forbids live exchange adapter. DRY_RUN forbids external side effects. Mode transitions require explicit confirmation + audit.


## Non-Scope

Does NOT implement broker clients, storage drivers, business event semantics, or domain DTOs.

## Files

- `runtime/mode.go` — ExecutionMode enum + gate logic
- `runtime/mode_test.go` — Mode gate tests

## Acceptance

- [ ] LIVE: missing audit sink → reject
- [ ] PAPER: allows paper order adapter
- [ ] REPLAY: real order submission → `TX_MODE_VIOLATION`
- [ ] DRY_RUN: external side effect → `TX_MODE_VIOLATION`
- [ ] Mode transition emits audit event
- [ ] `go test ./runtime/... -run TestExecutionModeGates` passes

## Non-scope

- 不涉及本 Task 范围外的功能
