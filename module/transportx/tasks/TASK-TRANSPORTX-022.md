# TASK-TRANSPORTX-022: Data Classification + Redaction

- **Module**: transportx
- **Spec**: `module/transportx/SPEC.md` v1.1.1
- **FRs**: FR-024
- **ACs**: AC-024
- **TCs**: TC-024
- **Phase**: Data Integrity (Phase 5)
- **Priority**: P2
- **Dependencies**: TASK-012 (Middleware)
- **Status**: Pending

## Scope

Implement DataClass enum (PUBLIC, INTERNAL, CONFIDENTIAL, SECRET). CONFIDENTIAL and SECRET data must be redacted before logging/tracing. SECRET must never appear in audit or receipt. Redaction fail-closed: `TX_REDACTION_FAILED`.


## Non-Scope

Does NOT implement broker clients, storage drivers, business event semantics, or domain DTOs.

## Files

- `middleware/redaction.go` — Redaction middleware (enhanced)
- `data/classification.go` — DataClass enum + rules
- `middleware/redaction_test.go` — Data class redaction tests

## Acceptance

- [ ] PUBLIC data: no redaction required
- [ ] INTERNAL data: no redaction required
- [ ] CONFIDENTIAL data: redacted before logging/tracing export
- [ ] SECRET data: redacted; absent from audit, receipt, all telemetry
- [ ] Redaction failure → `TX_REDACTION_FAILED`, fail closed
- [ ] `go test ./middleware/... -run TestDataClassRedaction` passes
