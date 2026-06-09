# TASK-KERNEL-000 开发 Prompt

> 项目骨架：go.mod、doc.go、errors.go

---

## 任务

创建 `kernel` Go 包的项目骨架，包含 3 个文件。kernel 是 FoundationX L0 原语层，stdlib-only，零外部依赖。

## 文件清单

### 1. `go.mod`

```go
module github.com/ZoneCNH/kernel

go 1.24
```

- 无 `require` 块
- 无 `go.sum`（无外部依赖）

### 2. `doc.go`

```go
// Package kernel 提供应用的运行时骨架。
//
// kernel 负责把模块组织成一个可启动、可停止、可观测、可验证的应用。
// 它提供 App / Module / Lifecycle 抽象，统一管理 70+ 模块的生命周期。
//
// # 核心能力
//
//   - 模块注册与依赖图管理（自动检测循环依赖）
//   - 按拓扑序启动、反序停止
//   - 优雅停机（signal handling、deadline、force shutdown）
//   - 统一健康检查（readiness / liveness）
//   - panic 隔离（模块 panic 不传播到调用方）
//
// # 设计约束
//
// kernel 是 stdlib-only 的 L0 原语层。它不 import 任何 Foundation L1 包。
// L1 能力（配置、日志、指标、追踪）通过 Deps 结构体在组合根注入。
//
// # 快速开始
//
//	app := kernel.New(
//	    kernel.WithStartupTimeout(30 * time.Second),
//	)
//	app.Register(&myModule{})
//	if err := app.Run(ctx); err != nil {
//	    log.Fatal(err)
//	}
package kernel
```

### 3. `errors.go`

```go
package kernel

import "errors"

// 公共错误变量。所有错误前缀为 "kernel: "。
var (
    // ErrCycleDetected 依赖图中检测到环。
    ErrCycleDetected = errors.New("kernel: dependency cycle detected")

    // ErrModuleNotFound 查询的模块未注册。
    ErrModuleNotFound = errors.New("kernel: module not found")

    // ErrAlreadyRegistered 同名模块已注册。
    ErrAlreadyRegistered = errors.New("kernel: module already registered")

    // ErrStartupFailed 模块启动失败（Init 或 Start 返回错误）。
    ErrStartupFailed = errors.New("kernel: startup failed")

    // ErrShutdownTimeout 优雅停机超时，部分模块未完成 Stop。
    ErrShutdownTimeout = errors.New("kernel: shutdown timeout")

    // ErrNilModule Register 调用时传入 nil。
    ErrNilModule = errors.New("kernel: nil module")

    // ErrAlreadyRunning App 已在运行中，重复调用 Run。
    ErrAlreadyRunning = errors.New("kernel: app already running")

    // ErrAlreadyStopped App 已停止，无法再 Register。
    ErrAlreadyStopped = errors.New("kernel: app already stopped")

    // ErrAlreadyStarted App 已启动，不允许新增 Register。
    ErrAlreadyStarted = errors.New("kernel: app already started, register not allowed")

    // ErrShutdownInProgress 停机正在进行中，拒绝重复 Shutdown。
    ErrShutdownInProgress = errors.New("kernel: shutdown in progress")
)
```

## 验收标准

| AC | 关联 FR/TC | 验证命令 | 预期结果 |
|----|-----------|----------|----------|
| AC-008 | FR-001, BR-008, BR-009 | `go list -deps ./... \| grep -v "^std" \| grep -v "^github.com/ZoneCNH/kernel$"` | 无输出 |
| AC-NEW-01 | — | `go build ./...` | 编译通过 |
| AC-NEW-02 | — | `go vet ./...` | 无警告 |
| AC-NEW-03 | — | 检查 errors.go 包含 10 个 `Err` 变量 | 全部首字母大写 |

## 禁止事项

- 不要添加任何 `require` 依赖
- 不要创建 `_test.go` 文件（本 task 无业务逻辑可测）
- 不要创建除 go.mod、doc.go、errors.go 以外的文件
- 不要使用 `fmt.Errorf` 定义错误（必须用 `errors.New`）

## 证据回填

完成后提交以下产物到 `.config/goal/evidence/` 目录：

1. `go build ./...` 输出（编译通过）
2. `go vet ./...` 输出（无警告）
3. `go list -deps ./...` 输出（仅 stdlib）
4. `errors.go` 文件清单（10 个 Err 变量确认）
5. `go.mod` 内容确认（无 require 块）

## 完成后

1. 运行 `go build ./...` 确认编译通过
2. 运行 `go vet ./...` 确认无警告
3. 运行 `go list -deps ./...` 确认无外部依赖
4. 将证据产物写入 `.config/goal/evidence/2026-06-09/TASK-KERNEL-000/`
5. 将 task 状态更新为 completed
