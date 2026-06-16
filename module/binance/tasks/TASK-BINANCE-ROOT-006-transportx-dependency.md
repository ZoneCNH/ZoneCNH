# TASK-BINANCE-ROOT-006 transportx Dependency

## Objective

Validate and document the dependency of `module/binance` on `module/transportx` for runtime transport policies, ensuring that gRPC streaming, retry/backoff, admin conventions, health/readiness, and auth/TLS recommendations are consistently applied.

## Scope

`module/transportx` owns cross-cutting transport policies that both `module/binance/client` and `module/binance/server` must follow. This task ensures the policies are documented as dependencies and applied consistently in the binance module's runtime implementation.

## Deliverables

- Dependency declaration in root SPEC.md referencing `module/transportx`
- Verification that the following transport policies are available and applicable:
  - gRPC streaming policy
  - Retry/backoff defaults
  - Gin admin conventions
  - Health/readiness conventions
  - Auth/TLS recommendations
- Documentation of how `module/binance` runtime will apply each policy

## Acceptance Criteria

1. gRPC streaming policy from transportx is identified and applicable to the binance client-server stream.
2. Retry/backoff defaults are documented and referenced in client task specs.
3. Gin admin conventions are documented and referenced in both client and server admin task specs.
4. Health/readiness conventions are documented and referenced in server task specs.
5. Auth/TLS recommendations are documented for production deployment guidance.

## Dependencies

- PR-001 (root docs established).
- `module/transportx` (external — must expose transport policy documentation).
