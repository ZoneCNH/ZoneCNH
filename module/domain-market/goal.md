# domain-market Goal

| 字段 | 值 |
| --- | --- |
| 模块 | `domain-market` |
| 层级 | L2.5 领域共享 |
| 仓库 | <https://github.com/ZoneCNH/domain-market> |
| 当前版本 | v1.0.1 |
| 目标版本 | v1.0.0 |
| 状态 | v1.0.0 基线与 v1.0.1 patch 已公开发布 |
| 发布证据 | <https://github.com/ZoneCNH/domain-market/releases/tag/v1.0.1> |
| 最后更新 | 2026-06-15 |

## 目标

`domain-market` 是 ZoneCNH 的市场数据语义源，统一研究、回测、实盘、provider 和策略之间的 Tick、Quote、Bar、OrderBook、Instrument、Funding、OpenInterest、LongShortRatio 与数据质量语义。

## 非目标

- 不实现 HTTP、WebSocket、Kafka、数据库或交易所 SDK adapter。
- 不承载策略、因子、回测、执行或风险逻辑。
- 不在领域模型中泄漏 provider 原始响应、transport DTO、ORM tag 或存储细节。

## v1.0.0 成功标准

- 公开价格、数量、成交额、费率、未平仓等金融字段使用 `decimalx.Decimal` 或明确值对象，禁止 public `float64`。
- Market data quality gate 必须 fail-closed，脏数据、时间非法数据不得进入下游。
- 时间语义明确：event time、source time、received time、available time 的排序与缺失策略可验证。
- 与 `domainx` 的边界清晰：市场侧可保留 trade aggressor side；订单类型、订单方向和订单状态归 `domainx`。
- Provider contract 只表达领域语义，不绑定 transport 或 vendor DTO。

## 发布证据

| 证据 | 值 |
| --- | --- |
| GitHub Release | <https://github.com/ZoneCNH/domain-market/releases/tag/v1.0.1> |
| Tag target | `7bf9d6c311ba9bff9241440fcf1337691d80d02c` |
| 本地验证 | `go test -count=1 ./...` |
| 结果 | 通过 |
