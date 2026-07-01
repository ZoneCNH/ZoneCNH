# market_regime 规格

- Status: Draft
- Spec-Version: v0.1.0
- Last-Updated: 2026-06-30
- Layer: 分析域 · 市场状态 (S引擎)
- Version: v0.1.0-draft
- Related: `CONSTITUTION.md`

> 本文档发布 market_regime 基线。运行时实现为 Pending。

## 1. 摘要

market_regime 是分析域的 S 引擎，分析市场微观结构特征，输出 S1-S7 市场状态。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | S1-S7 市场状态分类器、微观结构特征提取（波动率/流动性/相关性）、bias 计算、permission gate |
| Depends on | market_data（MarketEventEnvelope）、domain_market、flowx（数据管线） |
| Consumed by | regime_engine（S 分类输入）、factor_engine（状态感知因子） |

## 3. 功能需求

### FR-001: S 分类

WHEN WHEN 市场数据流可用
THEN 输出 S1-S7 状态分类 + confidence

### FR-002: 特征提取

WHEN WHEN 接收 OHLCV/OB 数据
THEN 计算波动率、spread、volume_profile、orderbook_imbalance

### FR-003: Bias/Permission

WHEN WHEN 状态确定
THEN 输出 bias(+1/0/-1) 和 permission(ALLOW/REDUCE/DENY)


## 4. 行为约束

| ID | 规则 |
| --- | --- |
| BR-001 | 输入校验 fail-closed |
| BR-002 | 输出不可变，下游只读 |
| BR-003 | No lookahead |

## 5. 术语

待补充。

## 6. 非功能需求

待补充。

## 7. Acceptance Criteria Registry

待补充。

## 8. 追溯与测试门禁

待补充。

## 9. 版本记录

待补充。

## 10. 错误处理

待补充。

## 11. 边界情况

待补充。

## 12. 目录结构

待补充。

## 13. 依赖

待补充。

## 14. 测试

待补充。

## 15. 性能预算

待补充。

## 16. 可观测性

待补充。

## 17. 安全

待补充。

## 18. CI 门禁

待补充。

## 19. 升级兼容性

待补充。

## 20. 发布 DoD

待补充。

## 21. 待解决问题

待补充。

## 22. 运行时边界

待补充。

## 23. 变更历史

| 日期 | 版本 | 变更 | 作者 |
| --- | --- | --- | --- |
| 2026-06-17 | v0.1.0-draft | 初始基线 | ZoneCNH |
