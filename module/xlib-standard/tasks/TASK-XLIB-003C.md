# TASK-XLIB-003C

> PR-4c：Health + Metrics — pkg/templatex/health.go + metrics.go + contracts

---

```yaml
task_id: TASK-XLIB-003C
module: xlib-standard
scope: "实现 HealthCheck 和 Metrics 5 个 P0 指标，覆盖 FR-003 和 FR-004"
spec_ref:
  - "module/xlib-standard/SPEC.md#7"
  - "module/xlib-standard/SPEC.md#9"
  - "module/xlib-standard/SPEC.md#10"
  - "module/xlib-standard/goal.md#7"
  - "module/xlib-standard/goal.md#8"
files:
  - "pkg/templatex/health.go"
  - "pkg/templatex/health_test.go"
  - "pkg/templatex/metrics.go"
  - "pkg/templatex/metrics_test.go"
  - "contracts/health.schema.json"
  - "contracts/metrics.json"
acceptance_criteria:
  - "AC-009: HealthCheck nil context 返回 unhealthy"
  - "AC-010: HealthCheck 健康客户端返回 healthy"
  - "AC-011: NoopMetrics 不 panic"
  - "AC-012: 指标名匹配 contract 5 个 P0 指标名一致"
  - "AC-013: label 低基数只有 op/kind/status"
depends_on:
  - "TASK-XLIB-003B"
estimated_effort: "1h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-003 | Health 标准 | HealthCheck 返回格式正确 |
| FR-004 | Metrics 标准 | 5 个 P0 指标 |

## Test Plan

```bash
GOWORK=off go test ./pkg/templatex/ -run TestHealth -v
GOWORK=off go test ./pkg/templatex/ -run TestMetrics -v
GOWORK=off go test -race ./pkg/templatex/
```

## Implementation Notes

1. Metrics 按 goal.md §7.5 只有 5 个 P0
2. Health 按 goal.md §7.6 实现
3. contracts/health.schema.json 和 contracts/metrics.json 按 goal.md §8 更新
