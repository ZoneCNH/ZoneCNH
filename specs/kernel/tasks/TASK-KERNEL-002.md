# TASK-KERNEL-002

> 依赖图：拓扑排序、环检测、GraphView 实现

---

```yaml
task_id: TASK-KERNEL-002
module: kernel
scope: "实现依赖图管理（添加节点/边、拓扑排序、环检测）及 GraphView 只读视图"
spec_ref:
  - "specs/kernel/SPEC.md#FR-005"
  - "specs/kernel/SPEC.md#BR-001"
  - "specs/kernel/SPEC.md#BR-002"
files:
  - "graph.go"
  - "internal/dag/dag.go"
  - "graph_test.go"
  - "internal/dag/dag_test.go"
acceptance_criteria:
  - "AC-NEW-09: 依赖图正确反映模块间的依赖关系"
  - "AC-NEW-10: 无环依赖图的 TopologicalOrder 返回正确的拓扑序"
  - "AC-NEW-11: 有环依赖图返回 ErrCycleDetected"
  - "AC-NEW-12: 自引用（A→A）返回 ErrCycleDetected"
  - "AC-NEW-13: GraphView.Nodes() 返回所有已添加节点名"
  - "AC-NEW-14: GraphView.Edges() 返回所有 [from, to] 边"
  - "AC-NEW-15: 100 节点拓扑排序 < 1ms"
depends_on:
  - "TASK-KERNEL-001"
estimated_effort: "3h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-005 | DependencyGraph 返回 GraphView 只读视图 | GraphView 包含节点列表、边列表、拓扑序 |
| BR-001 | 依赖图不允许环 | 检测到环返回 ErrCycleDetected |
| BR-002 | 启动顺序必须是拓扑序 | TopologicalOrder 返回正确的拓扑序 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| TC-002 | Unit | 循环依赖检测：A→B→A 返回 ErrCycleDetected |
| TC-010 | Unit | 依赖图输出：A→B 的 GraphView 包含正确节点和边 |
| TC-014 | Unit | 深依赖链：50+ 层线性链拓扑排序正确且 < 1ms |
| — | Unit | 自引用依赖：A→A 返回 ErrCycleDetected |
| — | Unit | 空图：无节点时 TopologicalOrder 返回空切片 |
| — | Unit | 多独立链：A→B, C→D 两条独立链正确排序 |
| — | Benchmark | 100 节点拓扑排序 Benchmark |

## Implementation Notes

- `internal/dag` 包实现纯算法，不依赖 kernel 包的类型（避免循环依赖）
- `dag.TopologicalSort` 使用 Kahn 算法（BFS），同时检测环
- `dag.DetectCycle` 使用 DFS 三色标记（白/灰/黑）
- `graph.go` 包装 dag 算法，提供面向 kernel 的接口
- GraphView 应返回切片的副本而非内部引用（只读语义）

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `internal/dag` 包：Graph 结构体（邻接表）、AddNode、AddEdge 方法 | `internal/dag/dag.go` | `go build ./internal/dag` 通过 |
| 2 | 实现 `dag.TopologicalSort`（Kahn BFS）和 `dag.DetectCycle`（DFS 三色标记） | `internal/dag/dag.go` | `go test ./internal/dag/...` 通过 |
| 3 | 实现 `graph.go`：DependencyGraph 方法返回 GraphView，Nodes/Edges 返回副本 | `graph.go` | `go test ./... -run TestGraph` 通过 |
| 4 | 编写 benchmark 验证 100 节点拓扑排序 < 1ms，深依赖链 50+ 层正确 | `dag_test.go` | `go test -bench=BenchmarkTopo` < 1ms |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Kahn 算法实现有环检测遗漏 | Low | High | 使用 DFS 三色标记作为交叉验证 |
| GraphView 返回内部引用导致数据竞争 | Medium | High | 返回切片副本，用 `-race` 测试验证 |
