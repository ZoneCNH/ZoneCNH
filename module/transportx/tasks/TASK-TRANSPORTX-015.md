# TASK-TRANSPORTX-015: Retry + Dead Letter

- **Module**: transportx
- **Spec**: `module/transportx/SPEC.md` v1.1.1
- **FRs**: FR-013
- **ACs**: AC-013
- **TCs**: TC-013
- **Phase**: Middleware + Control (Phase 3)
- **Priority**: P1
- **Dependencies**: TASK-006 (Errors), TASK-012 (Middleware)
- **Status**: Pending

## Scope

Implement bounded retry with configurable policy and dead-letter routing. DLQ records must retain trace context, redacted failure metadata, attempt count, original message id. DLQPolicy: enabled, maxAttempts, topicSuffix, includePayload, includeError.


## Non-Scope

Does NOT implement broker clients, storage drivers, business event semantics, or domain DTOs.

## Files

- `middleware/retry.go` — Retry middleware
- `middleware/dlq.go` — DLQ router + DLQPolicy
- `middleware/retry_test.go` — Retry exhaustion + DLQ tests

## Acceptance

- [ ] Retryable failure → bounded retry applied
- [ ] Retry exhaustion → route to dead-letter with trace context
- [ ] DLQ record missing trace context → `TX_DLQ_INCOMPLETE`
- [ ] DLQ runbook: view, replay, skip, mark resolved
- [ ] `go test ./middleware/... -run TestDLQWithTrace` passes
