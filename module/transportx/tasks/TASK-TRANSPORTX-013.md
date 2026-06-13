# TASK-TRANSPORTX-013: Control Plane

- **Module**: transportx
- **Spec**: `module/transportx/SPEC.md` v1.1.1
- **FRs**: FR-006
- **ACs**: AC-006
- **TCs**: TC-006
- **Phase**: Middleware + Control (Phase 3)
- **Dependencies**: TASK-004 (Runtime Lifecycle)
- **Status**: Pending

## Scope

Implement ControlPlane interface with Apply, Rollback, Snapshot, Audit. Operations: kill switch, pause, resume, mirror, canary, rate-limit. Every command must persist commandId, actor, timestamp, target, previousState, newState, rollbackToken.

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
- [ ] Audit event emitted for every command
- [ ] `go test ./control/... -run TestCommandAudit` passes
