# domain-exchange Goal

| 字段 | 值 |
| --- | --- |
| 模块 | `domain-exchange` |
| 层级 | L2.5 领域共享 |
| 仓库 | <https://github.com/ZoneCNH/domain-exchange> |
| 当前版本 | v1.0.0 |
| 目标版本 | v1.0.0 |
| 状态 | v1.0.0 已公开发布 |
| 发布证据 | <https://github.com/ZoneCNH/domain-exchange/releases/tag/v1.0.0> |
| 最后更新 | 2026-06-15 |

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

## 发布证据

| 证据 | 值 |
| --- | --- |
| GitHub Release | <https://github.com/ZoneCNH/domain-exchange/releases/tag/v1.0.0> |
| Tag target | `9c11c421ef643768690eb45c88f7b89dbda3afc8` |
| 本地验证 | `go test -count=1 ./...` |
| 公开依赖 | `decimalx v1.0.0` / `domain-market v1.0.1` / `domainx v1.0.1` |
| 结果 | 通过 |
