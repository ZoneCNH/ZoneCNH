# TASK-TRANSPORTX-001: Envelope Schema + Payload Limits

- **Module**: transportx
- **Spec**: `module/transportx/SPEC.md` v1.1.1
- **FRs**: FR-001, FR-002
- **ACs**: AC-001, AC-002
- **TCs**: TC-001, TC-002
- **Phase**: Foundation Contracts (Phase 1)
- **Dependencies**: none
- **Status**: Pending

## Scope

Implement Envelope struct with required fields (id, type, schemaVersion, source, endpoint, tenant, createdAt, deadlineAt, traceContext, idempotencyKey, headers, payloadRef, payloadDigest) and payload/header limit enforcement.

## Files

- `envelope/envelope.go` — Envelope struct + validation
- `envelope/header.go` — Header type
- `envelope/payload_ref.go` — PayloadRef + PayloadDigest
- `envelope/limits.go` — Payload/header limit config + check
- `envelope/envelope_test.go` — Required field rejection tests
- `envelope/limits_test.go` — Limit boundary tests

## Acceptance

- [ ] Envelope validation rejects missing id, type, source, endpoint, timestamp, deadlineAt, traceContext, payloadRef
- [ ] Payload exceeds `tx.payload.max_bytes` → `TX_PAYLOAD_LIMIT_EXCEEDED`
- [ ] Header count exceeds `tx.header.max_count` → `TX_HEADER_LIMIT_EXCEEDED`
- [ ] Header bytes exceed `tx.header.max_bytes` → `TX_HEADER_LIMIT_EXCEEDED`
- [ ] `go test ./envelope/... -run TestValidateRequired` passes
- [ ] `go test ./envelope/... -run TestLimits` passes
