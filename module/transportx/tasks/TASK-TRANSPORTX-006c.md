# TASK-TRANSPORTX-006c: Error Taxonomy — QoS + Mode

- **Module**: transportx
- **spec_ref**: module/transportx/SPEC.md#FR-017 ,#FR-021
- **BR_ref**: module/transportx/SPEC.md#BR-013 ,#BR-014 ,#BR-016
- **ACs**: AC-017, AC-021
- **Phase**: Foundation Contracts (Phase 1)
- **Priority**: P0
- **Dependencies**: TASK-TRANSPORTX-006 (Error Taxonomy — Transport + Idempotency)
- **Status**: Pending

## Scope

Implement QoS violation error behavior (order/fill/risk not REALTIME per BR-013; COMMAND_IDEMPOTENT requires key per BR-014) and execution mode violation error behavior (REPLAY/DRY_RUN prevents real orders per BR-016). Audit error codes included as QoS/Mode gate enforcers.

## Non-Scope

- Common error struct and RetryClassFor mapping (TASK-TRANSPORTX-006)
- Auth/deadline/retry error behavior (TASK-TRANSPORTX-006b)
- Actual QoS routing logic (TASK-TRANSPORTX-007)
- Execution mode gating logic (TASK-TRANSPORTX-019)

## Files

- `errors/qos_errors.go` — TX_QOS_VIOLATION constructors
- `errors/mode_errors.go` — TX_MODE_VIOLATION, TX_AUDIT_MISSING, TX_AUDIT_DROPPED
- `errors/qos_mode_test.go` — QoS + Mode + Audit error tests

## Covered Error Codes (4)

TX_QOS_VIOLATION, TX_MODE_VIOLATION, TX_AUDIT_MISSING, TX_AUDIT_DROPPED

## Acceptance

- [ ] TX_QOS_VIOLATION raised when order/fill/risk use REALTIME_BEST_EFFORT (BR-013)
- [ ] TX_QOS_VIOLATION raised when COMMAND_IDEMPOTENT lacks idempotency key (BR-014)
- [ ] TX_MODE_VIOLATION raised when REPLAY/DRY_RUN attempts real order submission (BR-016)
- [ ] TX_AUDIT_MISSING raised when control command lacks audit evidence
- [ ] TX_AUDIT_DROPPED raised on audit delivery failure (not silently dropped)
- [ ] `go test ./errors/... -run TestQoSHardRules` passes
- [ ] `go test ./errors/... -run TestExecutionModeGates` passes
