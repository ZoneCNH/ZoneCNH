# TASK-TRANSPORTX-024: Conformance Suite

- **Module**: transportx
- **Spec**: `module/transportx/SPEC.md` v1.1.1
- **FRs**: FR-016
- **ACs**: AC-016
- **TCs**: TC-001 through TC-025
- **Phase**: CI + Release (Phase 6)
- **Dependencies**: All Phase 1-5 tasks
- **Status**: Pending

## Scope

Implement ConformanceSuite with four test groups: RunLifecycle, RunEnvelope, RunControlPlane, RunErrorTaxonomy. All 25 TCs must be executable via `go test ./conformance/...`. Integrate all previous task tests into unified suite.

## Files

- `conformance/suite.go` — ConformanceSuite runner
- `conformance/lifecycle_test.go` — TC-004, TC-005, TC-021
- `conformance/envelope_test.go` — TC-001, TC-002, TC-003
- `conformance/control_plane_test.go` — TC-006, TC-013
- `conformance/error_taxonomy_test.go` — Error code classification
- `conformance/qos_test.go` — TC-017
- `conformance/codec_test.go` — TC-018
- `conformance/registry_test.go` — TC-019, TC-020, TC-025
- `conformance/middleware_test.go` — TC-007, TC-008, TC-009, TC-010, TC-012, TC-014, TC-024
- `conformance/outbox_inbox_test.go` — TC-022
- `conformance/audit_test.go` — TC-023
- `conformance/receipt_test.go` — TC-011

## Acceptance

- [ ] All 25 TCs pass in conformance suite
- [ ] Missing conformance evidence → CI blocks release (TX-GATE-005~012)
- [ ] Suite works against in-memory adapter for local testing
- [ ] Report output includes test counts, pass/fail, timing
