# backtestx Goal

## 元数据

| 字段 | 值 |
| --- | --- |
| Target | v1.0.0 |
| Layer | 分析域 · 回测引擎 |
| Status | Review |
| Last-Updated | 2026-06-16 |
| Source | [SPEC.md](./SPEC.md) |

## 目标

- 事件驱动回测：按历史行情时间序列逐 tick/bar 驱动
- 与实盘共享代码：回测和实盘使用相同的因子、信号、风控模块
- 完整绩效指标：Sharpe、Sortino、Max Drawdown、Calmar、Win Rate、Profit Factor
- Walk-Forward 优化：滚动训练/测试窗口，防过拟合
- 蒙特卡洛模拟：随机打乱交易序列评估策略稳健性
- 压力测试：模拟极端行情场景（闪崩、流动性枯竭）
---

## 成功标准

参见 [TRACEABILITY.md](./TRACEABILITY.md) §1 FR 追溯表。

## 范围内

参见 [SPEC.md](./SPEC.md) §5 Non-goals（取反即为范围内）。

## 范围外

参见 [SPEC.md](./SPEC.md) §4 非目标。
