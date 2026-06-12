# TASK-OBSERVEX-008

> 集成测试 + Benchmark：完整链路、性能验证

---

```yaml
task_id: TASK-OBSERVEX-008
module: observex
scope: "实现集成测试（Logger+Meter+Tracer+Exporter 端到端）和性能基准"
spec_ref:
  - "module/observex/SPEC.md#16"
  - "module/observex/SPEC.md#17"
files:
  - "integration_test.go"
  - "benchmark_test.go"
acceptance_criteria:
  - "集成测试：Logger+Meter+Tracer+Exporter 端到端通过"
  - "Benchmark：单条日志 < 5μs"
  - "Benchmark：metrics 记录 < 1μs"
  - "Benchmark：span 创建+结束 < 2μs"
  - "-race 测试通过"
depends_on:
  - "TASK-OBSERVEX-002"
  - "TASK-OBSERVEX-003"
  - "TASK-OBSERVEX-003b"
  - "TASK-OBSERVEX-004"
  - "TASK-OBSERVEX-005"
  - "TASK-OBSERVEX-006"
  - "TASK-OBSERVEX-007"
estimated_effort: "3h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| §16.4 | 集成测试：完整链路 | Logger+Meter+Tracer+Exporter 端到端 |
| §17 | Performance Budget | 日志 < 5μs，metrics < 1μs，span < 2μs |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| §16.4-1 | Integration | exporter 不可达降级 |
| §16.4-2 | Integration | 完整链路端到端 |
| §17-1 | Benchmark | 单条结构化日志 < 5μs |
| §17-2 | Benchmark | metrics 记录 < 1μs |
| §17-3 | Benchmark | span 创建+结束 < 2μs |

## Implementation Notes

- 集成测试使用 test exporter 记录数据
- Benchmark 使用 `testing.B`，报告 ns/op 和 allocs/op
- 降级测试：使用 mock exporter 返回错误

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现集成测试：Logger+Meter+Tracer+Exporter 端到端 | `integration_test.go` | §16.4-2 通过 |
| 2 | 实现降级测试：exporter 不可达不影响业务 | `integration_test.go` | §16.4-1 通过 |
| 3 | 实现 Benchmark：日志、metrics、span 性能基准 | `benchmark_test.go` | §17 全部通过 |
| 4 | 运行 `-race` 全量测试 | — | 无 data race |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Benchmark 结果不稳定 | Medium | Low | `b.N` 自动调整，`-count=3` |
