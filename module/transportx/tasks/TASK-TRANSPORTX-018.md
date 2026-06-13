# TASK-TRANSPORTX-018: Idempotency

- **Module**: transportx
- **Spec**: `module/transportx/SPEC.md` v1.1.1
- **FRs**: FR-010
- **ACs**: AC-010
- **TCs**: TC-010
- **Phase**: Advanced Features (Phase 4)
- **Priority**: P1
- **Dependencies**: TASK-001 (Envelope), TASK-012 (Middleware)
- **Status**: Pending

## Scope

Implement idempotency middleware. Check idempotency key against stored keys. Collision with incompatible payload digest → `TX_IDEMPOTENCY_CONFLICT`. Must NOT publish duplicate work. Envelope id and idempotency key must be stable across retries (BR-007).


## Non-Scope

Does NOT implement broker clients, storage drivers, business event semantics, or domain DTOs.

## Files

- `middleware/idempotency.go` — Idempotency middleware
- `middleware/idempotency_test.go` — Conflict + duplicate prevention tests

## Acceptance

- [ ] Same idempotency_key + same digest → idempotent ack (no duplicate publish)
- [ ] Same idempotency_key + different digest → `TX_IDEMPOTENCY_CONFLICT`
- [ ] Envelope id and key stable across retries
- [ ] `go test ./middleware/... -run TestIdempotencyConflict` passes
