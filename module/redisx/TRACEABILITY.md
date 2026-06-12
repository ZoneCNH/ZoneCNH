# redisx 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-12
Source: docs/governance/TRACEABILITY.md（迁移前全局矩阵）
Dependency-Boundary: direct Go deps are `kernel` plus Redis client library `github.com/redis/go-redis/v9`; `configx`、`observex`、`resiliencx`、`contracts` are non-scope direct imports.

| Requirement | Description        | Acceptance Criteria | Test Case | Task | Status |
| ----------- | ------------------ | ------------------- | --------- | ---- | ------ |
| FR-001      | Get                | DoD: 所有 FR 有测试 | TC-001    | TASK-REDISX-002 | ⬜ |
| FR-002      | Set                | DoD: 所有 FR 有测试 | TC-001    | TASK-REDISX-002 | ⬜ |
| FR-003      | Del                | DoD: 所有 FR 有测试 | TC-001    | TASK-REDISX-002 | ⬜ |
| FR-004      | Exists             | DoD: 所有 FR 有测试 | TC-005    | TASK-REDISX-003 | ⬜ |
| FR-005      | Expire             | DoD: 所有 FR 有测试 | TC-005    | TASK-REDISX-003 | ⬜ |
| FR-006      | HGet / HSet        | DoD: 所有 FR 有测试 | TC-006    | TASK-REDISX-003 | ⬜ |
| FR-007      | LPush / LRange     | DoD: 所有 FR 有测试 | TC-007    | TASK-REDISX-004 | ⬜ |
| FR-008      | Subscribe          | DoD: 所有 FR 有测试 | TC-008    | TASK-REDISX-004 | ⬜ |
| FR-009      | Pipeline           | DoD: 所有 FR 有测试 | TC-003    | TASK-REDISX-005 | ⬜ |
| FR-010      | Locker.Acquire     | DoD: 所有 FR 有测试 | TC-002    | TASK-REDISX-006 | ⬜ |
| FR-011      | Locker.Release     | DoD: 所有 FR 有测试 | TC-002    | TASK-REDISX-006 | ⬜ |
| FR-012      | Health             | DoD: 所有 FR 有测试 | TC-009    | TASK-REDISX-007 | ⬜ |
| BR-004      | 分布式锁唯一持有者 | -                   | TC-002    | TASK-REDISX-006 | ⬜ |
| BR-006      | Pipeline 原子性    | -                   | TC-003    | TASK-REDISX-005 | ⬜ |

## Non-Scope Traceability

| Non-Scope Item | Guard | Verification |
| -------------- | ----- | ------------ |
| configx direct import | redisx receives already parsed options or local config structs only. | Dependency guard / code review |
| observex direct import | redisx exposes local callbacks or sink interfaces for observability semantics. | Dependency guard / code review |
| resiliencx direct import | redisx owns timeout/retry/fast-fail settings locally or receives policies via options. | Dependency guard / code review |
| contracts direct import | Public API and error-code contracts are documented here and in SPEC, not imported. | Dependency guard / code review |
