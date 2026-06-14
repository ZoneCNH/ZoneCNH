---
scope: "Schema Compatibility"
acceptance_criteria: []
---

# TASK-TRANSPORTX-023: Schema Compatibility

- **Module**: transportx
- **spec_ref**: module/transportx/SPEC.md#FR-015 ,#FR-025
- **BR_ref**: module/transportx/SPEC.md#BR-011

- **ACs**: AC-015, AC-025
- **TCs**: TC-015, TC-025
- **Phase**: CI + Release (Phase 6)
- **Priority**: P2
- **Dependencies**: TASK-011 (SchemaRegistry)
- **Status**: Pending

## Scope

Schema compatibility checker + breaking change detection. Envelope/Endpoint/Receipt/ControlCommand schema changes classified as compatible or breaking. Breaking change → major version bump (BR-011). Implement rollback procedure per §21.


## Non-Scope

Does NOT implement broker clients, storage drivers, business event semantics, or domain DTOs.

## Files

- `registry/compatibility.go` — Enhanced compatibility checker
- `registry/compatibility_test.go` — Breaking change detection tests
- `docs/compatibility-notes.md` — Template for compatibility reports

## Acceptance

- [ ] Compatible change: minor/patch bump allowed
- [ ] Breaking change: returns incompatible classification
- [ ] Breaking change blocks release via TX-GATE-008
- [ ] Rollback: consumers pin previous version, adapters support both versions
- [ ] `go test ./registry/... -run TestSchemaBreakingChange` passes
- [ ] `go test ./registry/... -run TestSchemaCompatibility` passes

## Non-scope

- 不涉及本 Task 范围外的功能
