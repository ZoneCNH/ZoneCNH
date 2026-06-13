# TASK-TRANSPORTX-006b: Error Taxonomy — Auth + Deadline + Retry

- **Module**: transportx
- **Spec**: `module/transportx/SPEC.md` v1.1.1
- **FRs**: FR-008, FR-009, FR-013
- **ACs**: AC-008, AC-009, AC-013
- **TCs**: TC-008, TC-009, TC-013
- **Phase**: Foundation Contracts (Phase 1)
- **Priority**: P0
- **Dependencies**: TASK-006 (Error Taxonomy — Transport + Idempotency)
- **Status**: Pending

## Scope

Implement auth error behavior (AUTHN_REQUIRED, AUTHZ_DENIED must not leak secrets), deadline error behavior (DEADLINE_EXCEEDED and CLOCK_SKEW distinct codes for each branch), and retry/DLQ error behavior (DLQ records retain trace context, retry class enforces UNSAFE no-auto-retry).

## Non-Scope

- Common error struct and RetryClassFor mapping (see TASK-006)
- QoS and Execution Mode error behavior (see TASK-006c)
- Envelope-level payload/header limit enforcement (see TASK-001)

## Files

- `errors/auth_errors.go` — TX_AUTHN_REQUIRED, TX_AUTHZ_DENIED constructors
- `errors/deadline_errors.go` — TX_DEADLINE_EXCEEDED, TX_CLOCK_SKEW constructors
- `errors/retry_errors.go` — TX_DLQ_INCOMPLETE, TX_RETRY_UNSAFE constructors
- `errors/auth_deadline_retry_test.go` — Auth + deadline + retry error tests

## Covered Error Codes

TX_AUTHN_REQUIRED, TX_AUTHZ_DENIED, TX_DEADLINE_EXCEEDED, TX_CLOCK_SKEW, TX_DLQ_INCOMPLETE, TX_RETRY_UNSAFE

## Acceptance

- [ ] TX_AUTHZ_DENIED error message must not contain endpoint secrets or payload bytes
- [ ] TX_DEADLINE_EXCEEDED and TX_CLOCK_SKEW produce distinct error codes from separate code paths
- [ ] TX_DLQ_INCOMPLETE records retain trace context and redacted failure metadata
- [ ] TX_RETRY_UNSAFE enforces no-auto-retry on UNSAFE methods
- [ ] `go test ./errors/... -run TestAuthzDenialNoLeak` passes
- [ ] `go test ./errors/... -run TestDeadlineAndSkew` passes
- [ ] `go test ./errors/... -run TestDLQWithTrace` passes
