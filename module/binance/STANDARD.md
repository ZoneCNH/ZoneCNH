# module/binance STANDARD.md — Runtime Control Standard

## Metadata

| Field | Value |
| --- | --- |
| Status | Active |
| Module-Version | v3.4.0 |
| Last-Updated | 2026-06-23 |
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

## 5. Script Responsibility Comparison

[COMPUTED, HIGH] 本仓 `scripts/check-binance-docs.sh` 与 runtime 仓 `/home/binance/scripts/boundary-gates.sh` 是两套互补的 gate，职责不重叠：

| 维度 | `scripts/check-binance-docs.sh`（本仓） | `scripts/boundary-gates.sh`（runtime 仓） |
| --- | --- | --- |
| 位置 | ZoneCNH/ZoneCNH 文档仓 | ZoneCNH/binance runtime 仓 |
| 对象 | `module/binance/` 治理文档 | runtime Go 代码与 go.mod |
| 层级 | L1 文档治理 gate | L1 runtime 边界 gate |
| 检测内容 | 命名 SSOT 漂移、4×6 矩阵对称、版本字段统一（R6）、Spec-Reference 闭环、legacy alias 残留、FR-009 L1 证据 | C/S 进程隔离 import、No cs package（BR-005）、No same-process adapter、Server owns storage（BR-006）、Wire contract externality（BR-008）、No domain ownership（BR-007）、go.mod 依赖合规（BR-009） |
| 触发 | 本仓 CI（docs PR） | runtime 仓 CI（code PR） |
| 对应规则 | RULES R1/R2/R6/R9 | BOUNDARY-GATES.md §1-§12 |
| 失败处理 | 阻断 docs PR 合并 | 阻断 code PR 合并 |

[FRAME, HIGH] 两脚本均属 L1 boundary/governance gate，不可替代 L2 functional runtime evidence（RULES R4）。文档侧漂移由本仓脚本守门，runtime 侧架构边界由 runtime 脚本守门；FR-009 实现状态以 `boundary-gates.sh` 输出为唯一 L1 证据，文档侧 `check-binance-docs.sh` 只验证文档对 FR-009 的引用一致性。

## 6. Stop Conditions

[FRAME, HIGH] Stop and keep FR-024 pending if live stream behavior is not proven, if endpoint naming remains split across active docs, if release evidence is local-only but the gate requires remote CI, or if rollback behavior is untested.
