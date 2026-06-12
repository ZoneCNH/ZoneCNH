# resiliencx 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-12
Source: SPEC.md v1.0.1

| Requirement | Description             | Acceptance Criteria                | Test Case                       | Task                                                           | Status |
| ----------- | ----------------------- | ---------------------------------- | ------------------------------- | -------------------------------------------------------------- | ------ |
| FR-001      | Timeout                 | AC-001: 正常/超时/ctx取消          | TC-001                          | TASK-RESILIENCX-002                                            | ⬜      |
| FR-002      | Retry                   | AC-002: 首次成功/失败/上限/取消    | TC-001                          | TASK-RESILIENCX-003                                            | ⬜      |
| FR-003      | CircuitBreaker          | AC-003: 三态转换; AC-004: 并发安全 | TC-002, TC-003                  | TASK-RESILIENCX-004                                            | ⬜      |
| FR-004      | Bulkhead                | AC-005: 并发控制/等待/超时         | TC-004                          | TASK-RESILIENCX-005                                            | ⬜      |
| FR-005      | RateLimiter             | AC-006: Allow/Wait正确 & 并发安全  | TC-005                          | TASK-RESILIENCX-006                                            | ⬜      |
| FR-006      | Fallback                | AC-007: primary成功/失败降级       | TC-006                          | TASK-RESILIENCX-007                                            | ⬜      |
| BR-001      | ctx.Context 参数        | 所有策略函数签名含 ctx             | CI Gate: go vet                 | TASK-RESILIENCX-002, TASK-RESILIENCX-003                       | ⬜      |
| BR-002      | configx.Reader 参数化   | 策略参数无硬编码                   | CI Gate: go build + code review | TASK-RESILIENCX-000                                            | ⬜      |
| BR-003      | 策略组合：装饰器模式    | 外层包装内层，可任意嵌套           | TC-008 (compose)                | TASK-RESILIENCX-008                                            | ⬜      |
| BR-004      | 熔断器并发安全          | -race 测试通过                     | CI Gate: go test -race          | TASK-RESILIENCX-004                                            | ⬜      |
| BR-005      | 限流器并发安全          | -race 测试通过                     | CI Gate: go test -race          | TASK-RESILIENCX-006                                            | ⬜      |
| BR-006      | observex.Meter 指标采集 | metrics 注册且可抓取               | CI Gate: 指标端点验证           | TASK-RESILIENCX-009                                            | ⬜      |
| BR-007      | stdlib + 最少依赖       | go.mod 仅含声明依赖                | CI Gate: go mod graph           | TASK-RESILIENCX-000                                            | ⬜      |
| BR-008      | 可独立测试              | 每个策略有独立 unit test           | CI Gate: go test -run           | TASK-RESILIENCX-002 ~ TASK-RESILIENCX-009                      | ⬜      |
| NFR-001     | 性能预算                | benchmark 达标                     | CI Gate: go test -bench         | TASK-RESILIENCX-009                                            | ⬜      |
| NFR-002     | 可观测性                | metrics + logs 输出正确            | CI Gate: 观测验证               | TASK-RESILIENCX-009                                            | ⬜      |
| NFR-003     | 安全                    | 无凭证泄露、输入校验、panic恢复    | CI Gate: gitleaks + code review | TASK-RESILIENCX-000, TASK-RESILIENCX-002 ~ TASK-RESILIENCX-007 | ⬜      |
| NFR-004     | CI Gate 门禁            | 编译/测试/覆盖率/vet/lint 通过     | CI Gate: 全部门禁               | TASK-RESILIENCX-000 ~ TASK-RESILIENCX-009                      | ⬜      |

---

## 覆盖率仪表盘

| 类别   | 总数   | 已覆盖   | 覆盖率   |
| ------ | ------ | -------- | -------- |
| FR     | 6      | 6        | 100%     |
| BR     | 8      | 8        | 100%     |
| NFR    | 4      | 4        | 100%     |

---

## 变更历史

| 日期       | 变更内容                                                                       |
| ---------- | ------------------------------------------------------------------------------ |
| 2026-06-12 | 补全 Task 列、全部 BR (BR-001~BR-008)、NFR 行 (NFR-001~NFR-004)；Task 映射填充 |
| 2026-06-09 | 初始版本（从全局矩阵迁移）                                                     |
