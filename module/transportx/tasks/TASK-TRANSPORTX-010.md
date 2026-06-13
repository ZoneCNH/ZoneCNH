# TASK-TRANSPORTX-010: MethodRegistry

- **Module**: transportx
- **Spec**: `module/transportx/SPEC.md` v1.1.1
- **FRs**: FR-020
- **ACs**: AC-020
- **TCs**: TC-020
- **Phase**: QoS + Codec + Registry (Phase 2)
- **Dependencies**: TASK-006 (Errors)
- **Status**: Pending

## Scope

Implement MethodRegistry interface with Register, Resolve, RetryClass. Method naming: `{service}.{version}.{Service}/{Method}`. Validate deadline requirement, retry classification (READ_ONLY/IDEMPOTENT/UNSAFE), idempotency requirement.

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
