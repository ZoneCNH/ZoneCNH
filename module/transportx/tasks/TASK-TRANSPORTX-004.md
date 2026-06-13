# TASK-TRANSPORTX-004: Runtime Lifecycle + Drain

- **Module**: transportx
- **Spec**: `module/transportx/SPEC.md` v1.1.1
- **FRs**: FR-004, FR-005
- **ACs**: AC-004, AC-005
- **TCs**: TC-004, TC-005
- **Phase**: Foundation Contracts (Phase 1)
- **Priority**: P0
- **Dependencies**: none
- **Status**: Pending

## Scope

Implement TransportRuntime interface with state machine (new → starting → running → paused → draining → stopped) and Drain semantics. Enforce forbidden transitions. Drain must stop accepting new work, finish in-flight within deadline, report counts.


## Non-Scope

Does NOT implement a scheduler, service mesh, or API gateway.

## Files

- `runtime/runtime.go` — TransportRuntime interface
- `runtime/state.go` — State enum + transition table
- `runtime/drain.go` — DrainResult + drain logic
- `runtime/runtime_test.go` — Lifecycle transition tests
- `runtime/drain_test.go` — Drain report tests

## Acceptance

- [ ] All allowed transitions execute without error
- [ ] Forbidden transitions (paused→running w/o Resume, draining→running, stopped→*) rejected
- [ ] ForceStop from any state → stopped (abandoned)
- [ ] Drain report includes accepted, completed, abandoned, timed-out counts
- [ ] `go test ./runtime/... -run TestLifecycleTransitions` passes
- [ ] `go test ./runtime/... -run TestDrainReport` passes
