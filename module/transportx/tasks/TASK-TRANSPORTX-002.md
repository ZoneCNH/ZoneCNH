# TASK-TRANSPORTX-002: Endpoint Model + Registry

- **Module**: transportx
- **Spec**: `module/transportx/SPEC.md` v1.1.1
- **FRs**: FR-003
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
