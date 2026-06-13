# TASK-TRANSPORTX-006: Error Taxonomy

- **Module**: transportx
- **Spec**: `module/transportx/SPEC.md` v1.1.1
- **FRs**: FR-002, FR-008, FR-009, FR-010, FR-012, FR-013, FR-017, FR-021
- **ACs**: AC-002, AC-008, AC-009, AC-010, AC-012, AC-013, AC-017, AC-021
- **Phase**: Foundation Contracts (Phase 1)
- **Dependencies**: none
- **Status**: Pending

## Scope

Implement complete typed transport error taxonomy (23 error codes). Every error must include stable code, redacted message, retry classification, endpoint reference and trace id.

## Files

- `errors/codes.go` — All TX_* error code constants
- `errors/transport_error.go` — TransportError struct
- `errors/classification.go` — RetryClassFor(err) mapping
- `errors/errors_test.go` — Error construction + classification tests

## Key Error Codes

TX_PAYLOAD_LIMIT_EXCEEDED, TX_HEADER_LIMIT_EXCEEDED, TX_ENDPOINT_INVALID, TX_AUTHN_REQUIRED, TX_AUTHZ_DENIED, TX_DEADLINE_EXCEEDED, TX_CLOCK_SKEW, TX_IDEMPOTENCY_CONFLICT, TX_BACKPRESSURE, TX_BULKHEAD_REJECTED, TX_ADAPTER_FAILURE, TX_CONTROL_CONFLICT, TX_QOS_VIOLATION, TX_MODE_VIOLATION, TX_SCHEMA_INCOMPATIBLE, TX_TOPIC_DUPLICATE, TX_METHOD_DUPLICATE, TX_RETRY_UNSAFE, TX_REDACTION_FAILED, TX_AUDIT_MISSING, TX_AUDIT_DROPPED, TX_DLQ_INCOMPLETE, TX_MIRROR_IDEMPOTENCY_VIOLATION

## Acceptance

- [ ] All 23 error codes defined as typed constants
- [ ] TransportError includes code, message (redacted), retryClass, endpoint, traceId
- [ ] RetryClassFor maps each error to NONE/READ_ONLY/IDEMPOTENT/UNSAFE
- [ ] Error message never contains raw payload
