# risk_engine 规格

- Status: Draft
- Spec-Version: v0.1.0-draft
- Last-Updated: 2026-06-17
- Layer: 执行域 · 风险管理
- Version: v0.1.0-draft
- Related: `CONSTITUTION.md`

> 本文档发布 risk_engine 基线。运行时实现为 Pending。

## 1. 摘要

risk_engine 是执行域的风控引擎。所有策略订单必须通过 risk_engine 风控检查后才能提交到 order_engine。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | 事前风控规则、回撤控制、熔断机制、风险限额、仓位约束 |
| Depends on | signal_factory（信号）、portfolio_engine（组合敞口）、domainx |
| Consumed by | order_engine（风控通过后提交订单） |

## 3. 功能需求

### FR-001: 订单风控

WHEN WHEN 信号生成订单意向
THEN 检查仓位上限、单笔限额、回撤熔断

### FR-002: 回撤熔断

WHEN WHEN 日回撤 > 阈值
THEN 熔断所有策略，禁止新订单

### FR-003: 风险报告

WHEN WHEN 风控决策完成
THEN 输出 RiskReport{Exposure, Drawdown, VaR, Limits}


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
