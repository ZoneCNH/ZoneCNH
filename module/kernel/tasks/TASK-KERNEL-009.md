# TASK-KERNEL-009

> 集成测试 + Benchmark：完整启动-运行-停止流程、性能验证

---

```yaml
task_id: TASK-KERNEL-009
module: kernel
scope: "实现集成测试（完整启动-运行-停止）和性能基准（注册、冷启动、拓扑排序、停机）"
spec_ref:
  - "module/kernel/SPEC.md#16.5"
  - "module/kernel/SPEC.md#16.4"
  - "module/kernel/SPEC.md#17"
files:
  - "integration_test.go"
  - "benchmark_test.go"
acceptance_criteria:
  - "AC-NEW-46: 集成测试：完整启动-运行-停止流程通过"
  - "AC-NEW-47: 集成测试：启动失败回滚通过"
  - "AC-NEW-48: Benchmark：50 模块注册 + 依赖图校验 < 10ms"
  - "AC-NEW-49: Benchmark：冷启动 < 100ms"
  - "AC-NEW-50: Benchmark：100 节点拓扑排序 < 1ms"
  - "AC-NEW-51: Benchmark：graceful shutdown < 5s"
  - "AC-NEW-52: -race 测试通过"
depends_on:
  - "TASK-KERNEL-004"
  - "TASK-KERNEL-005"
  - "TASK-KERNEL-006"
  - "TASK-KERNEL-007"
  - "TASK-KERNEL-008"
estimated_effort: "3h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| §16.5 | 集成测试：完整启动-运行-停止 | App.Run → 全部 Running → Shutdown → 全部 Stopped |
| §16.5 | 集成测试：启动失败回滚 | 部分 Init 成功、Start 失败 → 已 Init 模块被 Stop |
| §16.4 | Benchmark：50 模块注册 + 依赖图校验 | < 10ms |
| §16.4 | Benchmark：冷启动 | < 100ms |
| §16.4 | Benchmark：100 节点拓扑排序 | < 1ms |
| §17 | Performance Budget：graceful shutdown | < 5s |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| §16.5-1 | Integration | 完整启动-运行-停止：App.Run → signal → Shutdown → 全部 Stopped |
| §16.5-2 | Integration | 启动失败回滚：部分模块 Init 成功、Start 失败 → 已 Init 模块被 Stop |
| §16.4-1 | Benchmark | 50 模块注册 + 依赖图校验 < 10ms |
| §16.4-2 | Benchmark | 冷启动 < 100ms |
| §16.4-3 | Benchmark | 100 节点拓扑排序 < 1ms |
| §17-1 | Benchmark | graceful shutdown < 5s |

## Implementation Notes

- 集成测试使用 `//go:build integration` tag，不参与常规 `go test`
- 使用 mock 模块实现 Module 接口，控制 Init/Start/Stop 行为
- Benchmark 使用 `testing.B`，报告 ns/op 和 allocs/op
- 集成测试验证 observable 状态（ModuleHealth、DependencyGraph）
- 使用 `testing.Benchmark` 或 `b.N` 循环

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 创建 mock 模块实现（可控 Init/Start/Stop 行为，支持注入错误和延迟） | `integration_test.go` 辅助 | `go build ./...` 通过 |
| 2 | 实现集成测试：完整启动-运行-停止流程（App.Run → 全部 Running → Shutdown → 全部 Stopped） | `integration_test.go` | §16.5-1 通过 |
| 3 | 实现集成测试：启动失败回滚（部分 Init 成功、Start 失败 → 已 Init 模块被 Stop） | `integration_test.go` | §16.5-2 通过 |
| 4 | 实现 Benchmark：50 模块注册 + 依赖图校验 < 10ms，冷启动 < 100ms，100 节点拓扑排序 < 1ms | `benchmark_test.go` | §16.4 全部通过 |
| 5 | 实现 Benchmark：graceful shutdown < 5s，运行 `-race` 测试 | `benchmark_test.go` | §17-1 通过，`-race` 无 data race |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| mock 模块行为不够真实 | Low | Medium | 使用真实 Module 接口实现，可控延迟和错误 |
| Benchmark 结果不稳定 | Medium | Low | 使用 `b.N` 自动调整，`-count=3` 取中位数 |
