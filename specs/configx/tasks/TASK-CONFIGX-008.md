# TASK-CONFIGX-008

> 集成测试 + Benchmark：完整加载链、性能验证

---

```yaml
task_id: TASK-CONFIGX-008
module: configx
scope: "实现集成测试（完整加载链）和性能基准（加载、Get、校验）"
spec_ref:
  - "specs/configx/SPEC.md#16"
  - "specs/configx/SPEC.md#17"
files:
  - "integration_test.go"
  - "benchmark_test.go"
acceptance_criteria:
  - "集成测试：默认值 → 文件 → 环境变量 → 校验 → 读取 全链路通过"
  - "Benchmark：配置加载 1000 key < 50ms"
  - "Benchmark：Get 单次调用 < 100ns"
  - "-race 测试通过"
depends_on:
  - "TASK-CONFIGX-004"
  - "TASK-CONFIGX-005"
  - "TASK-CONFIGX-006"
  - "TASK-CONFIGX-007"
estimated_effort: "2h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| §16.4 | 集成测试：完整加载链 | 默认值 → 文件 → 环境变量 → 校验 → 读取 |
| §17 | Performance Budget | 加载 < 50ms，Get < 100ns |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| §16.4-1 | Integration | 完整加载链 |
| §17-1 | Benchmark | 配置加载 1000 key < 50ms |
| §17-2 | Benchmark | Get 单次调用 < 100ns |

## Implementation Notes

- 集成测试使用 testdata/ 目录下的配置文件
- Benchmark 使用 `testing.B`，报告 ns/op 和 allocs/op

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 创建 testdata/ 配置文件 | `testdata/` | 文件格式正确 |
| 2 | 实现集成测试：完整加载链 | `integration_test.go` | §16.4-1 通过 |
| 3 | 实现 Benchmark：加载、Get、校验 | `benchmark_test.go` | §17 全部通过 |
| 4 | 运行 `-race` 全量测试 | — | 无 data race |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Benchmark 结果不稳定 | Medium | Low | `b.N` 自动调整，`-count=3` |
