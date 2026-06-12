# clickhousex 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-09
Source: docs/governance/TRACEABILITY.md（迁移前全局矩阵）

| Requirement | Description            | Acceptance Criteria | Test Case      | Status |
| ----------- | ---------------------- | ------------------- | -------------- | ------ |
| FR-001      | NewClient              | DoD: 所有 FR 有测试 | TC-005         | ⬜      |
| FR-002      | Exec                   | DoD: 所有 FR 有测试 | TC-001         | ⬜      |
| FR-003      | Query                  | DoD: 所有 FR 有测试 | TC-001         | ⬜      |
| FR-004      | InsertBatch            | DoD: 所有 FR 有测试 | TC-001, TC-003 | ⬜      |
| FR-005      | Health                 | DoD: 所有 FR 有测试 | TC-006         | ⬜      |
| FR-006      | Close                  | DoD: 所有 FR 有测试 | TC-007         | ⬜      |
| FR-007      | Rows.Next/Scan/Close   | DoD: 所有 FR 有测试 | TC-001         | ⬜      |
| FR-008      | Rows.ColumnTypes       | DoD: 所有 FR 有测试 | TC-004         | ⬜      |
| BR-002      | 原生 batch insert 协议 | -                   | TC-003         | ⬜      |
| BR-003      | 参数化绑定防 SQL 拼接  | -                   | TC-001         | ⬜      |
| BR-004      | 连接断开自动重试       | -                   | TC-002         | ⬜      |
| BR-011      | Nullable 映射 Go 指针  | -                   | TC-004         | ⬜      |

---
