# portfolio-engine 规格

- Status: Draft
- Spec-Version: v0.1.0-draft
- Last-Updated: 2026-06-17
- Layer: 执行域 · 投资组合
- Module-Version: v0.1.0-draft
- Related: `CONSTITUTION.md`

> 本文档发布 portfolio-engine 基线。运行时实现为 Pending。

## 1. 摘要

portfolio-engine 实时追踪所有持仓和 PnL，提供组合层面的风险敞口视图。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | 组合管理、PnL 实时计算、风险敞口监控、再平衡建议 |
| Depends on | order-engine（成交）、settlement（结算）、domainx |
| Consumed by | risk-engine（敞口数据）、observex（PnL 可观测） |

## 3. 功能需求

### FR-001: PnL 计算

WHEN WHEN 成交发生
THEN 实时更新 position PnL = (mark_price - avg_entry) * qty

### FR-002: 敞口监控

WHEN WHEN 敞口变化
THEN 按 instrument/venue/product_line 维度汇总净敞口


## 4. 行为约束

| ID | 规则 |
| --- | --- |
| BR-001 | 输入校验 fail-closed |
| BR-002 | 输出不可变，下游只读 |
| BR-003 | No lookahead |

## 变更历史

| 日期 | 版本 | 变更 | 作者 |
| --- | --- | --- | --- |
| 2026-06-17 | v0.1.0-draft | 初始基线 | ZoneCNH |
