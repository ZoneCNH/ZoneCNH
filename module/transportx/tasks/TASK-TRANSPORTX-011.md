---
scope: "SchemaRegistry"
acceptance_criteria: []
---

# TASK-TRANSPORTX-011: SchemaRegistry

- **Module**: transportx
- **spec_ref**: module/transportx/SPEC.md#FR-025

- **BRs**: BR-006, BR-011
- **ACs**: AC-025
- **TCs**: TC-025
- **Phase**: QoS + Codec + Registry (Phase 2)
- **Priority**: P0
- **Dependencies**: TASK-001 (Envelope), TASK-002 (Endpoint), TASK-005 (Receipt)
- **Status**: Pending

## Scope

Implement SchemaRegistry interface with Register, CheckCompatibility, Versions. Record schema version, digest, compatibility classification (compatible/breaking), migration notes. Reject unknown versions with `TX_SCHEMA_INCOMPATIBLE`.


## Non-Scope

Does NOT implement standalone SchemaRegistry service (embedded library for v1.x per SPEC OQ-3).

## Files

- `registry/schema.go` — Schema struct
- `registry/schema_registry.go` — SchemaRegistry interface + in-memory impl
- `registry/compatibility.go` — CompatibilityResult type + checker
- `registry/schema_registry_test.go` — Compatibility + version tests

## Acceptance

- [ ] Schema.Register records version, digest, classification, migration notes
- [ ] Breaking change returns incompatible classification (BR-011)
- [ ] Adapter fields in namespaced extensions (BR-006)
- [ ] Unknown version → `TX_SCHEMA_INCOMPATIBLE`
- [ ] `go test ./registry/... -run TestSchemaCompatibility` passes

## Non-scope

- 不涉及本 Task 范围外的功能
