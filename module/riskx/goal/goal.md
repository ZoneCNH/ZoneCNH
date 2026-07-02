# riskx Goal

## 元数据

| 字段 | 值 |
| --- | --- |
| Target | v1.0.0 |
| Layer | 决策域 · 风控引擎 |
| Status | Review |
| Last-Updated | 2026-06-16 |
| Source | [SPEC.md](./SPEC.md) |

## 目标

- 统一风控门禁：所有订单必须通过 riskx 检查
- 事前风控：下单前检查仓位限额、单笔限额、频率限制
- 实时风控：监控回撤、波动率、集中度
- 熔断机制：触发条件时暂停交易
- 风险报告：定时输出风险指标（VaR, Sharpe, maxDrawdown）
---

## 成功标准

参见 [TRACEABILITY.md](./TRACEABILITY.md) §1 FR 追溯表。

## 范围内

参见 [SPEC.md](./SPEC.md) §5 Non-goals（取反即为范围内）。

## 范围外

参见 [SPEC.md](./SPEC.md) §4 非目标。
