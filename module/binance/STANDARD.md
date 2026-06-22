# module/binance STANDARD.md — Runtime Control Standard

## Metadata

| Field | Value |
| --- | --- |
| Status | Draft |
| Doc-Version | v0.1.0 |
| Last-Updated | 2026-06-22 |
| Scope | `module/binance` runtime control and evidence standard |
| Spec-Impact | None until FR-024 is promoted into `SPEC.md` |

> [FRAME, HIGH] This document is the thin standard entry for runtime control work. It is not a replacement for `SPEC.md`, `TRACEABILITY.md`, `ACCEPTANCE.md`, or `RUNTIME-MAPPING.md`.

## 1. Scope

[FRAME, HIGH] The standard covers symbol catalog reload, runtime stream-diff behavior, release evidence, and document synchronization for future FR-024 work.

[FRAME, HIGH] The standard does not approve a release, create a new event type, alter the 4 product-line by 4 event-type matrix, or authorize credentials, live trading endpoints, or production rollout.

## 2. Hot Reload Contract

[COMPUTED, HIGH] The current local runtime evidence path is `POST /api/v1/admin/symbols/reload` in `/home/binance/internal/client/admin.go`.

[FRAME, HIGH] FR-024 must not be marked done until the runtime proves all of the following:

| Requirement | Evidence required |
| --- | --- |
| Method boundary | Non-POST requests return 405 with `Allow: POST` |
| Payload boundary | Unknown fields and invalid catalog entries are rejected |
| Atomic catalog swap | A valid request replaces the local catalog without process restart |
| Stream diff | Added symbols start new streams and removed symbols drain existing streams |
| Existing stream continuity | Unchanged active streams remain connected during reload |
| Rollback path | Failed reload leaves the previous catalog and active stream set intact |
| Auditability | Reload count, rejected entry count, and stream add/remove counts are observable |

[FRAME, HIGH] Older planning references to `/api/v1/admin/catalog/reload` must be reconciled with the current `POST /api/v1/admin/symbols/reload` runtime path before `RUNTIME-MAPPING.md` or `SPEC.md` can claim FR-024 completion.

## 3. Evidence Gates

[COMPUTED, HIGH] Current local runtime tests cover successful catalog reload, invalid method, and invalid payload.

[FRAME, HIGH] Full FR-024 evidence still requires an integration test or smoke test that demonstrates active stream add/remove without restarting the client process.

[FRAME, HIGH] Release evidence for this standard must include:

| Gate | Minimum evidence |
| --- | --- |
| Unit | admin reload success, method rejection, payload rejection |
| Integration | active stream add/remove, unchanged stream continuity, rollback on reload failure |
| Boundary | `./scripts/boundary-gates.sh` passes all gates |
| Runtime | `go test ./...`, `golangci-lint run`, and smoke self-test pass |
| Release | `TRACEABILITY.md`, `ACCEPTANCE.md`, `FEATURES.md`, and release evidence archive reference the same result |

## 4. Document Synchronization

[FRAME, HIGH] When FR-024 lands, update these files in the same PR or explicitly block the PR:

| File | Required update |
| --- | --- |
| `SPEC.md` | FR-024 requirement, acceptance criteria, and failure modes |
| `TRACEABILITY.md` | FR-024, AC, TC, and evidence mapping |
| `ACCEPTANCE.md` | Hot reload acceptance command and Release DoD status |
| `FEATURES.md` | Feature projection and implementation status |
| `RUNTIME-MAPPING.md` | Admin endpoint path and operational behavior |
| `CHANGELOG.md` | Versioned change summary |
| `scripts/check-binance-docs.sh` | Machine check for the accepted contract |

## 5. Stop Conditions

[FRAME, HIGH] Stop and keep FR-024 pending if live stream behavior is not proven, if endpoint naming remains split across active docs, if release evidence is local-only but the gate requires remote CI, or if rollback behavior is untested.
