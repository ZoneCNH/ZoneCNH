---
scope: "Audit Plane"
acceptance_criteria: []
---

# TASK-TRANSPORTX-021: Audit Plane

- **Module**: transportx
- **spec_ref**: module/transportx/SPEC.md#FR-023
- **BR_ref**: module/transportx/SPEC.md#BR-015

- **ACs**: AC-023
- **TCs**: TC-023
- **Phase**: Data Integrity (Phase 5)
- **Priority**: P2
- **Dependencies**: TASK-001 (Envelope), TASK-003 (Identity)
- **Status**: Pending

## Scope

Define AuditSink interface (Append) and ReplaySource interface (Replay). AuditRecord must contain recordId, traceId, correlationId, actor, action, target, result, timestamp, dataClass. Must NOT contain SECRET data. Audit events must not be silently dropped (BR-015).


## Non-Scope

Does NOT implement broker clients, storage drivers, business event semantics, or domain DTOs.

## Files

- `audit/audit_record.go` — AuditRecord struct
- `audit/audit_sink.go` — AuditSink interface
- `audit/replay_source.go` — ReplaySource interface + ReplayQuery
- `conformance/audit_test.go` — Audit append + replay tests

## Acceptance

- [ ] AuditSink.Append writes immutable audit record
- [ ] ReplaySource.Replay replays matching records in order
- [ ] Audit records contain trace_id, correlation_id
- [ ] SECRET data absent from audit records
- [ ] `go test ./conformance/... -run TestAuditPlane` passes

## Non-scope

- 不涉及本 Task 范围外的功能
