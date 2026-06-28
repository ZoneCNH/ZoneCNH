# binancex Goal

| 字段 | 值 |
| --- | --- |
| 模块 | `binancex` |
| 层级 | L3 SDK 抽象层（binance ingest pipeline） |
| 仓库 | `github.com/ZoneCNH/runtime-patches/binancex` |
| 当前版本 | v0.1.0-patch |
| 目标版本 | v0.1.0-patch |
| 状态 | Patches 初始化 — 从 Go 源码反向提取，待 SPEC 创建 |
| 最后更新 | 2026-06-29 |

## 目标

`binancex` 定义交易所 SDK 抽象层。从 binance/server 提取 feed/session 接口为 `MarketDataFeed`，使 ingest pipeline 依赖接口而非具体 SDK 实现。支持 mock-based 测试、多交易所 adapter 多态，以及传输层（SDK）与 ingest 逻辑（server）的清晰分离。

## 非目标

- 不实现具体交易所 SDK（Binance/Bybit/OKX adapter 由各自模块实现）
- 不实现 HTTP/WebSocket 连接管理
- 不实现 market data 标准化逻辑（归一化由 binance/server 完成）
- 不引入第三方交易所 SDK 依赖

## v0.1.0 成功标准

- `MarketDataFeed` 接口含 6 个方法（Connect/Close/Subscribe/Unsubscribe/Events/Errors）
- `FeedEvent` 11 字段使用 canonical `domainmarket` 类型（InstrumentKey/EventType）
- `StreamSpec` 支持 InstrumentKey + Channel + Interval 订阅描述
- `FeedConfig` 9 字段含 Validate() 拒绝空 Endpoint 和 0 值 timeout/buffer
- `DefaultFeedConfig()` 返回生产安全默认值
- 接口编译期通过合规检查，支持 mock 实现

## 依赖

- stdlib（context, time, fmt）
- `github.com/ZoneCNH/runtime-patches/domain-market`（canonical 类型）

## 当前阻塞

| 优先级 | 阻塞项 | 处理方向 |
| --- | --- | --- |
| P0 | 缺少模块级 SPEC.md | 从 adapter.go 和 TRACEABILITY.md 提取创建 |
| P1 | 测试覆盖（adapter_test.go） | 补全 mock feed 实现和接口契约测试 |
| P2 | 文档对齐（README/CHANGELOG） | 发布前补齐 |
