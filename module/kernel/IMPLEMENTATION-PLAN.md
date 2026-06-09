# kernel 实现计划

> 来源：module/kernel/SPEC.md v1.1.0 + TASK-KERNEL-000~010
> 生成日期：2026-06-08

---

## 依赖 DAG

```text
TASK-KERNEL-000 (骨架)
├── TASK-KERNEL-001 (接口)
│   ├── TASK-KERNEL-002 (依赖图)
│   ├── TASK-KERNEL-003 (注册表)
│   │   └── TASK-KERNEL-004 (启动)
│   │       └── TASK-KERNEL-005 (停机)
│   │           └── TASK-KERNEL-007 (panic 隔离)
│   ├── TASK-KERNEL-006 (健康检查) ← 依赖 001, 003
│   └── TASK-KERNEL-008 (配置选项) ← 依赖 001
│       └── TASK-KERNEL-009 (集成测试) ← 依赖 004, 005, 006, 007, 008
│           └── TASK-KERNEL-010 (文档+示例) ← 依赖 009
```

---

## 实现顺序

| Phase | Task            | 文件                                   | 依赖     | 可并行              | Effort | 验证命令                                                                                |
| ----- | --------------- | -------------------------------------- | -------- | ------------------- | ------ | --------------------------------------------------------------------------------------- |
| 1     | TASK-KERNEL-000 | go.mod, doc.go, errors.go              | —        | —                   | 0.5h   | `go build ./... && go list -deps ./... \| grep -v "^std" && go vet ./...`               |
| 2     | TASK-KERNEL-001 | kernel.go, interfaces.go               | 000      | —                   | 1h     | `go build ./... && go vet ./...`                                                        |
| 3a    | TASK-KERNEL-002 | graph.go, graph_test.go                | 001      | ✅ 与 003, 008 并行 | 3h     | `go test -race -run TestGraph -count=1 ./...`                                           |
| 3b    | TASK-KERNEL-003 | registry.go, registry_test.go          | 001      | ✅ 与 002, 008 并行 | 2h     | `go test -race -run TestRegistry -count=1 ./...`                                        |
| 3c    | TASK-KERNEL-008 | options.go, kernel.go, options_test.go | 001      | ✅ 与 002, 003 并行 | 1h     | `go test -race -run TestOption -count=1 ./...`                                          |
| 4     | TASK-KERNEL-004 | lifecycle.go, lifecycle_test.go        | 002, 003 | —                   | 4h     | `go test -race -run TestLifecycle -count=1 ./...`                                       |
| 5     | TASK-KERNEL-005 | shutdown.go, shutdown_test.go          | 004      | —                   | 3h     | `go test -race -run TestShutdown -count=1 ./...`                                        |
| 6     | TASK-KERNEL-006 | health.go, health_test.go              | 001, 003 | —                   | 1.5h   | `go test -race -run TestHealth -count=1 ./...`                                          |
| 7     | TASK-KERNEL-007 | lifecycle.go, shutdown.go (修改)       | 004, 005 | —                   | 2h     | `go test -race -run TestPanic -count=1 ./...`                                           |
| 8     | TASK-KERNEL-009 | integration_test.go, benchmark_test.go | 004-008  | —                   | 3h     | 集成：`go test -tags=integration -race ./...` + 性能：`go test -bench=. -benchmem -count=3 ./...` |
| 9     | TASK-KERNEL-010 | README.md, example_test.go             | 009      | —                   | 2h     | `go test -race ./... && go test -coverprofile=c.out ./... && go tool cover -func=c.out` |

---

## 关键路径

```text
000 → 001 → 002/003 → 004 → 005 → 007 → 009 → 010
```

**关键路径工期**：0.5 + 1 + 3 + 4 + 3 + 2 + 3 + 2 = **18.5h**

---

## 并行策略

### Phase 3（最大并行度 3）

TASK-KERNEL-002、003、008 互相无依赖，可同时开发：

- 002（graph.go）：DAG 算法、环检测、拓扑排序
- 003（registry.go）：并发安全注册表
- 008（options.go）：Option 模式配置

### Phase 6（可选并行）

TASK-KERNEL-006（健康检查）与 Phase 4-5（lifecycle/shutdown）无文件冲突，但依赖 003 完成。可在 004 进行中并行开始。

---

## 文件冲突分析

| 文件         | 创建 Task | 修改 Task | 冲突风险    |
| ------------ | --------- | --------- | ----------- |
| kernel.go    | 001       | 008       | ⚠️ 顺序执行 |
| lifecycle.go | 004       | 007       | ⚠️ 顺序执行 |
| shutdown.go  | 005       | 007       | ⚠️ 顺序执行 |
| graph.go     | 002       | —         | 无          |
| registry.go  | 003       | —         | 无          |
| health.go    | 006       | —         | 无          |
| options.go   | 008       | —         | 无          |
| errors.go    | 000       | —         | 无          |

---

## 测试策略

| 测试类型    | 覆盖 Task | 工具                         |
| ----------- | --------- | ---------------------------- |
| 单元测试    | 002~008   | `go test -race -count=1`     |
| 集成测试    | 009       | `go test -tags=integration`  |
| Benchmark   | 009       | `go test -bench=. -benchmem` |
| stdlib-only | 000, 001  | CI gate                      |
| 覆盖率      | ALL       | `go tool cover` ≥ 90%        |

---

## 风险与缓解

| 风险                | 影响              | 缓解                                        |
| ------------------- | ----------------- | ------------------------------------------- |
| 拓扑排序算法 bug    | 启动顺序错误      | 充分测试：自引用、互引用、深层链、100+ 节点 |
| panic recovery 遗漏 | 调用方崩溃        | 逐一检查 Init/Start/Stop 调用点             |
| 并发安全            | race condition    | `-race` 测试 + `sync.Mutex` 保护            |
| stdlib-only 被破坏  | CONSTITUTION 违反 | CI gate + `go list -deps`                   |

---

## 回滚策略

### TASK-KERNEL-004（启动生命周期）

| 失败场景          | 回滚步骤                                                       |
| ----------------- | -------------------------------------------------------------- |
| 拓扑排序 panic    | 捕获 panic → 返回 ErrStartupFailed → 不调用任何模块 Init/Start |
| 某模块 Init 失败  | 遍历已 Init 模块反序调用 Stop → 返回原始错误                   |
| 某模块 Start 失败 | 遍历已 Start 模块反序调用 Stop → 返回原始错误                  |
| ctx 取消          | 检测 ctx.Done() → 遍历已启动模块反序 Stop → 返回 ctx.Err()     |

### TASK-KERNEL-005（停机生命周期）

| 失败场景          | 回滚步骤                                                             |
| ----------------- | -------------------------------------------------------------------- |
| 某模块 Stop 超时  | 记录超时模块名 → 继续 Stop 后续模块 → 返回 ErrShutdownTimeout        |
| 某模块 Stop panic | 捕获 panic → 记录日志 → 继续 Stop 后续模块                           |
| 并发 Shutdown     | 互斥锁保护 → 第二次调用返回 ErrShutdownInProgress 或 nil（已完成后） |
