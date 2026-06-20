# settlement 规格

- Status: Draft
- Spec-Version: v0.1.0-draft
- Last-Updated: 2026-06-17
- Layer: 执行域 · 结算对账
- Version: v0.1.0-draft
- Related: `CONSTITUTION.md`

> 本文档发布 settlement 基线。运行时实现为 Pending。

## 1. 摘要

settlement 负责交易后的资金对账和结算确认，确保交易所余额与内部账本一致。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | 结算流程、资金对账、手续费核算、结算报告 |
| Depends on | order_engine（成交记录）、portfolio_engine（持仓）、domainx |
| Consumed by | observex（结算可观测） |

## 3. 功能需求

### FR-001: 资金对账

WHEN WHEN 结算周期到达
THEN 比对交易所余额 vs 内部账本，差异超过阈值时告警

### FR-002: 手续费核算

WHEN WHEN 成交记录可用
THEN 累加手续费并按 fee_asset 分类汇总


## 4. 行为约束

| ID | 规则 |
| --- | --- |
| BR-001 | 输入校验 fail-closed |
| BR-002 | 输出不可变，下游只读 |
| BR-003 | No lookahead |

## 版本记录

| 日期 | 版本 | 变更 | 作者 |
| --- | --- | --- | --- |
| 2026-06-17 | v0.1.0-draft | 初始基线 | ZoneCNH |
