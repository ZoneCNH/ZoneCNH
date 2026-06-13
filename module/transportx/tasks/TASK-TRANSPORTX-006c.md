# TASK-TRANSPORTX-006c: Error Taxonomy — QoS + Mode

- **Module**: transportx
- **Spec**: `module/transportx/SPEC.md` v1.1.1
- **FRs**: FR-017, FR-021
- **ACs**: AC-017, AC-021
- **TCs**: TC-017, TC-021
- **Phase**: Foundation Contracts (Phase 1)
- **Priority**: P0
- **Dependencies**: TASK-006 (Error Taxonomy — Transport + Idempotency)
- **Status**: Pending

## Scope

Implement QoS violation error behavior (hard rules: order/fill/risk not REALTIME_BEST_EFFORT; COMMAND_IDEMPOTENT requires idempotency key) and Execution Mode violation error behavior (REPLAY/DRY_RUN prevents real order submission and external side effects). Audit errors (TX_AUDIT_MISSING, TX_AUDIT_DROPPED) are included as they gate QoS and Mode enforcement.

## Non-Scope

- Common error struct and RetryClassFor mapping (see TASK-006)
- Auth/deadline/retry error behavior (see TASK-006b)
- Actual QoS routing or mode gating logic (see TASK-015, TASK-018)

## Files

- `errors/qos_errors.go` — TX_QOS_VIOLATION constructors
- `errors/mode_errors.go` — TX_MODE_VIOLATION, TX_AUDIT_MISSING, TX_AUDIT_DROPPED constructors
- `errors/qos_mode_test.go` — QoS + Mode + Audit error tests

## Covered Error Codes

TX_QOS_VIOLATION, TX_MODE_VIOLATION, TX_AUDIT_MISSING, TX_AUDIT_DROPPED

## Acceptance

- [ ] TX_QOS_VIOLATION raised when order/fill/risk events use REALTIME_BEST_EFFORT
- [ ] TX_QOS_VIOLATION raised when COMMAND_IDEMPOTENT lacks idempotency key
- [ ] TX_MODE_VIOLATION raised when REPLAY/DRY_RUN attempts real order submission
- [ ] TX_AUDIT_MISSING raised when control command lacks audit evidence
- [ ] TX_AUDIT_DROPPED raised on audit delivery failure (not silently dropped)
- [ ] `go test ./errors/... -run TestQoSHardRules` passes
- [ ] `go test ./errors/... -run TestExecutionModeGates` passes
