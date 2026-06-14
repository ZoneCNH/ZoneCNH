---
scope: "MethodRegistry"
acceptance_criteria: []
---

# TASK-TRANSPORTX-010: MethodRegistry

- **Module**: transportx
- **spec_ref**: module/transportx/SPEC.md#FR-020
- **BR_ref**: module/transportx/SPEC.md#BR-017

- **ACs**: AC-020
- **TCs**: TC-020
- **Phase**: QoS + Codec + Registry (Phase 2)
- **Priority**: P0
- **Dependencies**: TASK-006 (Errors)
- **Status**: Pending

## Scope

Implement MethodRegistry interface with Register, Resolve, RetryClass. Method naming: `{service}.{version}.{Service}/{Method}`. Validate deadline requirement, retry classification (READ_ONLY/IDEMPOTENT/UNSAFE), idempotency requirement.


## Non-Scope

Does NOT implement broker clients, storage drivers, or business event semantics.

## Files

- `registry/method.go` — Method struct
- `registry/method_registry.go` — MethodRegistry interface + in-memory impl
- `registry/method_registry_test.go` — Retry class + duplicate rejection tests

## Acceptance

- [ ] Method.Register validates naming `{service}.{version}.{Service}/{Method}`
- [ ] Duplicate method name → `TX_METHOD_DUPLICATE`
- [ ] UNSAFE method without explicit retry opt-out rejected
- [ ] RetryClass(method) returns correct classification
- [ ] `go test ./registry/... -run TestMethodRetryClass` passes

## Non-scope

- 不涉及本 Task 范围外的功能
