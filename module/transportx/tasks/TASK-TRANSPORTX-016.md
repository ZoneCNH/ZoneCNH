# TASK-TRANSPORTX-016: Authorization Middleware

- **Module**: transportx
- **Spec**: `module/transportx/SPEC.md` v1.1.1
- **FRs**: FR-008
- **ACs**: AC-008
- **TCs**: TC-008
- **Phase**: Advanced Features (Phase 4)
- **Dependencies**: TASK-003 (Identity), TASK-012 (Middleware)
- **Status**: Pending

## Scope

Implement authorization middleware. Validate ServiceIdentity scopes against Endpoint requirements. Deny with `TX_AUTHZ_DENIED` + audit event. Must not expose endpoint secrets or payload bytes.

## Files

- `middleware/auth.go` — Auth middleware
- `middleware/auth_test.go` — Scope denial + no-leak tests

## Acceptance

- [ ] Missing scope → `TX_AUTHZ_DENIED`
- [ ] Tenant permission violation → `TX_AUTHZ_DENIED`
- [ ] Error response contains no payload bytes or endpoint secrets
- [ ] Audit event emitted on denial
- [ ] `go test ./middleware/... -run TestAuthzDenialNoLeak` passes
