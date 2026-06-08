# TASK-RESILIENCX-009

> 集成测试 + Benchmark

---

```yaml
task_id: TASK-RESILIENCX-009
module: resiliencx
scope: "实现集成测试和性能基准"
spec_ref:
  - "module/resiliencx/SPEC.md#16"
  - "module/resiliencx/SPEC.md#17"
files:
  - "integration_test.go"
  - "benchmark_test.go"
acceptance_criteria:
  - "所有策略端到端测试通过"
  - "Benchmark：单次策略调用 < 1μs（无 IO）"
  - "-race 测试通过"
depends_on:
  - "TASK-RESILIENCX-002"
  - "TASK-RESILIENCX-003"
  - "TASK-RESILIENCX-004"
  - "TASK-RESILIENCX-005"
  - "TASK-RESILIENCX-006"
  - "TASK-RESILIENCX-007"
  - "TASK-RESILIENCX-008"
estimated_effort: "2h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| §16 | 集成测试 | 端到端测试通过 |
| §17 | Performance Budget | 策略调用 < 1μs |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | Integration | 所有策略端到端 |
| — | Benchmark | 策略调用开销 |

## Implementation Notes

- 集成测试模拟真实场景：网络调用 + 超时 + 重试 + 熔断
- Benchmark 测量策略包装开销（不含实际 IO）

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现集成测试：各策略端到端 | `integration_test.go` | 全部通过 |
| 2 | 实现 Benchmark：策略调用开销 | `benchmark_test.go` | < 1μs |
| 3 | 运行 `-race` 全量测试 | — | 无 data race |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Benchmark 不稳定 | Low | Low | `b.N` 自动调整 |
