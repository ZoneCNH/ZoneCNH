# cmd 规格

- Spec-Version: v0.1.0
- Runtime-Version: v0.1.0-patch
- Status: Draft（从 patches/cmd/main.go 反向提取）
- Last-Updated: 2026-06-29
- Source: `patches/cmd/main.go`

## 1. 摘要

`cmd` 是 binance ingest pipeline 的组合根入口。核心逻辑提取到可测试的 `Run()` 函数中，`main()` 仅处理 `os.Exit`。`Run()` 执行 6 阶段管线：验证配置 → 装配中间件 → 构造 server → 连接 feed → 阻塞等待信号 → 优雅关闭。所有依赖通过 `assembly.ServerDeps` 注入，测试提供 mock。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | `Run()` 6 阶段管线编排、`main()` 进程入口 |
| Depends on | `runtime-patches/assembly`（Assemble/ServerDeps）、`runtime-patches/binance`（NewServer/IngestServer）、`runtime-patches/binancecfg`（LoadConfig/Config） |
| Consumed by | 进程入口（shell/systemd/container） |
| Excludes | ingest 逻辑、adapter/feed 实现、配置加载逻辑、中间件实现、业务状态 |

## 3. 术语

| 术语 | 定义 |
| --- | --- |
| Run() | 可测试的管线入口函数，注入所有依赖 |
| main() | 进程入口，仅 LoadConfig + ServerDeps + Run + os.Exit |
| 6 阶段管线 | validate → assemble → construct → connect → serve → drain |
| DrainTimeout | 优雅关闭最大等待时间，超时强制返回 |

## 4. Run() 管线

### 4.1 阶段 1: 配置验证

```go
if err := cfg.Validate(); err != nil {
    return fmt.Errorf("cmd: invalid config: %w", err)
}
```

### 4.2 阶段 2: 中间件装配

```go
assembled, err := assembly.Assemble(deps, middlewares...)
```

### 4.3 阶段 3: Server 构造

```go
srv := binance.NewServer(assembled.Validator, assembled.Idempotency, assembled.Dispatcher, assembled.Config)
```

### 4.4 阶段 4: Feed 连接

```go
if err := assembled.Feed.Connect(ctx); err != nil {
    return fmt.Errorf("cmd: feed connect failed: %w", err)
}
defer assembled.Feed.Close()
```

### 4.5 阶段 5: 阻塞等待信号

- SIGINT/SIGTERM → graceful shutdown
- context cancellation → shutdown
- Feed.Errors() 非 nil error → shutdown

### 4.6 阶段 6: 优雅关闭

```go
drainCtx, drainCancel := context.WithTimeout(context.Background(), cfg.ShutdownTimeout)
defer drainCancel()
```

## 5. 功能需求

| FR ID | Requirement |
| --- | --- |
| FR-CMD-001 | Run() — 可测试入口点：6 阶段有序执行 |
| FR-CMD-002 | 配置验证作为第一步，无效配置立即返回错误 |
| FR-CMD-003 | assembly.Assemble 注入中间件后构造 IngestServer |
| FR-CMD-004 | 信号处理：SIGINT/SIGTERM 触发优雅关闭 |
| FR-CMD-005 | 优雅关闭：context 取消后等待 DrainTimeout |
| FR-CMD-006 | main() 只处理 os.Exit(1)，所有逻辑委托给 Run() |

## 6. 行为约束

| BR ID | Rule |
| --- | --- |
| BR-CMD-001 | 所有依赖注入：Feed/Validator/Idempotency/Dispatcher 通过 assembly.ServerDeps 注入 |
| BR-CMD-002 | Feed.Connect 失败立即返回错误，不进入 serve loop |
| BR-CMD-003 | Feed.Errors() channel 非 nil error 触发 shutdown |
| BR-CMD-004 | ShutdownTimeout 通过 context.WithTimeout 强制执行 |

## 7. 非功能需求

| NFR ID | Requirement |
| --- | --- |
| NFR-CMD-001 | 结构化日志通过 slog，含 component 标签 |
| NFR-CMD-002 | 所有错误用 fmt.Errorf wrapping 保留调用链 |

## 8. Acceptance Criteria Registry

见 [TRACEABILITY.md §5](./TRACEABILITY.md)

## 9. 后续实现门禁

- Feed Gate: 实现真实 binancex.MarketDataFeed adapter
- Idempotency Gate: 实现真实 IdempotencyStore
- Dispatcher Gate: 实现真实 DownstreamDispatcher
- Test Gate: 对 Run() 各阶段编写 mock-based 测试

## 变更历史

| 日期 | 变更 |
| --- | --- |
| 2026-06-29 | v0.1.0 Draft：从 patches/cmd/main.go 反向提取，初始化 SPEC |
