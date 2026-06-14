---
scope: "Conformance Suite"
acceptance_criteria: []
---

# TASK-TRANSPORTX-024: Conformance Suite

- **Module**: transportx
- **spec_ref**: module/transportx/SPEC.md#FR-016

- **ACs**: AC-016
- **TCs**: TC-001 through TC-025
- **Phase**: CI + Release (Phase 6)
- **Priority**: P2
- **Dependencies**: TASK-TRANSPORTX-001, TASK-TRANSPORTX-002, TASK-TRANSPORTX-003, TASK-TRANSPORTX-004, TASK-TRANSPORTX-005, TASK-TRANSPORTX-006, TASK-TRANSPORTX-007, TASK-TRANSPORTX-008, TASK-TRANSPORTX-009, TASK-TRANSPORTX-010, TASK-TRANSPORTX-011, TASK-TRANSPORTX-012, TASK-TRANSPORTX-013, TASK-TRANSPORTX-014, TASK-TRANSPORTX-015, TASK-TRANSPORTX-016, TASK-TRANSPORTX-017, TASK-TRANSPORTX-018, TASK-TRANSPORTX-019, TASK-TRANSPORTX-020, TASK-TRANSPORTX-021, TASK-TRANSPORTX-022
- **Status**: Pending

## Scope

Implement ConformanceSuite with four test groups: RunLifecycle, RunEnvelope, RunControlPlane, RunErrorTaxonomy. All 25 TCs must be executable via `go test ./conformance/...`. Integrate all previous task tests into unified suite.


## Non-Scope

Does NOT implement broker clients, storage drivers, business event semantics, or domain DTOs.

## Files

- `conformance/suite.go` — ConformanceSuite runner + report generator
- `conformance/core_test.go` — TC-001~005
- `conformance/control_security_test.go` — TC-006~016
- `conformance/registry_data_test.go` — TC-017~025
- `conformance/conformance_test.go` — Suite self-test

## Acceptance

- [ ] All 25 TCs pass in conformance suite
- [ ] Missing conformance evidence → CI blocks release (TX-GATE-005~012)
- [ ] Suite works against in-memory adapter for local testing
- [ ] Report output includes test counts, pass/fail, timing

## Non-scope

- 不涉及本 Task 范围外的功能
