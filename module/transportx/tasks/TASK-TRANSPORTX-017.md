# TASK-TRANSPORTX-017: Deadline + Clock Skew

- **Module**: transportx
- **Spec**: `module/transportx/SPEC.md` v1.1.1
- **FRs**: FR-009
- **ACs**: AC-009
- **TCs**: TC-009
- **Phase**: Advanced Features (Phase 4)
- **Dependencies**: TASK-001 (Envelope), TASK-012 (Middleware)
- **Status**: Pending

## Scope

Implement deadline enforcement and clock skew detection. Use monotonic runtime clock + wall-clock skew guard (`tx.clock_skew.max_ms`). Return `TX_DEADLINE_EXCEEDED` or `TX_CLOCK_SKEW`.

## Files

- `middleware/deadline.go` — Deadline middleware
- `clock/clock.go` — Monotonic clock wrapper
- `middleware/deadline_test.go` — Deadline + skew tests

## Acceptance

- [ ] Expired deadline → `TX_DEADLINE_EXCEEDED`, reject or dead-letter
- [ ] Clock skew exceeds guard → `TX_CLOCK_SKEW`
- [ ] Deadline and skew branches produce distinct error codes
- [ ] `go test ./middleware/... -run TestDeadlineAndSkew` passes
