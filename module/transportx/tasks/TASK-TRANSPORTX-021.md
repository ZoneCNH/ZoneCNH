# TASK-TRANSPORTX-021: Audit Plane

- **Module**: transportx
- **Spec**: `module/transportx/SPEC.md` v1.1.1
- **FRs**: FR-023
- **ACs**: AC-023
- **TCs**: TC-023
- **Phase**: Data Integrity (Phase 5)
- **Dependencies**: TASK-001 (Envelope), TASK-003 (Identity)
- **Status**: Pending

## Scope

Define AuditSink interface (Append) and ReplaySource interface (Replay). AuditRecord must contain recordId, traceId, correlationId, actor, action, target, result, timestamp, dataClass. Must NOT contain SECRET data. Audit events must not be silently dropped (BR-015).

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
