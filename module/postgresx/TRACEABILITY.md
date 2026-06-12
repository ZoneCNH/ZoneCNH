# postgresx 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-09
Source: docs/governance/TRACEABILITY.md（迁移前全局矩阵）

| Requirement | Description              | Acceptance Criteria | Test Case      | Status |
| ----------- | ------------------------ | ------------------- | -------------- | ------ |
| FR-001      | Query                    | DoD: 所有 FR 有测试 | TC-001         | ⬜      |
| FR-002      | QueryRow                 | DoD: 所有 FR 有测试 | TC-001         | ⬜      |
| FR-003      | Exec                     | DoD: 所有 FR 有测试 | TC-001         | ⬜      |
| FR-004      | Tx                       | DoD: 所有 FR 有测试 | TC-002, TC-003 | ⬜      |
| FR-005      | Health                   | DoD: 所有 FR 有测试 | TC-005         | ⬜      |
| FR-006      | Migration                | DoD: 所有 FR 有测试 | TC-004         | ⬜      |
| BR-001      | 参数化查询防 SQL 注入    | -                   | TC-001         | ⬜      |
| BR-003      | 事务自动 commit/rollback | -                   | TC-002         | ⬜      |
| BR-004      | 事务 panic 自动 rollback | -                   | TC-003         | ⬜      |
| BR-007      | 迁移脚本幂等             | -                   | TC-004         | ⬜      |

---
