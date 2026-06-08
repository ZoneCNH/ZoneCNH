# TASK-REDISX-008

> 集成测试 + Benchmark

---

```yaml
task_id: TASK-REDISX-008
module: redisx
scope: "实现集成测试和性能基准"
spec_ref:
  - "specs/redisx/SPEC.md#16"
  - "specs/redisx/SPEC.md#17"
files:
  - "integration_test.go"
  - "benchmark_test.go"
acceptance_criteria:
  - "所有操作端到端测试通过"
  - "Benchmark：单次 Get/Set < 1ms"
  - "-race 测试通过"
depends_on:
  - "TASK-REDISX-002"
  - "TASK-REDISX-003"
  - "TASK-REDISX-004"
  - "TASK-REDISX-005"
  - "TASK-REDISX-006"
  - "TASK-REDISX-007"
estimated_effort: "2h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| §16 | 集成测试 | 端到端测试通过 |
| §17 | Performance Budget | Get/Set < 1ms |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | Integration | 全部操作端到端 |
| — | Benchmark | Get/Set 延迟 |

## Implementation Notes

- 集成测试需要 Redis 实例（或 miniredis mock）
- Benchmark 测量网络延迟

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现集成测试 | `integration_test.go` | 全部通过 |
| 2 | 实现 Benchmark | `benchmark_test.go` | < 1ms |
| 3 | `-race` 全量测试 | — | 无 data race |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Redis 实例依赖 | Medium | Low | 使用 miniredis mock |
