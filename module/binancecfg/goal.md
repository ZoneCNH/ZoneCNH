# binancecfg Goal

| 字段 | 值 |
| --- | --- |
| 模块 | `binancecfg` |
| 层级 | L3 配置层（binance ingest pipeline） |
| 仓库 | `github.com/ZoneCNH/runtime-patches/binancecfg` |
| 当前版本 | v0.1.0-patch |
| 目标版本 | v0.1.0-patch |
| 状态 | Patches 初始化 — 从 Go 源码反向提取，待 SPEC 创建 |
| 最后更新 | 2026-06-29 |

## 目标

`binancecfg` 为 binance ingest pipeline 提供类型化配置加载层。从 `FOUNDATIONX_BINANCE_*` 环境变量读取配置，提供生产安全默认值，并将统一 Config 转换为下游 `binance.ServerConfig` 和 `binancex.FeedConfig`，实现配置与命令逻辑的解耦。

## 非目标

- 不读取配置文件、配置中心或密钥管理服务
- 不实现 HTTP/gRPC server
- 不持有运行时状态或连接
- 不依赖第三方配置库

## v0.1.0 成功标准

- `LoadConfig()` 正确读取全部 13 个 `FOUNDATIONX_BINANCE_*` 环境变量
- 未设置变量回退到 `DefaultConfig()` 生产安全默认值
- `Validate()` 拒绝非法值（MaxStreams <= 0, DrainTimeout <= 0, ShutdownTimeout <= 0）
- `ServerConfig()` 正确映射 5 字段到 `binance.ServerConfig`
- `FeedConfig()` 正确映射 9 字段到 `binancex.FeedConfig`
- 非法环境变量值记录 structured log warning，使用默认值，不 panic
- 纯单元测试可覆盖，不依赖外部系统

## 依赖

- stdlib（os, time, strconv, log/slog, fmt）
- `github.com/ZoneCNH/runtime-patches/binance`（ServerConfig 类型）
- `github.com/ZoneCNH/runtime-patches/binancex`（FeedConfig 类型）

## 当前阻塞

| 优先级 | 阻塞项 | 处理方向 |
| --- | --- | --- |
| P0 | 缺少模块级 SPEC.md | 从 config.go 和 TRACEABILITY.md 提取创建 |
| P1 | 测试覆盖（config_test.go） | 补全 LoadConfig/Validate/转换 测试用例 |
| P2 | 文档对齐（README/CHANGELOG） | 发布前补齐 |
