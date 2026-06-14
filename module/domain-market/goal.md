# domain-market Goal

| 字段 | 值 |
| --- | --- |
| 模块 | `domain-market` |
| 层级 | L2.5 领域共享 |
| 仓库 | <https://github.com/ZoneCNH/domain-market> |
| 当前版本 | v0.1.0 |
| 目标版本 | v1.0.0 |
| 状态 | v1.0.0 执行计划待落地 |
| 计划来源 | `/home/zone/Downloads/0615/ZoneCNH-v1.0.0-goal-execution-plans/domain-market-v1.0.0-goal-execution-plan.md` |
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

## 当前阻塞

| 优先级 | 阻塞项 | 处理方向 |
| --- | --- | --- |
| P0 | 当前版本仍为 v0.1.0 | 建立 v1 API freeze 与 release gate |
| P0 | 缺少模块级 SPEC / TRACEABILITY | 本目录补齐规划基线，代码仓库继续落地 |
| P0 | validator 与质量门禁证据不足 | 增加 invalid time、dirty data、zero/negative value 测试 |
| P0 | 与 `domainx` 的 enum overlap | 保留 market side，迁出订单语义 |
| P1 | provider error 与 transport 边界不清 | 定义领域错误而非 vendor/transport 错误 |
