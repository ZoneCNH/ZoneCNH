# testkitx 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-09
Source: docs/governance/TRACEABILITY.md（迁移前全局矩阵）

| Requirement | Description             | Acceptance Criteria          | Test Case     | Status |
| ----------- | ----------------------- | ---------------------------- | ------------- | ------ |
| FR-001      | FakeConfig              | DoD: 所有 FR 有测试          | TC-001        | ⬜     |
| FR-002      | FakeLogger              | DoD: 编译期接口检查          | TC-002        | ⬜     |
| FR-003      | FakeMeter               | DoD: 编译期接口检查          | TC-003        | ⬜     |
| FR-004      | FakeTracer              | DoD: 编译期接口检查          | TC-004        | ⬜     |
| FR-005      | FakeClock               | DoD: 确定性 fake             | TC-005        | ⬜     |
| FR-006      | FakeBreaker             | DoD: 编译期接口检查          | TC-006        | ⬜     |
| FR-007      | Eventually              | DoD: 所有 FR 有测试          | TC-007        | ⬜     |
| FR-008      | GoldenUpdate            | DoD: GOLDEN_UPDATE 环境变量  | TC-008        | ⬜     |
| FR-009      | BoundaryCheck           | DoD: 生产 import 无 testkitx | TC-009        | ⬜     |
| FR-010      | GoroutineLeakCheck      | DoD: 所有 FR 有测试          | TC-010        | ⬜     |
| BR-001      | 编译期接口检查          | -                            | CI Gate       | ⬜     |
| BR-002      | fake 确定性             | -                            | CI Gate       | ⬜     |
| BR-005      | 生产 import 无 testkitx | -                            | boundary-test | ⬜     |

---
