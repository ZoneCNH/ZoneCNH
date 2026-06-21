# portfolio_engine 规格 ⚠️ DEPRECATED

> **⚠️ DEPRECATED — 已废弃**
>
> 本模块已被 **[`positionx`](../positionx/SPEC.md)** 取代。`portfolio_engine` 是早期占位仓库，不再维护，不应作为新开发依据。
>
> - **替代模块**：`positionx`（语义收窄：portfolio → position，定位为跨账户仓位管理）
> - **废弃日期**：2026-06-22（文档基线层标记；GitHub 仓库 README 已于 2026-06-20 加 DEPRECATED）
> - **本规格保留原因**：留作历史档案，避免外部链接 404；规格内容已冻结，不再修订

- Status: Deprecated
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-22
- Layer: 执行域 · 投资组合（已迁移至 positionx）
- Version: v1.0.0-spec
- Related: `CONSTITUTION.md`, `module/portfolio-engine/TRACEABILITY.md`, **`module/positionx/SPEC.md`（活跃规格）**

> 本文档发布 `portfolio_engine` 文档基线，不引入运行时代码、依赖或 wire schema。运行时实现与 `TC-PORTFOLIO_ENGINE-001`~`TC-PORTFOLIO_ENGINE-005` 测试进入后续阶段。

## 1. 摘要

`portfolio_engine` 实时追踪所有持仓和 PnL，提供组合层面的风险敞口视图，并向 `risk_engine` 与观测链路输出可审计的组合状态。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | 组合管理、PnL 实时计算、风险敞口监控、再平衡建议 |
| Depends on | `order_engine`（成交）、`settlement`（结算）、`domainx`（通用域对象） |
| Consumed by | `risk_engine`（敞口数据）、`observex`（PnL 可观测） |
| Excludes | 下单执行、行情接入、风控决策、存储与队列实现 |

## 3. 术语

| 术语 | 定义 |
| --- | --- |
| Position | 某一 instrument 在组合中的持仓状态。 |
| PnL | 组合盈亏结果，包含已实现与未实现部分。 |
| ExposureSlice | 按 instrument、venue、product_line 维度切分的敞口片段。 |
| RebalanceHint | 面向上游的再平衡建议，不是强制指令。 |

## 4. 功能需求

| ID | 需求 | WHEN | THEN |
| --- | --- | --- | --- |
| FR-001 | PnL 计算 | 成交发生或 mark price 更新 | 必须实时更新 position PnL = (mark_price - avg_entry) * qty。 |
| FR-002 | 敞口监控 | 敞口变化 | 必须按 instrument / venue / product_line 维度汇总净敞口。 |

## 5. 行为约束

| ID | 规则 |
| --- | --- |
| BR-001 | 输入校验 fail-closed，缺失成交或结算快照时不得静默修正。 |
| BR-002 | 输出不可变，下游只能读取已冻结组合视图。 |
| BR-003 | 不得使用 lookahead 数据回写历史持仓或 PnL。 |

## 6. 非功能需求

| ID | 类别 | 需求 |
| --- | --- | --- |
| NFR-001 | 可审计性 | 每个组合快照必须可追溯到成交、结算与行情来源。 |
| NFR-002 | 一致性 | 同一输入序列重复计算必须产出等价结果。 |
| NFR-003 | 可观测性 | 至少暴露组合净值、PnL、敞口分布与回撤相关指标。 |
| NFR-004 | 边界纯净 | 文档与后续 public API 不得泄露执行、存储或 vendor DTO 细节。 |

## 7. Acceptance Criteria Registry

| AC ID | FR/BR Ref | Criterion | Verification | Status |
| --- | --- | --- | --- | --- |
| AC-PORTFOLIO_ENGINE-001 | FR-001 | PnL 计算口径可独立复现，且与成交/行情输入一致。 | 文档引用检查 | Baseline Published |
| AC-PORTFOLIO_ENGINE-002 | FR-002 | 敞口监控口径可按 instrument / venue / product_line 稳定聚合。 | 文档引用检查 | Baseline Published |

## 8. 追溯与测试门禁

| 门禁 | 要求 | 当前状态 |
| --- | --- | --- |
| Traceability Gate | `module/portfolio-engine/TRACEABILITY.md` 已包含 FR/BR/AC/TC 映射，且 AC ID 与本 SPEC 对齐。 | Baseline Published |
| Test Gate | 后续实现必须覆盖 PnL 复算、敞口聚合、fail-closed 与重复输入等价性。 | Pending |
| Boundary Gate | 本 SPEC 不定义运行时代码、wire schema、数据库表或队列 topic。 | Baseline Published |

## 9. 版本记录

| 日期 | 版本 | 变更 | 作者 |
| --- | --- | --- | --- |
| 2026-06-21 | v1.0.0 | 从占位符扩充为完整文档基线，补齐边界、FR、BR、NFR、AC 与测试门禁 | ZoneCNH |
