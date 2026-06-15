# domain-exchange v1.0.0 Spec

- Status: Draft
- Spec-Version: v1.0.0
Module-Version: v0.1.0 -> v1.0.0
Layer: L2.5 领域共享
Repository: https://github.com/ZoneCNH/domain-exchange
Source-Plan: /home/zone/Downloads/0615/ZoneCNH-v1.0.0-goal-execution-plans/domain-exchange-v1.0.0-goal-execution-plan.md
- Last-Updated: 2026-06-15

## 1. 范围

`domain-exchange` 定义交易所领域接口和 adapter SPI，承接 venue capability、request、error、rate limit、registry 和 streaming 语义。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | Exchange SPI、Place/Cancel/Query request、VenueCapability、RateLimitPolicy、ExchangeError、Registry |
| Depends on | `kernel`、`decimalx`、`domain-market`、`domainx` |
| Excludes | 真实交易所客户端、订单状态 SSOT、市场数据值对象、策略/风控/账本逻辑 |
| Boundary with domainx | `domainx` 拥有 Order、Trade、Position、Portfolio、ExecutionReport、OrderSide/Type/State |
| Boundary with domain-market | `domain-market` 拥有 Kline/OrderBook/Funding/OpenInterest 等行情模型 |

## 3. 功能需求

| ID | 需求 |
| --- | --- |
| FR-EXC-001 | Exchange SPI 必须拆分读写能力接口，避免单个巨型 interface。 |
| FR-EXC-002 | 下单、撤单、查询请求必须表达 client id、idempotency、venue 与 instrument。 |
| FR-EXC-003 | ExchangeError 必须区分临时错误、永久错误、限速、认证、余额、精度和不支持能力。 |
| FR-EXC-004 | VenueCapability、RateLimitPolicy、VenueProfile 必须可静态描述并可测试。 |
| FR-EXC-005 | Registry 必须线程安全，支持 fake exchange 注入。 |
| FR-EXC-006 | MarketReader 必须返回 `domain-market` 类型，不重复定义行情模型。 |
| FR-EXC-007 | Order 相关返回必须采用 `domainx` 类型或短期兼容 alias，不建立第二套订单 SSOT。 |

## 4. 非功能需求

- Adapter 友好：SPI 稳定，但不绑定任何单一 vendor API。
- Fail-closed：未知能力、未知错误和不安全重试必须默认失败。
- 可测试：所有能力、错误和 retry/idempotency 语义必须可用 fake exchange 验证。

## 5. 发布门禁

| 门禁 | 要求 |
| --- | --- |
| 边界门禁 | 不重复拥有 `domainx` 和 `domain-market` 的公共模型。 |
| SPI 门禁 | 接口拆分后下游 adapter 可按能力实现。 |
| 错误门禁 | retry/idempotency/rate limit 有明确测试。 |
| 下游门禁 | fake exchange 与至少一个 downstream smoke 通过。 |

## 6. Consumers

- 待补齐：v1.0.0 planning SPEC 尚未展开本节；不得据此推断 release、live 或 factory 成熟度。

## 7. Functional Requirements

- 待补齐：v1.0.0 planning SPEC 尚未展开本节；不得据此推断 release、live 或 factory 成熟度。

## 8. Business Rules

- 待补齐：v1.0.0 planning SPEC 尚未展开本节；不得据此推断 release、live 或 factory 成熟度。

## 9. Interface Contract

- 待补齐：v1.0.0 planning SPEC 尚未展开本节；不得据此推断 release、live 或 factory 成熟度。

## 10. Data Model

- 待补齐：v1.0.0 planning SPEC 尚未展开本节；不得据此推断 release、live 或 factory 成熟度。

## 11. Config Schema

- 待补齐：v1.0.0 planning SPEC 尚未展开本节；不得据此推断 release、live 或 factory 成熟度。

## 12. Error Handling

- 待补齐：v1.0.0 planning SPEC 尚未展开本节；不得据此推断 release、live 或 factory 成熟度。

## 13. Edge Cases

- 待补齐：v1.0.0 planning SPEC 尚未展开本节；不得据此推断 release、live 或 factory 成熟度。

## 14. Directory Structure

- 待补齐：v1.0.0 planning SPEC 尚未展开本节；不得据此推断 release、live 或 factory 成熟度。

## 15. Dependencies

- 待补齐：v1.0.0 planning SPEC 尚未展开本节；不得据此推断 release、live 或 factory 成熟度。

## 16. Testing

- 待补齐：v1.0.0 planning SPEC 尚未展开本节；不得据此推断 release、live 或 factory 成熟度。

## 17. Performance Budget

- 待补齐：v1.0.0 planning SPEC 尚未展开本节；不得据此推断 release、live 或 factory 成熟度。

## 18. Observability

- 待补齐：v1.0.0 planning SPEC 尚未展开本节；不得据此推断 release、live 或 factory 成熟度。

## 19. Security

- 待补齐：v1.0.0 planning SPEC 尚未展开本节；不得据此推断 release、live 或 factory 成熟度。

## 20. CI Gate

- 待补齐：v1.0.0 planning SPEC 尚未展开本节；不得据此推断 release、live 或 factory 成熟度。

## 21. Upgrade Compatibility

- 待补齐：v1.0.0 planning SPEC 尚未展开本节；不得据此推断 release、live 或 factory 成熟度。

## 22. Release DoD

- 待补齐：v1.0.0 planning SPEC 尚未展开本节；不得据此推断 release、live 或 factory 成熟度。

## 23. Open Questions

- 待补齐：v1.0.0 planning SPEC 尚未展开本节；不得据此推断 release、live 或 factory 成熟度。
