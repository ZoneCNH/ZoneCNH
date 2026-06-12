# kafkax 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-09
Source: docs/governance/TRACEABILITY.md（迁移前全局矩阵）

| Requirement | Description                | Acceptance Criteria | Test Case | Status |
| ----------- | -------------------------- | ------------------- | --------- | ------ |
| FR-001      | Producer.Send              | DoD: 所有 FR 有测试 | TC-001    | ⬜      |
| FR-002      | Producer.SendBatch         | DoD: 所有 FR 有测试 | TC-002    | ⬜      |
| FR-003      | Consumer.Subscribe         | DoD: 所有 FR 有测试 | TC-001    | ⬜      |
| FR-004      | Consumer.Poll              | DoD: 所有 FR 有测试 | TC-001    | ⬜      |
| FR-005      | Consumer.Commit            | DoD: 所有 FR 有测试 | TC-003    | ⬜      |
| FR-006      | Health                     | DoD: 所有 FR 有测试 | TC-005    | ⬜      |
| BR-001      | Producer 同步发送 acks=all | -                   | TC-001    | ⬜      |
| BR-002      | Consumer 手动 offset       | -                   | TC-003    | ⬜      |
| BR-005      | Producer 重试可配置        | -                   | TC-004    | ⬜      |

---
