# TASK-TRANSPORTX-012: Middleware Chain + Redaction Order

- **Module**: transportx
- **Spec**: `module/transportx/SPEC.md` v1.1.1
- **FRs**: FR-014
- **ACs**: AC-014
- **TCs**: TC-014
- **Phase**: Middleware + Control (Phase 3)
- **Dependencies**: TASK-001 (Envelope), TASK-003 (Identity), TASK-006 (Errors)
- **Status**: Pending

## Scope

Implement middleware Chain and 14 individual middleware in enforced order: Recover → ValidateEnvelope → InjectServiceIdentity → TracePropagate → Metrics → Logging → Redaction → Deadline → Auth → Idempotency → RetrySafety → RateLimit → CircuitBreaker → Codec → Adapter. Redaction MUST execute before Logging and Tracing.

## Files

- `middleware/chain.go` — Chain() function
- `middleware/handler.go` — Handler type
- `middleware/recover.go`, `validate.go`, `identity.go`, `trace.go`
- `middleware/metrics.go`, `logging.go`, `redaction.go`
- `middleware/deadline.go`, `auth.go`, `idempotency.go`
- `middleware/retry_safety.go`, `ratelimit.go`, `circuit.go`
- `middleware/middleware_test.go` — Redaction order test

## Acceptance

- [ ] Chain executes middleware in correct order
- [ ] Redaction executes before Logging and Tracing receive stringified fields
- [ ] Redaction failure → fail closed (block logging + adapter dispatch)
- [ ] `go test ./middleware/... -run TestRedactionOrder` passes
