# TASK-XLIB-007

> PR-4c：Health + Metrics — pkg/templatex/health.go + metrics.go + contracts

---

```yaml
task_id: TASK-XLIB-007
module: xlib_standard
scope: "实现 HealthCheck 和 Metrics 5 个 P0 指标，覆盖 FR-003 和 FR-004"
spec_ref:
  - "module/xlib_standard/spec/SPEC.md#7"
  - "module/xlib_standard/spec/SPEC.md#9"
  - "module/xlib_standard/spec/SPEC.md#10"
  - "module/xlib_standard/goal/goal.md#7"
  - "module/xlib_standard/goal/goal.md#8"
files:
  - "pkg/templatex/health.go"
  - "pkg/templatex/health_test.go"
  - "pkg/templatex/metrics.go"
  - "pkg/templatex/metrics_test.go"
  - "contracts/health.schema.json"
  - "contracts/metrics.json"

files_change:
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
  - "TASK-XLIB-006"
estimated_effort: "1h"
priority: P0
status: pending
```

---

## Scope

- 实现 `pkg/templatex/health.go` 的 HealthCheck。
- 实现 `pkg/templatex/metrics.go` 的 NoopMetrics 和 5 个 P0 指标。
- 更新 `contracts/health.schema.json` 与 `contracts/metrics.json`。

## Non-scope

- 不新增高基数 label。
- 不引入 Prometheus、OpenTelemetry 或其他外部指标依赖。
- 不修改 Client、Error 或生成脚本。

## Acceptance

- nil context 返回 unhealthy，健康客户端返回 healthy。
- NoopMetrics 调用不 panic。
- 指标名与 contract 中 5 个 P0 指标一致，label 只含 op/kind/status。

## Requirements Covered

| Requirement | Description  | Acceptance Criteria      |
| ----------- | ------------ | ------------------------ |
| FR-003      | Health 标准  | HealthCheck 返回格式正确 |
| FR-004      | Metrics 标准 | 5 个 P0 指标             |

## Test Plan

```bash
# TC-009: HealthCheck nil context → unhealthy
GOWORK=off go test ./pkg/templatex/ -run TestHealthNilContext -v

# TC-010: HealthCheck 健康客户端 → healthy
GOWORK=off go test ./pkg/templatex/ -run TestHealthHealthy -v

# TC-011: NoopMetrics 不 panic
GOWORK=off go test ./pkg/templatex/ -run TestNoopMetrics -v

# TC-012: 指标名匹配 contract 5 个 P0
GOWORK=off go test ./pkg/templatex/ -run TestMetricsNames -v

# TC-013: label 低基数只有 op/kind/status
GOWORK=off go test ./pkg/templatex/ -run TestMetricsLabels -v

# Race 检测
GOWORK=off go test -race ./pkg/templatex/
```

## Implementation Notes

1. Metrics 按 goal.md §7.5 只有 5 个 P0
2. Health 按 goal.md §7.6 实现
3. contracts/health.schema.json 和 contracts/metrics.json 按 goal.md §8 更新
