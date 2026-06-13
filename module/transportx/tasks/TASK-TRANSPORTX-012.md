# TASK-TRANSPORTX-012: Middleware Chain + Redaction Order

- **Module**: transportx
- **Spec**: `module/transportx/SPEC.md` v1.1.1
- **FRs**: FR-014
- **ACs**: AC-014
- **TCs**: TC-014
- **Phase**: Middleware + Control (Phase 3)
- **Priority**: P1
- **Dependencies**: TASK-001 (Envelope), TASK-003 (Identity), TASK-006 (Errors)
- **Status**: Pending

## Scope

Implement middleware Chain and 14 individual middleware in enforced order: Recover → ValidateEnvelope → InjectServiceIdentity → TracePropagate → Metrics → Logging → Redaction → Deadline → Auth → Idempotency → RetrySafety → RateLimit → CircuitBreaker → Codec → Adapter. Redaction MUST execute before Logging and Tracing.


## Non-Scope

Does NOT implement broker clients, storage drivers, business event semantics, or domain DTOs.

## Files

- `middleware/chain.go` — Chain function + Handler type
- `middleware/pre.go` — Recover + ValidateEnvelope + InjectServiceIdentity + TracePropagate
- `middleware/processing.go` — Metrics + Logging + Redaction + Deadline
- `middleware/security.go` — Auth + Idempotency + RetrySafety + RateLimit + CircuitBreaker
- `middleware/middleware_test.go` — Chain order + redaction order tests

## Acceptance

- [ ] Chain executes middleware in correct order
- [ ] Redaction executes before Logging and Tracing receive stringified fields
- [ ] Redaction failure → fail closed (block logging + adapter dispatch)
- [ ] `go test ./middleware/... -run TestRedactionOrder` passes
