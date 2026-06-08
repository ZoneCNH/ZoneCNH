# schedulex 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-09
Source: docs/governance/TRACEABILITY.md（迁移前全局矩阵）

| Requirement | Description                     | Acceptance Criteria           | Test Case | Status |
| ----------- | ------------------------------- | ----------------------------- | --------- | ------ |
| FR-001      | Schedule                        | DoD: 所有 FR 有测试           | TC-001    | ⬜     |
| FR-002      | Trigger                         | DoD: DST/timezone golden 测试 | TC-001    | ⬜     |
| FR-003      | Overlap Policy                  | DoD: overlap contract 测试    | TC-002    | ⬜     |
| FR-004      | Misfire Policy                  | DoD: misfire contract 测试    | TC-003    | ⬜     |
| FR-005      | Cancel                          | DoD: 所有 FR 有测试           | TC-005    | ⬜     |
| FR-006      | Stop                            | DoD: shutdown leak/race 测试  | TC-006    | ⬜     |
| FR-007      | EventSink                       | DoD: 所有 FR 有测试           | TC-007    | ⬜     |
| FR-008      | Locker                          | DoD: 所有 FR 有测试           | TC-004    | ⬜     |
| FR-009      | Clock                           | DoD: DST/timezone golden 测试 | TC-008    | ⬜     |
| BR-002      | 重复 JobID 返回 ErrDuplicateJob | -                             | TC-009    | ⬜     |
| BR-005      | job panic 被 catch              | DoD: shutdown race 测试       | TC-006    | ⬜     |
| BR-007      | DST 切换触发正确                | DoD: DST/timezone golden 测试 | TC-008    | ⬜     |

---
