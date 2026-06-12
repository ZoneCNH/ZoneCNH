# TASK-KERNEL-011

> healthx 子包：健康检查状态与聚合

---

```yaml
task_id: TASK-KERNEL-011
module: kernel
scope: "实现 healthx 子包：HealthStatusValue、HealthStatus、HealthChecker、Aggregate、AggregateWithClock"
spec_ref:
  - "module/kernel/SPEC.md#FR-003"
  - "module/kernel/SPEC.md#BR-007"
  - "module/kernel/SPEC.md#9.3"
  - "module/kernel/SPEC.md#10.2"
files:
  - "healthx/healthx.go"
  - "healthx/healthx_test.go"
  - "healthx/example_test.go"
acceptance_criteria:
  - "AC-005: HealthStatus 构造、IsHealthy、Aggregate 逻辑正确"
  - "AC-HEALTHX-01: Aggregate 全 healthy 返回 healthy"
  - "AC-HEALTHX-02: Aggregate 有 unhealthy 返回 unhealthy"
  - "AC-HEALTHX-03: Aggregate 无 unhealthy 有 degraded 返回 degraded"
  - "AC-HEALTHX-04: Aggregate 无 statuses 返回 healthy + \"ok\""
  - "AC-HEALTHX-05: WithMetadata 返回新 HealthStatus（不可变）"
  - "AC-HEALTHX-06: Metadata nil 时 JSON 序列化为 {}"
  - "AC-HEALTHX-07: AggregateWithClock clock=nil 回退到 RealClock"
  - "AC-HEALTHX-08: go test -race -count=1 ./healthx/... 通过"
depends_on:
  - "TASK-KERNEL-000"
  - "TASK-KERNEL-002"
estimated_effort: "1.5h"
priority: P0
status: pending
```

---

## Files Likely to Change

- `healthx/healthx.go` — 新建（HealthStatusValue/HealthStatus/HealthChecker/Aggregate）
- `healthx/healthx_test.go` — 新建
- `healthx/example_test.go` — 新建

## Requirements Covered

> Spec TC: TC-007

| Requirement | Description |
|---|---|
| FR-003 | 健康检查 |
| BR-007 | Metadata nil 时必须序列化为 {} |

## Internal Dependencies

- `timex` — AggregateWithClock 接受 timex.Clock

## Non-scope

- 不在 HealthChecker.Check 中产生副作用
- 不实现健康检查调度器（由调用方控制检查频率）

## Test Plan

| TC | Type | Description |
|----|------|-------------|
| TC-007 | Unit | Aggregate 优先级：unhealthy>degraded>healthy |

## Implementation Notes

- HealthStatus 是值类型，WithMetadata 不可变模式
- Aggregate 优先级：unhealthy > degraded > healthy
- Metadata nil 时 MarshalJSON 返回 `{}`
