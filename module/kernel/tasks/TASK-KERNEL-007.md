# TASK-KERNEL-007

> panic 隔离：Init/Start/Stop panic catch，转换为错误

---

```yaml
task_id: TASK-KERNEL-007
module: kernel
scope: "为 Init/Start/Stop 添加 panic recovery，转换 panic 为错误，确保不传播到调用方"
spec_ref:
  - "module/kernel/SPEC.md#FR-002"
  - "module/kernel/SPEC.md#FR-003"
  - "module/kernel/SPEC.md#BR-007"
files:
  - "lifecycle.go"
  - "shutdown.go"
  - "lifecycle_test.go"
  - "shutdown_test.go"
acceptance_criteria:
  - "AC-007: 模块 Start panic 时，panic 被捕获并转换为错误"
  - "AC-NEW-37: 模块 Stop panic 时，panic 被捕获，后续模块继续被 Stop"
  - "AC-NEW-38: Start panic → 转换为错误并触发已启动模块回滚"
  - "AC-NEW-39: Init panic → 返回 ErrStartupFailed，不传播"
  - "AC-NEW-40: Stop panic → 记录日志，后续模块继续被 Stop"
depends_on:
  - "TASK-KERNEL-004"
  - "TASK-KERNEL-005"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Files Likely to Change

- `lifecycle.go` — 修改（Init/Start 增加 panic catch）
- `shutdown.go` — 修改（Stop 增加 panic catch）
- `lifecycle_test.go` — 新建
- `shutdown_test.go` — 新建

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-002 | Run 中 Init/Start panic 被捕获 | panic 转换为 ErrStartupFailed |
| FR-003 | Shutdown 中 Stop panic 被捕获 | panic 被捕获，后续模块继续 Stop |
| BR-007 | panic 必须被 catch，不传播到调用方 | 所有 panic 路径均有 recover |

## Non-scope

- 不实现启动逻辑（→ TASK-KERNEL-004）
- 不实现停机逻辑（→ TASK-KERNEL-005）
- 不实现健康检查（→ TASK-KERNEL-006）

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| TC-006 | Unit | panic 隔离（Start）：A.Start panic → 转换为错误并回滚 |
| TC-016 | Unit | Init panic 隔离：A.Init panic → 返回 ErrStartupFailed |
| TC-017 | Unit | Stop panic 隔离：A.Stop panic → 后续模块继续被 Stop |
| — | Unit | panic 消息保留：捕获的 panic 值包含在错误消息中 |

## Implementation Notes

- ⚠️ 本 task 修改 TASK-KERNEL-004 和 005 创建的文件，必须在两者完成后才能开始。
- 使用 `defer func() { if r := recover(); r != nil { ... } }()` 模式
- panic 值转换为 `fmt.Errorf("kernel: module %s panic: %v", name, r)`
- lifecycle.go 中的 panic recovery 包裹每个模块的 Init 和 Start 调用
- shutdown.go 中的 panic recovery 包裹每个模块的 Stop 调用
- Stop panic 不中断后续模块的 Stop（与 Init/Start panic 的 fail-fast 行为不同）

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 封装 `callWithRecovery` 辅助函数：接收模块名和函数，defer recover，panic 转为 error | `lifecycle.go` | `go build ./...` 通过 |
| 2 | 在 lifecycle.go 的 Init/Start 循环中用 callWithRecovery 包裹每个调用 | `lifecycle.go` | TC-016 (Init panic), TC-006 (Start panic) 通过 |
| 3 | 在 shutdown.go 的 Stop 循环中用 callWithRecovery 包裹，panic 不中断后续模块 | `shutdown.go` | TC-017 通过 |
| 4 | 验证 panic 消息保留在错误中：`fmt.Errorf("kernel: module %s panic: %v", name, r)` | 测试 | panic 消息包含模块名和原始值 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| recover 漏掉某些 panic 路径 | Low | High | 统一使用 callWithRecovery 辅助函数 |
| Stop panic 中断后续模块 | Medium | High | Stop 循环中 callWithRecovery 返回错误但不 break |
