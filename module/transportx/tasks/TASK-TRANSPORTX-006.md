# TASK-TRANSPORTX-006: Error Taxonomy — Transport + Idempotency

- **Module**: transportx
- **spec_ref**: module/transportx/SPEC.md#FR-002 ,#FR-010 ,#FR-012
- **BR_ref**: module/transportx/SPEC.md#BR-007
- **ACs**: AC-002, AC-010, AC-012
- **Phase**: Foundation Contracts (Phase 1)
- **Priority**: P0
- **Dependencies**: none
- **Status**: Pending

## Scope

Implement typed transport error struct and core error code constants (13 codes). Every error must include stable code, redacted message, retry classification, endpoint reference and trace id. Covers transport-level, idempotency, backpressure/bulkhead, adapter, control, schema, topic/method, redaction and mirror errors.

## Non-Scope

- Auth/deadline/retry/DLQ errors (TASK-TRANSPORTX-006b)
- QoS and execution mode errors (TASK-TRANSPORTX-006c)
- Business error codes beyond 23 transport codes
- Broker clients, HTTP/RPC servers, storage drivers, domain DTOs

## Files

- `errors/codes.go` — All TX_* error code constants (13 core)
- `errors/transport_error.go` — TransportError struct
- `errors/classification.go` — RetryClassFor(err) mapping (BR-007)
- `errors/errors_test.go` — Error construction + classification tests

## Covered Error Codes (13)

TX_PAYLOAD_LIMIT_EXCEEDED, TX_HEADER_LIMIT_EXCEEDED, TX_ENDPOINT_INVALID, TX_IDEMPOTENCY_CONFLICT, TX_BACKPRESSURE, TX_BULKHEAD_REJECTED, TX_ADAPTER_FAILURE, TX_CONTROL_CONFLICT, TX_SCHEMA_INCOMPATIBLE, TX_TOPIC_DUPLICATE, TX_METHOD_DUPLICATE, TX_REDACTION_FAILED, TX_MIRROR_IDEMPOTENCY_VIOLATION

## Acceptance

- [ ] TransportError includes code, message (redacted), retryClass, endpoint, traceId
- [ ] All 13 core error codes defined as typed constants
- [ ] RetryClassFor maps each error to NONE/READ_ONLY/IDEMPOTENT/UNSAFE (BR-007)
- [ ] Error message never contains raw payload
- [ ] `go test ./errors/... -run TestTransportError` passes
- [ ] `go test ./errors/... -run TestRetryClassFor` passes
