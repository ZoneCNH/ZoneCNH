# TASK-SCHEDULEX-009

> 集成测试 + Benchmark

---

```yaml
task_id: TASK-SCHEDULEX-009
module: schedulex
scope: "实现集成测试和性能基准"
spec_ref:
  - "specs/schedulex/SPEC.md#16"
  - "specs/schedulex/SPEC.md#17"
files:
  - "integration_test.go"
  - "benchmark_test.go"
acceptance_criteria:
  - "所有功能场景端到端测试通过"
  - "Benchmark：Schedule < 1μs"
  - "-race 测试通过"
depends_on:
  - "TASK-SCHEDULEX-002"
  - "TASK-SCHEDULEX-003"
  - "TASK-SCHEDULEX-004"
  - "TASK-SCHEDULEX-005"
  - "TASK-SCHEDULEX-006"
  - "TASK-SCHEDULEX-007"
  - "TASK-SCHEDULEX-008"
estimated_effort: "2h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| §16 | 集成测试 | 端到端测试通过 |
| §17 | Performance Budget | Schedule < 1μs |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | Integration | 完整调度流程 |
| — | Benchmark | Schedule 注册开销 |

## Implementation Notes

- 使用 MockClock 控制时间推进
- 集成测试覆盖：Schedule→触发→Overlap→Misfire→Cancel→Stop 全流程

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现集成测试：全流程 | `integration_test.go` | 全部通过 |
| 2 | 实现 Benchmark | `benchmark_test.go` | < 1μs |
| 3 | `-race` 全量测试 | — | 无 data race |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 时间相关测试不稳定 | Medium | Low | MockClock 消除时间依赖 |
