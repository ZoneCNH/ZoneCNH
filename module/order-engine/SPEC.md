# order_engine 规格

- Status: Docs Baseline Approved
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-21
- Layer: 执行域 · 订单执行
- Version: v1.0.0-spec
- Related: `CONSTITUTION.md`, `module/order-engine/TRACEABILITY.md`

> 本文档发布 `order_engine` 文档基线，不引入运行时代码、依赖或 wire schema。运行时实现与 `TC-ORDER_ENGINE-001`~`TC-ORDER_ENGINE-006` 测试进入后续阶段。

## 1. 摘要

`order_engine` 抽象交易所差异，管理订单从创建到成交、撤销和拒绝的完整生命周期，并向组合与结算链路输出可审计结果。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | 订单生命周期、SOR 智能路由、执行算法（TWAP/VWAP）、Exchange 抽象适配 |
| Depends on | `risk_engine`（风控通过）、`domain_exchange`（VenueAdapter）、`contracts`（订单/执行契约） |
| Consumed by | `portfolio_engine`（成交更新）、`settlement`（结算） |
| Excludes | 风控决策、组合计算、结算计算、行情接入、存储与队列实现 |

## 3. 术语

| 术语 | 定义 |
| --- | --- |
| OrderIntent | 下单前的意图对象，尚未进入交易所执行。 |
| OrderState | 订单生命周期状态，如 `NEW`、`PENDING`、`PARTIAL`、`FILLED`、`CANCELLED`、`REJECTED`。 |
| RoutingDecision | SOR 路由决策结果。 |
| ExecutionAlgo | 订单执行算法，例如 TWAP、VWAP 或其受控变体。 |
| ExchangeAdapter | 交易所适配器，用于屏蔽不同 venue 的执行差异。 |

## 4. 功能需求

| ID | 需求 | WHEN | THEN |
| --- | --- | --- | --- |
| FR-001 | 订单生命周期 | 创建订单 | 状态必须按 `NEW→PENDING→PARTIAL→FILLED/CANCELLED/REJECTED` 演进。 |
| FR-002 | SOR 路由 | 多交易所可用 | 必须按流动性、手续费与延迟选择最优路由。 |
| FR-003 | Order DTO | 提交订单 | 必须输出 `Order{Symbol,Side,Qty,Price,Type,TIF,Exchange}`。 |

## 5. 行为约束

| ID | 规则 |
| --- | --- |
| BR-001 | 输入校验 fail-closed，缺少订单关键字段不得进入执行链路。 |
| BR-002 | 输出不可变，下游只能读取已冻结订单结果。 |
| BR-003 | 不得使用 lookahead 数据重写历史执行决策。 |

## 6. 非功能需求

| ID | 类别 | 需求 |
| --- | --- | --- |
| NFR-001 | 可审计性 | 每笔订单状态变更必须可追溯到风控、路由与交易所回执。 |
| NFR-002 | 一致性 | 同一输入序列重复执行必须遵守相同的状态机约束。 |
| NFR-003 | 可观测性 | 至少暴露订单数量、成交率、拒绝率、路由分布与执行时延。 |
| NFR-004 | 边界纯净 | 文档与后续 public API 不得泄露 vendor DTO、传输标签或存储细节。 |

## 7. Acceptance Criteria Registry

| AC ID | FR/BR Ref | Criterion | Verification | Status |
| --- | --- | --- | --- | --- |
| AC-ORDER_ENGINE-001 | FR-001 | 订单状态机可独立描述并复现。 | 文档引用检查 | Baseline Published |
| AC-ORDER_ENGINE-002 | FR-002 | SOR 路由准则可按流动性、手续费与延迟稳定表达。 | 文档引用检查 | Baseline Published |
| AC-ORDER_ENGINE-003 | FR-003 | Order DTO 字段集已冻结，且能被下游追溯。 | 文档引用检查 | Baseline Published |

## 8. 追溯与测试门禁

| 门禁 | 要求 | 当前状态 |
| --- | --- | --- |
| Traceability Gate | `module/order-engine/TRACEABILITY.md` 已包含 FR/BR/AC/TC 映射，且 AC ID 与本 SPEC 对齐。 | Baseline Published |
| Test Gate | 后续实现必须覆盖状态机、SOR 路由、DTO 输出与 fail-closed 路径。 | Pending |
| Boundary Gate | 本 SPEC 不定义运行时代码、wire schema、数据库表或队列 topic。 | Baseline Published |

## 9. 版本记录

| 日期 | 版本 | 变更 | 作者 |
| --- | --- | --- | --- |
| 2026-06-21 | v1.0.0 | 从占位符扩充为完整文档基线，补齐边界、FR、BR、NFR、AC 与测试门禁 | ZoneCNH |
