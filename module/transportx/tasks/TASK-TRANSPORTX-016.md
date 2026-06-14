---
scope: "Authorization Middleware"
acceptance_criteria: []
---

# TASK-TRANSPORTX-016: Authorization Middleware

- **Module**: transportx
- **spec_ref**: module/transportx/SPEC.md#FR-008

- **BR_ref**: module/transportx/SPEC.md#BR-009
- **ACs**: AC-008
- **TCs**: TC-008
- **Phase**: Advanced Features (Phase 4)
- **Priority**: P1
- **Dependencies**: TASK-003 (Identity), TASK-012 (Middleware)
- **Status**: Pending

## Scope

Implement authorization middleware. Validate ServiceIdentity scopes against Endpoint requirements. Deny with `TX_AUTHZ_DENIED` + audit event. Must not expose endpoint secrets or payload bytes.


## Non-Scope

Does NOT implement broker clients, storage drivers, business event semantics, or domain DTOs.

## Files

- `middleware/auth.go` — Auth middleware
- `middleware/auth_test.go` — Scope denial + no-leak tests

## Acceptance

- [ ] Missing scope → `TX_AUTHZ_DENIED`
- [ ] Tenant permission violation → `TX_AUTHZ_DENIED`
- [ ] Error response contains no payload bytes or endpoint secrets
- [ ] Audit event emitted on denial
- [ ] `go test ./middleware/... -run TestAuthzDenialNoLeak` passes

## Non-scope

- 不涉及本 Task 范围外的功能
