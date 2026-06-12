# TASK-KERNEL-006 开发 Prompt

> 上游 Task：[TASK-KERNEL-006.md](./tasks/TASK-KERNEL-006.md)
> shutdownx 子包：优雅停机 — Hook LIFO 管理 + OS 信号处理

---

## 任务

实现 `kernel/shutdownx` 子包。管理 LIFO 顺序的关闭钩子和 OS 信号处理，纯 stdlib。

## 文件清单

### 1. `shutdownx/shutdownx.go`

- `Hook` 接口：`Name() string` / `Shutdown(ctx) error`
- `HookFunc` 适配器：`{NameValue, Fn}` → 实现 Hook
- `Manager` 结构体（mutex 保护）
- `NewManager(hooks ...Hook) *Manager`：防御性拷贝
- `Manager.Register(hook)`：并发安全追加
- `Manager.Shutdown(ctx) error`：LIFO 顺序执行，快照后 Register 不执行，errors.Join 聚合
- `Manager.Hooks() []Hook`：防御性拷贝
- `NotifyContext(parent, signals...)`：封装 signal.NotifyContext

### 2. `shutdownx/shutdownx_test.go`

覆盖：LIFO 顺序、空 Hook、并发 Register+Shutdown、快照后追加不执行、HookFunc 适配器、NotifyContext 信号捕获。

### 3. `shutdownx/example_test.go`

展示注册 Shutdown Hook、绑定 OS 信号、优雅停机的完整流程。

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-009 | FR-006 | LIFO 顺序测试 | 后注册先执行 |
| AC-010 | FR-006 | NotifyContext 测试 | signal → cancel |
| AC-SHUTDOWNX-02 | BR-008 | 并发 Register+Shutdown | 快照后追加不执行 |

## 禁止事项

- 不要依赖非 stdlib 包
- 不要在 Shutdown 中强制 kill（由调用方 context 控制超时）
- 不要暴露 HTTP shutdown endpoint（属于应用层）

## 证据回填

完成后提交到 `docs/evidence/2026-06-12/TASK-KERNEL-006/`：
1. `go test -race -count=1 ./shutdownx/...` 输出
2. LIFO 顺序验证日志
3. 并发安全测试证据

## 验证命令

| 命令 | 判定标准 |
|------|----------|
| `go build ./shutdownx/...` | 编译通过，零错误 |
| `go test -race -count=1 ./shutdownx/...` | 全部测试通过，无 race |
| `go vet ./shutdownx/...` | 无警告 |

## 完成后

1. 运行 `go test -race -count=3 ./shutdownx/...` 确认无 flaky
2. 验证 Manager 无 goroutine 泄漏
3. 更新 TASK-KERNEL-006 状态为 completed
