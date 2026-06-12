# TASK-KERNEL-006

> shutdownx 子包：优雅停机 Hook 管理 + OS 信号处理

---

```yaml
task_id: TASK-KERNEL-006
module: kernel
scope: "实现 shutdownx 子包：Hook 接口、HookFunc 适配器、Manager LIFO、NotifyContext"
spec_ref:
  - "module/kernel/SPEC.md#FR-006"
  - "module/kernel/SPEC.md#BR-008"
  - "module/kernel/SPEC.md#9.6"
files:
  - "shutdownx/shutdownx.go"
  - "shutdownx/shutdownx_test.go"
  - "shutdownx/example_test.go"
acceptance_criteria:
  - "AC-009: Manager.Shutdown Hook LIFO 顺序，并发安全"
  - "AC-010: NotifyContext 正确捕获 OS signal 并传播 cancel"
  - "AC-SHUTDOWNX-01: Shutdown 时无 Hook 返回 nil"
  - "AC-SHUTDOWNX-02: 并发 Register + Shutdown 安全（快照后追加不执行）"
  - "AC-SHUTDOWNX-03: Manager.Hooks() 返回防御性拷贝"
  - "AC-SHUTDOWNX-04: HookFunc 适配器 Name()/Shutdown() 正确"
  - "AC-SHUTDOWNX-05: go test -race -count=1 ./shutdownx/... 通过"
depends_on:
  - "TASK-KERNEL-000"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description |
|---|---|
| FR-006 | 优雅停机 |
| BR-008 | Hook 按 LIFO 顺序执行 |

## Non-scope

- 不包含强制 kill / 超时逻辑（由调用方通过 context 控制）
- 不包含 HTTP shutdown endpoint

## Implementation Notes

- Manager 使用 mutex 保护 hooks 切片
- Shutdown 时对 hooks 做快照，LIFO 顺序执行
- errors.Join 聚合所有 Hook 的 Shutdown 错误
- NotifyContext 封装 signal.NotifyContext
