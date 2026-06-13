# TASK-TRANSPORTX-006b: Error Taxonomy — Auth + Deadline + Retry

- **Module**: transportx
- **spec_ref**: module/transportx/SPEC.md#FR-008 ,#FR-009 ,#FR-013
- **BR_ref**: module/transportx/SPEC.md#BR-008 ,#BR-009 ,#BR-010 ,#BR-017
- **ACs**: AC-008, AC-009, AC-013
- **Phase**: Foundation Contracts (Phase 1)
- **Priority**: P0
- **Dependencies**: TASK-TRANSPORTX-006 (Error Taxonomy — Transport + Idempotency)
- **Status**: Pending

## Scope

Implement auth error behavior (AUTHZ_DENIED must not leak secrets per BR-009), deadline error behavior (DEADLINE_EXCEEDED and CLOCK_SKEW distinct codes per BR-008), and retry/DLQ error behavior (DLQ retains trace per BR-010, UNSAFE no-auto-retry per BR-017).

## Non-Scope

- Common error struct and RetryClassFor mapping (TASK-TRANSPORTX-006)
- QoS and execution mode error behavior (TASK-TRANSPORTX-006c)
- Envelope-level payload/header limit enforcement (TASK-TRANSPORTX-001)

## Files

- `errors/auth_errors.go` — TX_AUTHN_REQUIRED, TX_AUTHZ_DENIED
- `errors/deadline_errors.go` — TX_DEADLINE_EXCEEDED, TX_CLOCK_SKEW
- `errors/retry_errors.go` — TX_DLQ_INCOMPLETE, TX_RETRY_UNSAFE
- `errors/auth_deadline_retry_test.go` — Auth + deadline + retry tests

## Covered Error Codes (6)

TX_AUTHN_REQUIRED, TX_AUTHZ_DENIED, TX_DEADLINE_EXCEEDED, TX_CLOCK_SKEW, TX_DLQ_INCOMPLETE, TX_RETRY_UNSAFE

## Acceptance

- [ ] TX_AUTHZ_DENIED error message must not contain endpoint secrets or payload bytes (BR-009)
- [ ] TX_DEADLINE_EXCEEDED and TX_CLOCK_SKEW produce distinct error codes (BR-008)
- [ ] TX_DLQ_INCOMPLETE records retain trace context (BR-010)
- [ ] TX_RETRY_UNSAFE enforces no-auto-retry on UNSAFE methods (BR-017)
- [ ] `go test ./errors/... -run TestAuthzDenialNoLeak` passes
- [ ] `go test ./errors/... -run TestDeadlineAndSkew` passes
- [ ] `go test ./errors/... -run TestDLQWithTrace` passes
