# order-engine 规格

- Status: Draft
- Spec-Version: v0.1.0-draft
- Last-Updated: 2026-06-17
- Layer: 执行域 · 订单执行
- Module-Version: v0.1.0-draft
- Related: `CONSTITUTION.md`

> 本文档发布 order-engine 基线。运行时实现为 Pending。

## 1. 摘要

order-engine 抽象交易所差异，管理订单从创建到成交/撤销的完整生命周期。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | 订单生命周期、SOR 智能路由、执行算法（TWAP/VWAP）、Exchange 抽象适配 |
| Depends on | risk-engine（风控通过）、domain-exchange（VenueAdapter）、contracts |
| Consumed by | portfolio-engine（成交更新）、settlement（结算） |

## 3. 功能需求

### FR-001: 订单生命周期

WHEN WHEN 创建订单
THEN 状态: NEW→PENDING→PARTIAL→FILLED/CANCELLED/REJECTED

### FR-002: SOR 路由

WHEN WHEN 多交易所可用
THEN 按流动性/手续费/延迟选择最优路由

### FR-003: Order DTO

WHEN WHEN 提交订单
THEN Order{Symbol,Side,Qty,Price,Type,TIF,Exchange}


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
