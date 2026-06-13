# TASK-TRANSPORTX-006: Error Taxonomy — Transport + Idempotency

- **Module**: transportx
- **Spec**: `module/transportx/SPEC.md` v1.1.1
- **FRs**: FR-002, FR-010, FR-012
- **ACs**: AC-002, AC-010, AC-012
- **TCs**: TC-002, TC-010, TC-012
- **Phase**: Foundation Contracts (Phase 1)
- **Priority**: P0
- **Dependencies**: none
- **Status**: Pending

## Scope

Implement typed transport error struct and common error codes. Every error must include stable code, redacted message, retry classification, endpoint reference and trace id. This task covers transport-level, idempotency, backpressure/bulkhead, adapter, control, schema, topic/method duplication, redaction and mirror error codes.

## Non-Scope

- Auth/authz deadline, clock skew, retry, DLQ error behavior (see TASK-006b)
- QoS and Execution Mode error behavior (see TASK-006c)
- Business error codes beyond the 23 transport error codes defined in SPEC §12
- Broker clients, HTTP/RPC servers, storage drivers, business event semantics

## Files

- `errors/codes.go` — All TX_* error code constants
- `errors/transport_error.go` — TransportError struct
- `errors/classification.go` — RetryClassFor(err) mapping
- `errors/errors_test.go` — Error construction + classification tests

## Covered Error Codes

TX_PAYLOAD_LIMIT_EXCEEDED, TX_HEADER_LIMIT_EXCEEDED, TX_ENDPOINT_INVALID, TX_IDEMPOTENCY_CONFLICT, TX_BACKPRESSURE, TX_BULKHEAD_REJECTED, TX_ADAPTER_FAILURE, TX_CONTROL_CONFLICT, TX_SCHEMA_INCOMPATIBLE, TX_TOPIC_DUPLICATE, TX_METHOD_DUPLICATE, TX_REDACTION_FAILED, TX_MIRROR_IDEMPOTENCY_VIOLATION

## Acceptance

- [ ] TransportError includes code, message (redacted), retryClass, endpoint, traceId
- [ ] All 13 transport/idempotency error codes defined as typed constants
- [ ] RetryClassFor maps each error to NONE/READ_ONLY/IDEMPOTENT/UNSAFE
- [ ] Error message never contains raw payload
- [ ] `go test ./errors/... -run TestTransportError` passes
- [ ] `go test ./errors/... -run TestRetryClassFor` passes
