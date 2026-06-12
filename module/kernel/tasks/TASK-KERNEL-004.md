# TASK-KERNEL-004

> syncx 子包：并发控制原语

---

```yaml
task_id: TASK-KERNEL-004
module: kernel
scope: "实现 syncx 子包：Limiter 接口、SemaphoreLimiter、WorkerGroup"
spec_ref:
  - "module/kernel/SPEC.md#FR-011"
  - "module/kernel/SPEC.md#BR-011"
  - "module/kernel/SPEC.md#9.11"
files:
  - "syncx/syncx.go"
  - "syncx/syncx_test.go"
  - "syncx/example_test.go"
acceptance_criteria:
  - "AC-015: SemaphoreLimiter Acquire/Release 并发安全"
  - "AC-016: WorkerGroup 错误收集 + context 取消传播"
  - "AC-SYNCX-01: NewSemaphoreLimiter(n<=0) 默认容量为 1"
  - "AC-SYNCX-02: SemaphoreLimiter double-release 静默忽略"
  - "AC-SYNCX-03: WorkerGroup closed 后 TryGo 返回 false"
  - "AC-SYNCX-04: WorkerGroup 无错误时 Wait() 返回 nil"
  - "AC-SYNCX-05: go test -race -count=1 ./syncx/... 通过"
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
| FR-011 | 并发控制 |
| BR-011 | SemaphoreLimiter double-release 静默忽略 |

## Non-scope

- 不实现连接池或资源池
- 不实现分布式锁

## Implementation Notes

- SemaphoreLimiter 使用 buffered channel 实现信号量
- WorkerGroup 通过 errgroup 模式 + context 派生实现
- 首个 worker 错误触发 cancel，Wait() 收集所有错误
