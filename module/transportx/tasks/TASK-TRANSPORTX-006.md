# TASK-TRANSPORTX-006: Error Taxonomy

- **Module**: transportx
- **spec_ref**: module/transportx/SPEC.md#FR-002 ,#FR-008 ,#FR-009 ,#FR-010 ,#FR-012 ,#FR-013 ,#FR-017 ,#FR-021

- **ACs**: AC-002, AC-008, AC-009, AC-010, AC-012, AC-013, AC-017, AC-021
- **Phase**: Foundation Contracts (Phase 1)
- **Priority**: P0
- **Dependencies**: none
- **Status**: Pending

## Scope

Implement the complete typed transport error taxonomy with all 23 error codes. Every error must include stable code, redacted message, retry classification, endpoint reference and trace id. Covers transport-level, idempotency, auth, deadline/clock-skew, retry/DLQ, backpressure/bulkhead, adapter, control, schema, topic/method duplication, redaction, QoS, execution mode, audit, and mirror error codes.

## Non-Scope

Does NOT implement business error codes beyond the 23 transport error codes defined in SPEC §12. Does NOT implement broker clients, HTTP/RPC servers, storage drivers, business event semantics, domain DTOs, or business orchestration.

## Files

- `errors/codes.go` — All 23 TX_* error code constants
- `errors/transport_error.go` — TransportError struct
- `errors/classification.go` — RetryClassFor(err) mapping
- `errors/errors_test.go` — Error construction + classification tests

## Covered Error Codes (23)

**Transport + Idempotency (13):** TX_PAYLOAD_LIMIT_EXCEEDED, TX_HEADER_LIMIT_EXCEEDED, TX_ENDPOINT_INVALID, TX_IDEMPOTENCY_CONFLICT, TX_BACKPRESSURE, TX_BULKHEAD_REJECTED, TX_ADAPTER_FAILURE, TX_CONTROL_CONFLICT, TX_SCHEMA_INCOMPATIBLE, TX_TOPIC_DUPLICATE, TX_METHOD_DUPLICATE, TX_REDACTION_FAILED, TX_MIRROR_IDEMPOTENCY_VIOLATION

**Auth + Deadline + Retry (6):** TX_AUTHN_REQUIRED, TX_AUTHZ_DENIED, TX_DEADLINE_EXCEEDED, TX_CLOCK_SKEW, TX_DLQ_INCOMPLETE, TX_RETRY_UNSAFE

**QoS + Mode + Audit (4):** TX_QOS_VIOLATION, TX_MODE_VIOLATION, TX_AUDIT_MISSING, TX_AUDIT_DROPPED

## Acceptance

- [ ] TransportError includes code, message (redacted), retryClass, endpoint, traceId
- [ ] All 23 error codes defined as typed constants
- [ ] RetryClassFor maps each error to NONE/READ_ONLY/IDEMPOTENT/UNSAFE
- [ ] Error message never contains raw payload
- [ ] TX_AUTHZ_DENIED error message must not contain endpoint secrets or payload bytes
- [ ] TX_DEADLINE_EXCEEDED and TX_CLOCK_SKEW produce distinct error codes from separate code paths
- [ ] TX_DLQ_INCOMPLETE records retain trace context and redacted failure metadata
- [ ] TX_RETRY_UNSAFE enforces no-auto-retry on UNSAFE methods
- [ ] TX_QOS_VIOLATION raised when order/fill/risk events use REALTIME_BEST_EFFORT
- [ ] TX_QOS_VIOLATION raised when COMMAND_IDEMPOTENT lacks idempotency key
- [ ] TX_MODE_VIOLATION raised when REPLAY/DRY_RUN attempts real order submission
- [ ] TX_AUDIT_MISSING raised when control command lacks audit evidence
- [ ] TX_AUDIT_DROPPED raised on audit delivery failure (not silently dropped)
- [ ] `go test ./errors/... -run TestTransportError` passes
- [ ] `go test ./errors/... -run TestRetryClassFor` passes
- [ ] `go test ./errors/... -run TestAuthzDenialNoLeak` passes
- [ ] `go test ./errors/... -run TestDeadlineAndSkew` passes
- [ ] `go test ./errors/... -run TestDLQWithTrace` passes
- [ ] `go test ./errors/... -run TestQoSHardRules` passes
- [ ] `go test ./errors/... -run TestExecutionModeGates` passes
