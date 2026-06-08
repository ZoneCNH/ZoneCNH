# TASK-KERNEL-005

> 优雅停机：反序 Stop、超时 force、signal handling

---

```yaml
task_id: TASK-KERNEL-005
module: kernel
scope: "实现 Shutdown(ctx) 反序停机逻辑、超时 force、OS signal 处理"
spec_ref:
  - "specs/kernel/SPEC.md#FR-003"
  - "specs/kernel/SPEC.md#BR-003"
  - "specs/kernel/SPEC.md#BR-006"
files:
  - "shutdown.go"
  - "internal/signal/signal.go"
  - "shutdown_test.go"
  - "internal/signal/signal_test.go"
acceptance_criteria:
  - "AC-NEW-28: Shutdown 按启动反序调用 Stop"
  - "AC-NEW-29: Stop 超时 → deadline 后强制返回 ErrShutdownTimeout"
  - "AC-NEW-30: Shutdown 幂等 → 第二次调用返回 nil"
  - "AC-NEW-31: Shutdown before Run → 返回 nil"
  - "AC-NEW-32: Shutdown 进行中再次调用返回 ErrShutdownInProgress"
  - "AC-NEW-33: 超时模块名被记录"
depends_on:
  - "TASK-KERNEL-001"
  - "TASK-KERNEL-004"
estimated_effort: "3h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-003 | Shutdown：反序停止、超时 force、ctx 取消、幂等、进行中拒绝 | 5 个 WHEN/THEN 场景 |
| BR-003 | 停止顺序必须是启动反序 | 反序遍历启动列表 |
| BR-006 | Stop 超时后 force shutdown，记录未完成模块 | 超时后跳过并记录 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| TC-001 | Unit | 正常停止：按启动反序调用 Stop |
| TC-004 | Unit | 停止超时：Stop 耗时超过 deadline → 返回 ErrShutdownTimeout |
| TC-011 | Unit | Shutdown 幂等：第二次调用返回 nil |
| TC-012 | Unit | Shutdown before Run：返回 nil |
| — | Unit | Shutdown 进行中：再次调用返回 ErrShutdownInProgress |
| — | Unit | ctx 取消：Shutdown 过程中 ctx cancel → 立即返回 |
| — | Unit | signal 触发：收到 SIGTERM → 自动调用 Shutdown |

## Implementation Notes

- Shutdown 内部流程：检查状态 → 设置 shutting_down 标志 → 反序遍历已启动模块 → 逐个 Stop（带 deadline） → 记录未完成模块
- 使用 `time.After` 或 `context.WithTimeout` 实现 per-module 超时
- `internal/signal` 包封装 `os.Signal`，提供 `Notify` 和 `Stop` 方法
- signal handler 通过 channel 接收信号后调用 app.Shutdown
- Shutdown 完成后设置 `stopped` 标志，清空 `started` 标志

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 Shutdown 状态检查：未运行→返回 nil，进行中→ErrShutdownInProgress | `shutdown.go` | `go test ./... -run TestShutdownState` 通过 |
| 2 | 实现反序 Stop：遍历 startedModules 反序，逐个调用 Stop（带 deadline） | `shutdown.go` | TC-001 通过 |
| 3 | 实现 per-module 超时：使用 context.WithTimeout，超时后记录模块名并跳过 | `shutdown.go` | TC-004 通过 |
| 4 | 实现幂等性：第二次调用返回 nil，进行中再次调用返回 ErrShutdownInProgress | `shutdown.go` | TC-011, TC-012 通过 |
| 5 | 实现 `internal/signal` 包：封装 os.Signal，提供 Notify/Stop 方法，SIGTERM 触发 Shutdown | `internal/signal/signal.go` | `go test ./internal/signal/...` 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 超时后未记录未完成模块 | Medium | Medium | 用 slice 记录超时模块名，日志输出 |
| Shutdown 幂等性竞态 | Low | High | 用 mutex 保护 shutting_down 标志 |
