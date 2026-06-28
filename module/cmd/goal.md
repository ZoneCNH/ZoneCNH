# cmd Goal

| 字段 | 值 |
| --- | --- |
| 模块 | `cmd` |
| 层级 | L3 组合根入口（binance ingest pipeline） |
| 仓库 | `github.com/ZoneCNH/runtime-patches/cmd` |
| 当前版本 | v0.1.0-patch |
| 目标版本 | v0.1.0-patch |
| 状态 | Patches 初始化 — 从 Go 源码反向提取，待 SPEC 创建 |
| 最后更新 | 2026-06-29 |

## 目标

`cmd` 是 binance ingest pipeline 的组合根入口。将核心逻辑提取到可测试的 `Run()` 函数中，`main()` 仅处理 os.Exit。`Run()` 执行 6 阶段管线：验证配置 → 装配中间件 → 构造 server → 连接 feed → 阻塞等待信号 → 优雅关闭。所有依赖通过 `assembly.ServerDeps` 注入，测试提供 mock。

## 非目标

- 不实现 ingest 逻辑（由 binance/server 实现）
- 不实现 adapter/feed 逻辑（由 binancex 实现）
- 不实现配置加载（由 binancecfg 实现）
- 不实现中间件（由 assembly 实现）
- 不持有业务状态

## v0.1.0 成功标准

- `Run()` 6 阶段有序执行：validate → assemble → construct → connect → serve → drain
- `cfg.Validate()` 失败 → Run() 返回 wrapped error，Feed.Connect 不执行
- SIGINT/SIGTERM 触发 cancel → drainCtx 超时强制返回 → Feed.Close() 执行
- `Feed.Errors()` channel 非 nil error 触发 shutdown
- 结构化日志含 component 标签，启动/停止/错误均记录
- 所有错误用 fmt.Errorf wrapping 保留调用链
- `main()` 仅 3 行：LoadConfig → ServerDeps → Run，Run 失败 os.Exit(1)

## 依赖

- stdlib（context, fmt, log/slog, os, os/signal, syscall）
- `github.com/ZoneCNH/runtime-patches/assembly`
- `github.com/ZoneCNH/runtime-patches/binance`
- `github.com/ZoneCNH/runtime-patches/binancecfg`

## 当前阻塞

| 优先级 | 阻塞项 | 处理方向 |
| --- | --- | --- |
| P0 | 缺少模块级 SPEC.md | 从 main.go 和 TRACEABILITY.md 提取创建 |
| P1 | Feed/Idempotency/Dispatcher 为 nil（TODO） | 实现真实 adapter 后注入 |
| P2 | 测试覆盖（main_test.go） | 对 Run() 各阶段编写 mock-based 测试 |
