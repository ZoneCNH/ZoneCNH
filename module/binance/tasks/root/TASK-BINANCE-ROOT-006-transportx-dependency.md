# TASK-BINANCE-ROOT-006 transportx Dependency

## Objective

Validate and document the dependency of `module/binance` on `module/transportx` for runtime transport policies, ensuring that admin conventions, HTTP readiness, retry/backoff, and auth/TLS recommendations are consistently applied.

## Scope

`module/transportx` owns cross-cutting transport policies that both `module/binance/client` and `module/binance/server` must follow for HTTP/admin surfaces and deployment transport guidance. The active event pipeline uses `natsx` JetStream rather than transportx-owned gRPC streaming.

## Deliverables

- Dependency declaration in root SPEC.md referencing `module/transportx`
- Verification that the following transport policies are available and applicable:
  - Retry/backoff defaults
  - Gin admin conventions
  - Health/readiness conventions
  - Auth/TLS recommendations
  - HTTP timeout and shutdown guidance where applicable
- Documentation of how `module/binance` runtime will apply each policy

## Acceptance Criteria

1. `natsx` is documented as the event transport for the binance client-server pipeline.
2. Retry/backoff defaults are documented for Binance exchange connectors, `natsx` publishing, and HTTP/admin clients where applicable.
3. Gin admin conventions are documented and referenced in both client and server admin task specs.
4. Health/readiness conventions are documented and referenced in server task specs.
5. Auth/TLS recommendations are documented for production deployment guidance.

## Dependencies

- PR-001 (root docs established).
- `module/transportx` (external — must expose transport policy documentation).
