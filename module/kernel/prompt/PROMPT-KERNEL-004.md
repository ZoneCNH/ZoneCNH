# TASK-KERNEL-004 开发 Prompt

> 上游 Task：[TASK-KERNEL-004.md](./tasks/TASK-KERNEL-004.md)
> syncx 子包：并发控制原语 — SemaphoreLimiter + WorkerGroup

---

## 任务

实现 `kernel/syncx` 子包。提供上下文感知的信号量限制器和 goroutine 组管理，纯 stdlib。

## 文件清单

### 1. `syncx/syncx.go`

- `Limiter` 接口：`Acquire(ctx) error` / `Release()`
- `SemaphoreLimiter`：buffered channel 实现，`NewSemaphoreLimiter(n)`，n<=0 默认 1
- `WorkerGroup`：`NewWorkerGroup(ctx)` / `Go(fn)` / `TryGo(fn) bool` / `Wait() error`
- 首个 worker 错误触发 cancel 传播，Wait 收集所有错误

### 2. `syncx/syncx_test.go`

覆盖：Acquire/Release 并发安全（-race）、double-release 静默忽略、WorkerGroup 错误收集、cancel 传播、closed 后 TryGo 返回 false、无错误时 Wait 返回 nil。

### 3. `syncx/example_test.go`

展示 SemaphoreLimiter 限流 API 调用、WorkerGroup 并行任务管理。

## 验收标准

| AC          | 关联   | 验证命令                                         | 预期结果          |
| ----------- | ------ | ------------------------------------------------ | ----------------- |
| AC-015      | FR-011 | `go test -race -run TestSemaphore ./syncx/...`   | 并发安全          |
| AC-016      | FR-011 | `go test -race -run TestWorkerGroup ./syncx/...` | 错误收集 + cancel |
| AC-SYNCX-02 | BR-011 | double-release                                   | 静默忽略          |

## 禁止事项

- 不要依赖非 stdlib 包
- 不要使用 `sync.WaitGroup` 裸 API（WorkerGroup 已封装）
- SemaphoreLimiter 不要 panic（包括 double-release）

## 证据回填

完成后提交到 `docs/evidence/2026-06-12/TASK-KERNEL-004/`：
1. `go test -race -count=1 ./syncx/...` 输出
2. `go vet ./syncx/...` 输出
3. Race detector 通过证明

## 验证命令

| 命令                                 | 判定标准              |
| ------------------------------------ | --------------------- |
| `go build ./syncx/...`               | 编译通过，零错误      |
| `go test -race -count=1 ./syncx/...` | 全部测试通过，无 race |
| `go vet ./syncx/...`                 | 无警告                |

## 完成后

1. 运行 `go test -race -count=3 ./syncx/...` 确认无 flaky
2. 确认 SemaphoreLimiter 和 WorkerGroup 均通过 -race
3. 更新 TASK-KERNEL-004 状态为 completed
