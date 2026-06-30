# settlement 规格

- Status: Docs Baseline Approved
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-30
- Layer: 执行域 · 结算对账
- Version: v1.0.0-spec
- Related: `CONSTITUTION.md`, `module/settlement/TRACEABILITY.md`

> 本文档发布 settlement 文档基线，不引入运行时代码、依赖或 wire schema。运行时实现与 `TC-SETTLEMENT-001`~`TC-SETTLEMENT-005` 测试进入后续阶段。

## 1. 摘要

`settlement` 负责交易后的资金对账、手续费核算与结算结果归档，确保交易所余额、内部账本和成交明细之间可审计、一致、可回溯。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | 结算流程、资金对账、手续费核算、结算报告、差异告警口径 |
| Depends on | `order_engine`（成交记录）、`portfolio_engine`（持仓快照）、`domainx`（通用域对象） |
| Consumed by | `observex`（结算可观测）、财务/风控报表消费者 |
| Excludes | 交易所下单、行情接入、策略信号、仓位生成、存储与队列实现 |

## 3. 术语

| 术语 | 定义 |
| --- | --- |
| SettlementCycle | 一次结算批次，通常对应日内或日终对账窗口。 |
| LedgerSnapshot | 内部账本在某一时间点的快照，用于与交易所余额比较。 |
| ReconciliationDiff | 交易所余额与内部账本之间的差异项。 |
| FeeAllocation | 按 `fee_asset`、成交与账户维度拆分的手续费分配结果。 |

## 4. 功能需求

| ID | 需求 | WHEN | THEN |
| --- | --- | --- | --- |
| FR-001 | 资金对账 | 结算周期到达且成交/余额数据可用 | 必须比对交易所余额与内部账本，生成差异项与告警结果。 |
| FR-002 | 手续费核算 | 成交记录可用 | 必须累加手续费并按 `fee_asset`、账户与结算周期汇总。 |

## 5. 行为约束

| ID | 规则 |
| --- | --- |
| BR-001 | 输入校验 fail-closed，缺失或不一致数据不得静默修正。 |
| BR-002 | 结算输出不可变，下游只能读取已冻结结果。 |
| BR-003 | 不得使用 lookahead 数据修正历史结算差异。 |

## 6. 非功能需求

| ID | 类别 | 需求 |
| --- | --- | --- |
| NFR-001 | 可审计性 | 每笔结算结果必须可追溯到成交、余额与差异来源。 |
| NFR-002 | 一致性 | 同一结算周期的重复运行必须产出等价结果。 |
| NFR-003 | 可观测性 | 至少暴露结算批次、差异金额、手续费金额与告警数量。 |
| NFR-004 | 边界纯净 | 文档与后续 public API 不得泄露存储、队列或 vendor DTO 细节。 |

## 7. Acceptance Criteria Registry

| AC ID | FR/BR Ref | Criterion | Verification | Status |
| --- | --- | --- | --- | --- |
| AC-SETTLEMENT-001 | FR-001 | 对账逻辑可明确覆盖余额差异、差异告警与结算批次输出。 | 文档引用检查 | Baseline Published |
| AC-SETTLEMENT-002 | FR-002 | 手续费核算口径可按 `fee_asset` 与结算周期稳定复现。 | 文档引用检查 | Baseline Published |

## 8. 追溯与测试门禁

| 门禁 | 要求 | 当前状态 |
| --- | --- | --- |
| Traceability Gate | `module/settlement/TRACEABILITY.md` 已包含 FR/BR/AC/TC 映射，且 AC ID 与本 SPEC 对齐。 | Baseline Published |
| Test Gate | 后续实现必须覆盖对账差异、手续费汇总、fail-closed 与重复运行等价性。 | Pending |
| Boundary Gate | 本 SPEC 不定义运行时代码、wire schema、数据库表或队列 topic。 | Baseline Published |

## 9. 版本记录

| 日期 | 版本 | 变更 | 作者 |
| --- | --- | --- | --- |
| 2026-06-21 | v1.0.0 | 从占位符扩充为完整文档基线，补齐边界、FR、BR、NFR、AC 与测试门禁 | ZoneCNH |
