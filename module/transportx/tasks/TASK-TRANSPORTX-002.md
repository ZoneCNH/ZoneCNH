---
scope: "Endpoint Model + Registry"
acceptance_criteria: []
---

# TASK-TRANSPORTX-002: Endpoint Model + Registry

- **Module**: transportx
- **spec_ref**: module/transportx/SPEC.md#FR-003
- **BR_ref**: module/transportx/SPEC.md#BR-006

- **ACs**: AC-003
- **TCs**: TC-003
- **Phase**: Foundation Contracts (Phase 1)
- **Priority**: P0
- **Dependencies**: TASK-001 (Envelope)
- **Status**: Pending

## Scope

Implement Endpoint struct and EndpointRegistry interface with validation: scheme, authority, path, topic, partitionKeyPolicy, capabilities, tenantScope, owner, status, version.


## Non-Scope

Does NOT implement broker clients, HTTP/RPC servers, or domain-specific endpoint semantics.

## Files

- `endpoint/endpoint.go` — Endpoint struct + validation
- `endpoint/registry.go` — EndpointRegistry interface + default impl
- `endpoint/capability.go` — Capability flags
- `endpoint/endpoint_test.go` — Registration rejection tests

## Acceptance

- [ ] Endpoint.Register rejects invalid scheme, missing owner, unsupported capability
- [ ] Endpoint.Resolve returns correct Endpoint by name
- [ ] Endpoint.Deprecate marks endpoint status as deprecated
- [ ] `go test ./endpoint/... -run TestRegisterInvalid` passes

## Non-scope

- 不涉及本 Task 范围外的功能
