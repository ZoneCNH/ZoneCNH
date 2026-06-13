# TASK-TRANSPORTX-024: Conformance Suite

- **Module**: transportx
- **Spec**: `module/transportx/SPEC.md` v1.1.1
- **FRs**: FR-016
- **ACs**: AC-016
- **TCs**: TC-001 through TC-025
- **Phase**: CI + Release (Phase 6)
- **Priority**: P2
- **Dependencies**: All Phase 1-5 tasks
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
