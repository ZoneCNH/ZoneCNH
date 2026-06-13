# TASK-TRANSPORTX-013: Control Plane

- **Module**: transportx
- **spec_ref**: module/transportx/SPEC.md#FR-006
- **BR_ref**: module/transportx/SPEC.md#BR-003, #BR-005

- **ACs**: AC-006
- **TCs**: TC-006
- **Priority**: P1
- **Phase**: Middleware + Control (Phase 3)
- **Priority**: P1
- **Dependencies**: TASK-004 (Runtime Lifecycle)
- **Status**: Pending

## Scope

Implement ControlPlane interface with Apply, Rollback, Snapshot, Audit. Operations: kill switch, pause, resume, mirror, canary, rate-limit. Every command must persist commandId, actor, timestamp, target, previousState, newState, rollbackToken (BR-003). Mirror and canary operations must preserve idempotency key semantics (BR-005).


## Non-Scope

Does NOT implement durable audit store backend (deferred per SPEC OQ-2).

## Files

- `control/control_plane.go` — ControlPlane interface
- `control/command.go` — ControlCommand struct
- `control/operations.go` — Operation types + apply logic
- `control/audit.go` — Audit event emission
- `control/control_plane_test.go` — Command audit + rollback tests

## Acceptance

- [ ] Apply persists command with all required fields
- [ ] Rollback restores previous state via rollback token
- [ ] Snapshot captures current control state
- [ ] Audit event emitted for every command (BR-003)
- [ ] `go test ./control/... -run TestCommandAudit` passes
