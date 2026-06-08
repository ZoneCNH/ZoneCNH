# TASK-KERNEL-004

> 生命周期管理：Init → Start 拓扑序启动、fail-fast 回滚

---

```yaml
task_id: TASK-KERNEL-004
module: kernel
scope: "实现 Run(ctx) 核心逻辑，按拓扑序执行 Init → Start，失败时 fail-fast 回滚"
spec_ref:
  - "module/kernel/SPEC.md#FR-002"
  - "module/kernel/SPEC.md#BR-002"
  - "module/kernel/SPEC.md#BR-004"
files:
  - "lifecycle.go"
  - "lifecycle_test.go"
acceptance_criteria:
  - "AC-004: Init 失败的模块不会收到 Start 调用"
  - "AC-NEW-21: 正常启动按拓扑序调用 Init → Start"
  - "AC-NEW-22: B.Start 失败 → A.Stop 被调用，返回 B 的错误"
  - "AC-NEW-23: ctx cancel → 已启动模块被 Stop"
  - "AC-NEW-24: Run 无模块时立即返回 nil"
  - "AC-NEW-25: Run 已运行时返回 ErrAlreadyRunning"
  - "AC-NEW-26: Run 已停止时返回 ErrAlreadyStopped"
  - "AC-NEW-27: 依赖图有环时返回 ErrCycleDetected"
depends_on:
  - "TASK-KERNEL-001"
  - "TASK-KERNEL-002"
  - "TASK-KERNEL-003"
estimated_effort: "4h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-002 | Run：拓扑序启动、环检测、失败回滚、ctx 取消、状态检查 | 7 个 WHEN/THEN 场景 |
| BR-002 | 启动顺序必须是拓扑序 | 按拓扑序调用 Init → Start |
| BR-004 | Init 失败的模块不能进入 Start | Init 返回错误后不调用 Start |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| TC-001 | Unit | 正常启动和停止：A.Init → A.Start 按序调用 |
| TC-002 | Unit | 循环依赖：Run 返回 ErrCycleDetected |
| TC-003 | Unit | 启动失败回滚：B.Start 失败 → A.Stop 被调用 |
| TC-005 | Unit | context 取消：parent ctx cancel → 已启动模块被 Stop |
| TC-018 | Unit | Init 失败不进入 Start：A.Init 错误 → A.Start 不被调用 |
| — | Unit | 空 App：无模块 Run 返回 nil |
| — | Unit | 重复 Run：第二次 Run 返回 ErrAlreadyRunning |
| — | Unit | 已停止后 Run：返回 ErrAlreadyStopped |

## Implementation Notes

- Run 内部流程：检查状态 → 构建依赖图 → 拓扑排序 → 逐模块 Init → 逐模块 Start → 设置 started 标志
- 维护两个切片：`initOrder`（拓扑序）和 `startedModules`（已启动模块，用于回滚）
- Init 和 Start 失败时，反序遍历 `startedModules` 调用 Stop
- ctx 取消通过 `ctx.Done()` channel 检测，在每轮 Init/Start 前检查
- 启动完成后设置 registry 的 `started` 标志，阻止后续 Register

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 Run 状态检查：未启动→继续，已运行→ErrAlreadyRunning，已停止→ErrAlreadyStopped | `lifecycle.go` | `go test ./... -run TestRunState` 通过 |
| 2 | 实现拓扑排序调用 Init：按序调用每个模块的 Init，传递 deps，失败时 fail-fast | `lifecycle.go` | `go test ./... -run TestRunInit` 通过 |
| 3 | 实现 Start 阶段：按拓扑序调用 Start，维护 startedModules 切片用于回滚 | `lifecycle.go` | `go test ./... -run TestRunStart` 通过 |
| 4 | 实现失败回滚：Start 失败时反序遍历 startedModules 调用 Stop | `lifecycle.go` | TC-003 通过 |
| 5 | 实现 ctx 取消检测：在每轮 Init/Start 前检查 ctx.Done() | `lifecycle.go` | TC-005 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 回滚顺序错误 | Medium | High | 严格反序遍历 startedModules |
| ctx 取消时机不当 | Low | Medium | 在每轮循环开头检查 ctx.Done() |
| Init deps 注入遗漏 | Low | Medium | 对照 §9.1 WHEN/THEN 验证 |
