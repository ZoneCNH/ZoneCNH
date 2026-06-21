# risk_engine 规格 ⚠️ DEPRECATED

> **⚠️ DEPRECATED — 已废弃**
>
> 本模块已被 **[`riskx`](../riskx/SPEC.md)** 取代。`risk_engine` 是早期占位仓库，不再维护，不应作为新开发依据。
>
> - **替代模块**：`riskx`（命名重构，职责不变）
> - **废弃日期**：2026-06-22（文档基线层标记；GitHub 仓库 README 已于 2026-06-20 加 DEPRECATED）
> - **本规格保留原因**：留作历史档案，避免外部链接 404；规格内容已冻结，不再修订

- Status: Deprecated
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-22
- Layer: 执行域 · 风险管理（已迁移至 riskx）
- Version: v1.0.0-spec
- Related: `CONSTITUTION.md`, `module/risk-engine/TRACEABILITY.md`, **`module/riskx/SPEC.md`（活跃规格）**

> 本文档发布 `risk_engine` 文档基线，不引入运行时代码、依赖或 wire schema。运行时实现与 `TC-RISK_ENGINE-001`~`TC-RISK_ENGINE-006` 测试进入后续阶段。

## 1. 摘要

`risk_engine` 是执行域的风控引擎。所有策略订单必须通过 `risk_engine` 的风控检查后，才能提交到 `order_engine`。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | 事前风控规则、回撤控制、熔断机制、风险限额、仓位约束 |
| Depends on | `signal_factory`（信号）、`portfolio_engine`（组合敞口）、`domainx`（通用域对象） |
| Consumed by | `order_engine`（风控通过后提交订单） |
| Excludes | 行情接入、订单执行、结算、组合状态持久化、存储与队列实现 |

## 3. 术语

| 术语 | 定义 |
| --- | --- |
| RiskRequest | 进入风控引擎的订单意图或检查请求。 |
| RiskDecision | 风控判断结果，包含通过、拒绝与熔断等分类。 |
| DrawdownWindow | 用于计算回撤阈值的时间窗口。 |
| RiskReport | 风控输出的审计摘要，包含曝光、回撤、限额与告警。 |

## 4. 功能需求

| ID | 需求 | WHEN | THEN |
| --- | --- | --- | --- |
| FR-001 | 订单风控 | 信号生成订单意向 | 必须检查仓位上限、单笔限额、回撤熔断与基础合规约束。 |
| FR-002 | 回撤熔断 | 日回撤大于阈值 | 必须熔断所有策略，禁止新订单。 |
| FR-003 | 风险报告 | 风控决策完成 | 必须输出 `RiskReport{Exposure, Drawdown, VaR, Limits}`。 |

## 5. 行为约束

| ID | 规则 |
| --- | --- |
| BR-001 | 输入校验 fail-closed，任何风控上下文缺失都不得放行。 |
| BR-002 | 输出不可变，下游只能读取风控冻结结果。 |
| BR-003 | 不得使用 lookahead 数据放宽风控阈值或回写历史决策。 |

## 6. 非功能需求

| ID | 类别 | 需求 |
| --- | --- | --- |
| NFR-001 | 可审计性 | 每次风控决策必须保留输入、规则命中与最终原因。 |
| NFR-002 | 一致性 | 同一输入序列与风控参数重复运行必须产出等价结果。 |
| NFR-003 | 响应性 | 风控检查不得成为订单链路的长尾阻塞点。 |
| NFR-004 | 边界纯净 | 文档与后续 public API 不得泄露执行、存储或 vendor DTO 细节。 |

## 7. Acceptance Criteria Registry

| AC ID | FR/BR Ref | Criterion | Verification | Status |
| --- | --- | --- | --- | --- |
| AC-RISK_ENGINE-001 | FR-001 | 订单风控规则可独立描述并复现。 | 文档引用检查 | Baseline Published |
| AC-RISK_ENGINE-002 | FR-002 | 回撤熔断阈值与熔断动作已被明确约束。 | 文档引用检查 | Baseline Published |
| AC-RISK_ENGINE-003 | FR-003 | 风险报告字段集已定稿且可供下游审计引用。 | 文档引用检查 | Baseline Published |

## 8. 追溯与测试门禁

| 门禁 | 要求 | 当前状态 |
| --- | --- | --- |
| Traceability Gate | `module/risk-engine/TRACEABILITY.md` 已包含 FR/BR/AC/TC 映射，且 AC ID 与本 SPEC 对齐。 | Baseline Published |
| Test Gate | 后续实现必须覆盖风控拒绝、熔断、报告生成与 fail-closed 路径。 | Pending |
| Boundary Gate | 本 SPEC 不定义运行时代码、wire schema、数据库表或队列 topic。 | Baseline Published |

## 9. 版本记录

| 日期 | 版本 | 变更 | 作者 |
| --- | --- | --- | --- |
| 2026-06-21 | v1.0.0 | 从占位符扩充为完整文档基线，补齐边界、FR、BR、NFR、AC 与测试门禁 | ZoneCNH |
