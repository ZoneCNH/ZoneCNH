# natsx 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-09
Source: docs/governance/TRACEABILITY.md（迁移前全局矩阵）

| Requirement | Description             | Acceptance Criteria | Test Case | Status |
| ----------- | ----------------------- | ------------------- | --------- | ------ |
| FR-001      | Publish（Core NATS）    | DoD: 所有 FR 有测试 | TC-001    | ⬜     |
| FR-002      | Subscribe（Core NATS）  | DoD: 所有 FR 有测试 | TC-001    | ⬜     |
| FR-003      | Request（Core NATS）    | DoD: 所有 FR 有测试 | TC-002    | ⬜     |
| FR-004      | JetStream.Publish       | DoD: 所有 FR 有测试 | TC-003    | ⬜     |
| FR-005      | JetStream.Subscribe     | DoD: 所有 FR 有测试 | TC-003    | ⬜     |
| FR-006      | JetStream.AddStream     | DoD: 所有 FR 有测试 | TC-003    | ⬜     |
| FR-007      | JetStream.AddConsumer   | DoD: 所有 FR 有测试 | TC-003    | ⬜     |
| FR-008      | Health                  | DoD: 所有 FR 有测试 | TC-005    | ⬜     |
| BR-001      | Core NATS at-most-once  | -                   | TC-001    | ⬜     |
| BR-002      | JetStream at-least-once | -                   | TC-003    | ⬜     |
| BR-005      | 自动重连指数退避        | -                   | TC-004    | ⬜     |

---
