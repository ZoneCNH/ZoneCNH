# TASK-EXC-007

> domainx 类型采纳：Order/ExecutionReport 边界对齐

---

```yaml
task_id: TASK-EXC-007
module: domain_exchange
scope: "确保 Order 相关返回使用 domainx.Order/ExecutionReport 或短期兼容 alias，不建立第二套订单 SSOT"
spec_ref:
  - "module/domain_exchange/SPEC.md#FR-EXC-007"
  - "module/domain_exchange/SPEC.md#§2"
  - "module/domain_exchange/SPEC.md#§21"
files:
  - "exchange.go"
  - "alias.go"
  - "adoption_test.go"
acceptance_criteria:
  - "AC-EXC-007: OrderPlacer.PlaceOrder 返回 domainx.ExecutionReport"
  - "AC-EXC-007: OrderQuerier.QueryOrder 返回 domainx.Order"
  - "AC-EXC-007: 如有兼容 alias，标注 deprecated 并记录迁移路径"
  - "AC-EXC-007: 不存在本地重复定义的 Order/ExecutionReport 类型"
depends_on:
  - "TASK-EXC-001"
  - "TASK-EXC-002"
estimated_effort: "1h"
priority: P0
status: pending
non_scope:
  - "不实现 Order 状态机逻辑"
  - "不定义 domainx 类型（仅引用）"
  - "不实现 MIGRATION.md（→发布阶段）"
```

---

## Non-scope

- 不实现 Order 状态机逻辑
- 不定义 domainx 类型（仅引用）
- 不实现 MIGRATION.md（→发布阶段）

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
| ----------- | ----------- | ------------------- |
| FR-EXC-007 | Order 返回使用 domainx 类型或兼容 alias | AC-EXC-007: 返回 domainx 类型，无本地重复定义 |

## Test Plan

| Test Case | Type     | Description |
| --------- | -------- | ----------- |
| TC-EXC-007 | Boundary | domainx adoption: 确认 Order/ExecutionReport 返回类型均为 domainx 包 |

## Implementation Notes

- 如需兼容旧代码，在 alias.go 中创建 deprecated alias，保留到 v2
- deprecated alias 必须有 `// Deprecated:` 注释
- 迁移路径写入 MIGRATION.md（发布阶段）

## Implementation Plan

| Step | Description | Deliverables | Verification |
| ---- | ----------- | ------------ | ------------ |
| 1    | 验证 PlaceOrder/CancelOrder/QueryOrder 返回 domainx 类型 | `adoption_test.go` | `go test ./...` 通过 |
| 2    | 如需兼容 alias，创建 alias.go 并标注 deprecated | `alias.go` | `go build ./...` 通过 |
| 3    | 扫描确认无本地重复 Order/ExecutionReport | `adoption_test.go` | 无本地类型定义 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
| ---- | ----------- | ------ | ---------- |
| domainx 类型变更导致接口不兼容 | Low | High | 依赖 domainx v1.0.0+ 稳定版 |
| deprecated alias 保留期争议 | Low | Low | 按 SPEC §21 保留到 v2 |
