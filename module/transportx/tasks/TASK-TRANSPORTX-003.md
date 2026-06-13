# TASK-TRANSPORTX-003: ServiceIdentity

- **Module**: transportx
- **Spec**: `module/transportx/SPEC.md` v1.1.1
- **FRs**: FR-007
- **ACs**: AC-007
- **TCs**: TC-007
- **Phase**: Foundation Contracts (Phase 1)
- **Dependencies**: none
- **Status**: Pending

## Scope

Implement ServiceIdentity struct with service, environment, tenant, trustDomain, scopes, authnMethod, principal, issuedAt, expiresAt. Validation: reject missing or expired identity before adapter dispatch.

## Files

- `identity/identity.go` — ServiceIdentity struct + validation
- `identity/scopes.go` — Scope constants
- `identity/identity_test.go` — Missing/expired identity rejection tests

## Acceptance

- [ ] ServiceIdentity validation rejects empty service, tenant, trustDomain
- [ ] Expired ServiceIdentity rejected with `TX_AUTHN_REQUIRED`
- [ ] Missing auth context rejected before adapter dispatch
- [ ] `go test ./middleware/... -run TestIdentityValidation` passes
