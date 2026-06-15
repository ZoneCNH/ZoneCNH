# domain-exchange Goal

| 字段 | 值 |
| --- | --- |
| 模块 | `domain-exchange` |
| 层级 | L2.5 领域共享 |
| 仓库 | <https://github.com/ZoneCNH/domain-exchange> |
| 当前版本 | v0.1.0 |
| 目标版本 | v1.0.0 |
| 状态 | v1.0.0 执行计划已落地，任务已拆分 |
| 计划来源 | `/home/zone/Downloads/0615/ZoneCNH-v1.0.0-goal-execution-plans/domain-exchange-v1.0.0-goal-execution-plan.md` |
| 最后更新 | 2026-06-16 |

## 目标

`domain-exchange` 定义交易所适配 SPI，使基础设施层可将不同交易所的 API、错误、精度、能力和限速语义映射为统一领域接口。它不拥有最终订单生命周期模型，而是复用 `domainx` 和 `domain-market` 的共享语义。

## 非目标

- 不实现真实 Binance、OKX 或其他交易所客户端。
- 不定义最终 OrderState、Position、ExecutionReport 等交易域模型；这些归 `domainx`。
- 不定义市场行情值对象；这些归 `domain-market`。
- 不承载策略、风控、会计、账本或投资组合逻辑。

## v1.0.0 成功标准

- SPI 拆分为 AccountReader、OrderPlacer、OrderCanceler、OrderQuerier、MarketReader、DerivativeReader、Streamer 与组合 Exchange。
- Place/Cancel/Query 请求具备 idempotency key、client order id 与 retry-safe 语义。
- ExchangeError 区分临时错误、永久错误、限速、认证、余额不足、精度错误和 venue 不支持。
- VenueCapability、RateLimitPolicy、VenueProfile 与 Registry 线程安全且可测试。
- 返回 `domainx.Order` / `domainx.ExecutionReport` 与 `domain-market` 行情模型，避免重复 SSOT。

## 当前阻塞

| 优先级 | 阻塞项 | 处理方向 |
| --- | --- | --- |
| P0 | 当前 Order/Balance/PlaceOrderRequest 与 `domainx` 重叠 | 迁移为 SPI request/response 或兼容 alias |
| P0 | Exchange interface 过宽 | 拆分读写能力接口与组合接口 |
| P0 | retry/idempotency/rate limit 语义不足 | 在请求和错误模型中冻结 |
| P1 | registry concurrency 与 capability 表达不足 | 增加 fake exchange 与并发测试 |
