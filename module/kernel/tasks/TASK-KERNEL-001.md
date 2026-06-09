# TASK-KERNEL-001

> 接口定义：Module、Deps、HealthStatus、GraphView、App 及 kernel 内最小接口

---

```yaml
task_id: TASK-KERNEL-001
module: kernel
scope: "定义 Module、Deps、HealthStatus、GraphView、App 接口及 kernel 内最小接口（Logger、Meter 等）"
spec_ref:
  - "module/kernel/SPEC.md#9.1"
  - "module/kernel/SPEC.md#10.2"
  - "module/kernel/SPEC.md#BR-009"
files:
  - "kernel.go"
acceptance_criteria:
  - "AC-008: go list -deps ./... 无非 stdlib 依赖"
  - "AC-NEW-04: Module 接口包含 Name()、Init()、Start()、Stop()、Health() 5 个方法"
  - "AC-NEW-05: Deps 结构体包含 Config、Logger、Meter、Tracer、Resilient、Scheduler 6 个字段"
  - "AC-NEW-06: GraphView 接口包含 Nodes()、Edges()、TopologicalOrder() 3 个方法"
  - "AC-NEW-07: App 接口包含 Register()、Run()、Shutdown()、ModuleHealth()、DependencyGraph() 5 个方法"
  - "AC-NEW-08: go build ./... 编译通过"
depends_on:
  - "TASK-KERNEL-000"
estimated_effort: "1h"
priority: P0
status: pending
```

---

## Files Likely to Change

- `kernel.go` — 新建（接口定义）

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| §9.1 | Module / App / Lifecycle 接口定义 | 所有接口和结构体按 spec 定义 |
| §10.2 | 模块状态枚举 | 6 个状态值：Registered, Starting, Running, Stopping, Stopped, Error |
| BR-009 | Deps 中的接口类型由消费方组装时注入 | kernel 包内定义所有 Deps 字段类型 |

## Non-scope

- 不实现具体模块（→ TASK-KERNEL-003~008）
- 不创建 go.mod（→ TASK-KERNEL-000）
- 不实现依赖图算法（→ TASK-KERNEL-002）

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | CI Gate | `go build ./...` 编译通过 |
| — | CI Gate | `go vet ./...` 无错误 |
| — | Compile | 接口完整性编译验证（所有方法签名正确） |

## Implementation Notes

- 所有接口方法的 `ctx context.Context` 参数保持一致
- `HealthStatus` 是结构体而非接口（值类型，可比较）
- `ModuleState` 使用 `int` 底层类型，`iota` 从 0 开始
- `Deps` 结构体的字段类型全部为 kernel 包内接口，这是 BR-009 的核心要求
- `Logger` 接口使用 `...any` 而非 `...interface{}`（Go 1.18+ 风格）

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 定义 `HealthStatus` 结构体（Ready, Live, Details）和 `ModuleState` 枚举（6 个状态，iota） | `kernel.go` 类型定义 | `go build ./...` 通过 |
| 2 | 定义 `Module` 接口（Name, Init, Start, Stop, Health, Deps）和 `Deps` 结构体（6 个字段） | `kernel.go` 接口定义 | 接口方法签名与 SPEC §9.1 一致 |
| 3 | 定义 `App` 接口（Register, Run, Shutdown, ModuleHealth, DependencyGraph）和 `GraphView` 接口 | `kernel.go` 接口定义 | 与 SPEC §9.1 WHEN/THEN 对照 |
| 4 | 定义 kernel 内最小接口（Logger, Meter, Tracer 等），确保 Deps 字段类型全部在包内 | `kernel.go` | `go vet ./...` 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 接口设计与下游使用场景不匹配 | Medium | High | 对照上游 kernel 现有接口确认 |
| Deps 注入语义不明确 | Low | Medium | 以 SPEC §9.1 WHEN/THEN 为准 |
