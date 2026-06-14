# domain-market v1.0.0 Spec

Status: Draft
Spec-Version: v1.0.0-plan
Module-Version: v0.1.0 -> v1.0.0
Layer: L2.5 领域共享
Repository: https://github.com/ZoneCNH/domain-market
Source-Plan: /home/zone/Downloads/0615/ZoneCNH-v1.0.0-goal-execution-plans/domain-market-v1.0.0-goal-execution-plan.md
Last-Updated: 2026-06-15

## 1. 范围

`domain-market` 定义市场数据领域模型与质量门禁，是上层行情采集、研究、回测、策略和执行服务共享的市场语义 SSOT。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | Tick、Quote、Bar、OrderBook、Instrument、Funding、OpenInterest、LongShortRatio、DataProvider、MarketDataQuality |
| Depends on | `kernel`、`decimalx` |
| Excludes | transport adapter、provider DTO、数据库 tag、策略/因子/回测逻辑、订单生命周期语义 |
| Boundary with domainx | `domainx` 拥有 OrderType、OrderSide、OrderState；`domain-market` 仅表达市场事件与行情侧方向语义 |

## 3. 功能需求

| ID | 需求 |
| --- | --- |
| FR-MKT-001 | 市场价格、数量、成交量、金额、费率等公开金融字段必须使用 `decimalx.Decimal` 或值对象。 |
| FR-MKT-002 | Tick、Quote、Bar、OrderBook 必须校验 symbol、timestamp、价格/数量边界和 bid/ask 关系。 |
| FR-MKT-003 | MarketDataQuality 必须 fail-closed，拒绝 dirty、stale、time-invalid 数据。 |
| FR-MKT-004 | Instrument 必须表达交易品种标识、市场类型、价格/数量精度和可交易状态。 |
| FR-MKT-005 | Funding、OpenInterest、LongShortRatio 必须有明确时间语义与数据来源。 |
| FR-MKT-006 | DataProvider contract 必须返回领域模型，不暴露 HTTP/WS/DB/vendor DTO。 |
| FR-MKT-007 | 与 `domainx` 重叠的订单枚举必须迁出或废弃，避免双 SSOT。 |

## 4. 非功能需求

- 质量优先：非法数据默认拒绝，不做静默修正。
- 领域纯净：公共模型中不得出现 transport、persistence 或 vendor schema tag。
- 下游稳定：v1.0.0 后公共字段含义和时间语义需保持兼容。

## 5. 发布门禁

| 门禁 | 要求 |
| --- | --- |
| 精度门禁 | public price/qty/money/rate fields 无 `float64`。 |
| 边界门禁 | 不含 HTTP/WS/DB/Kafka/TDengine/vendor DTO 泄漏。 |
| 质量门禁 | dirty/stale/time-invalid 数据有 fail-closed 测试。 |
| 下游门禁 | `domain-exchange` 可采用 market data types。 |
