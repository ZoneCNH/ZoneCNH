# xgo 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-09
Source: docs/governance/TRACEABILITY.md（迁移前全局矩阵）

| Requirement | Description          | Acceptance Criteria | Test Case    | Status |
| ----------- | -------------------- | ------------------- | ------------ | ------ |
| FR-001      | Compose 模块组装     | AC-001              | TC-001       | ⬜     |
| FR-002      | Run 启动             | AC-002              | TC-002       | ⬜     |
| FR-003      | Shutdown 停机        | AC-003              | TC-003       | ⬜     |
| FR-004      | Health 健康检查      | AC-004              | TC-004       | ⬜     |
| FR-005      | Signal 信号处理      | AC-005              | TC-005       | ⬜     |
| FR-006      | Config 配置加载      | AC-006              | TC-006       | ⬜     |
| BR-001      | 组合根不包含业务逻辑 | -                   | import check | ⬜     |
| BR-003      | 只编排不实现         | -                   | code review  | ⬜     |
| BR-005      | 单进程运行           | AC-002              | TC-002       | ⬜     |

---
