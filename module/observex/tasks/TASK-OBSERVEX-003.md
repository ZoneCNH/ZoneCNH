# TASK-OBSERVEX-003

> Meter 实现：Counter、Histogram、Gauge

---

```yaml
task_id: TASK-OBSERVEX-003
module: observex
scope: "实现 Meter 接口（Counter/Histogram/Gauge），指标命名校验"
spec_ref:
  - "module/observex/SPEC.md#FR-002"
  - "module/observex/SPEC.md#BR-002"
  - "module/observex/SPEC.md#BR-006"
files:
  - "meter/meter.go"
  - "meter/impl.go"
  - "meter/names.go"
  - "meter/meter_test.go"
acceptance_criteria:
  - "Counter.Add 累加正确"
  - "Histogram.Record 记录样本"
  - "Gauge.Set 设置值"
  - "指标命名符合 foundationx_<module>_<op>_<measure> 规范"
depends_on:
  - "TASK-OBSERVEX-001"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description                                            | Acceptance Criteria |
| ----------- | ------------------------------------------------------ | ------------------- |
| FR-002      | Meter：Counter/Histogram/Gauge 操作                    | 3 个 WHEN/THEN 场景 |
| BR-002      | Meter 必须控制 label 基数                              | 高基数 label 被拒绝 |
| BR-006      | 指标命名必须符合 `foundationx_<module>_<op>_<measure>` | 命名校验            |

## Test Plan

| Test Case | Type | Description                              |
| --------- | ---- | ---------------------------------------- |
| TC-007    | Unit | Metrics 命名规范：不符合规范的名称被拒绝 |
| —         | Unit | Counter.Add 累加正确                     |
| —         | Unit | Histogram.Record 记录正确                |
| —         | Unit | Gauge.Set 设置正确                       |

## Implementation Notes

- 内部使用 `map[string]*metric` 存储已注册指标
- 命名校验正则：`^[a-z][a-z0-9_]*_[a-z0-9_]+$`
- `meter/names.go` 定义命名规范常量
- label policy 检查由 TASK-OBSERVEX-003b 独立实现，meter 在 Add/Record/Set 时调用 label policy checker

## Implementation Plan

| Step | Description                                                 | Deliverables     | Verification               |
| ---- | ----------------------------------------------------------- | ---------------- | -------------------------- |
| 1    | 实现 Counter/Histogram/Gauge 内部结构和 Add/Record/Set 方法 | `meter/impl.go`  | `go test ./meter/...` 通过 |
| 2    | 实现 `MeterImpl`：注册指标时校验命名，记录时校验 label      | `meter/impl.go`  | TC-007 通过                |
| 3    | 创建 `meter/names.go`，定义命名规范和示例常量               | `meter/names.go` | `go build ./...` 通过      |

### Risk Assessment

| Risk             | Probability | Impact | Mitigation       |
| ---------------- | ----------- | ------ | ---------------- |
| 命名校验正则遗漏 | Low         | Low    | 对照 BR-006 规范 |
