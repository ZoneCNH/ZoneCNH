# TASK-KERNEL-005 开发 Prompt

> 上游 Task：[TASK-KERNEL-005.md](./tasks/TASK-KERNEL-005.md)
> lifecycx 子包：组件生命周期管理 — 有序启动/逆序停止/失败回滚

---

## 任务

实现 `kernel/lifecycx` 子包。管理一组 Component 的有序启动和逆序停止，启动失败自动回滚，纯 stdlib。

## 文件清单

### 1. `lifecycx/lifecycx.go`

- `Starter` 接口：`Start(ctx) error`
- `Stopper` 接口：`Stop(ctx) error`
- `Component` 接口：`Name() string` + Starter + Stopper
- `Manager` 结构体（未导出字段）
- `NewManager(components ...Component) *Manager`：防御性拷贝
- `Manager.Start(ctx) error`：按序启动，失败逆序回滚，errors.Join 聚合
- `Manager.Stop(ctx) error`：逆序停止，幂等（未 started 返回 nil）
- `Manager.Components() []Component`：防御性拷贝

### 2. `lifecycx/lifecycx_test.go`

覆盖：正常启停顺序、启动失败回滚、未启动 Stop 幂等、空 Component、回滚中 Stop 也失败时 errors.Join、Components 防御性拷贝。

### 3. `lifecycx/example_test.go`

展示注册多个 Component、启动、运行、停止的完整生命周期。

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-001 | FR-001 | 正常启停测试 | 按序启动、逆序停止 |
| AC-002 | FR-001 | 启动失败测试 | 回滚 + errors.Join |
| AC-LIFECYCX-02 | BR-003 | 未 started Stop | 返回 nil |

## 禁止事项

- 不要依赖非 stdlib 包
- 不要引入拓扑排序或依赖图
- 不要在 Start/Stop 中启动 goroutine（调用方负责并发）

## 证据回填

完成后提交到 `docs/evidence/2026-06-12/TASK-KERNEL-005/`：
1. `go test -race -count=1 ./lifecycx/...` 输出
2. `go vet ./lifecycx/...` 输出
3. 回滚场景日志证据

## 验证命令

| 命令 | 判定标准 |
|------|----------|
| `go build ./lifecycx/...` | 编译通过，零错误 |
| `go test -race -count=1 ./lifecycx/...` | 全部测试通过，无 race |
| `go vet ./lifecycx/...` | 无警告 |

## 完成后

1. 运行所有测试确认回滚逻辑正确
2. 验证 Manager 无 goroutine 泄漏
3. 更新 TASK-KERNEL-005 状态为 completed
