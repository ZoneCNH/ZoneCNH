# backtest-engine Goal

## 元数据

| 字段 | 值 |
| --- | --- |
| Target | v0.1.0-draft |
| Layer | 决策域 · 回测引擎 |
| Status | Draft |
| Last-Updated | 2026-06-17 |
| Source | SPEC.md (待创建) |

## 定位

backtest-engine 是决策域的回测引擎模块。事件驱动回测、滑点/手续费模型、绩效报告。

## 目标

- 定义模块核心接口与数据模型
- 明确上游依赖和下游消费者
- 建立可测试的验收标准基线

## 边界

| 类型 | 说明 |
| --- | --- |
| Owns | 回测循环/滑点模型/绩效指标(Sharpe/MaxDD)/报告 |
| Depends on | signal-factory, feature-store, domain-market |
| Consumed by | optimizer, 策略研发 |
| Excludes | 参数优化(→optimizer)、实时交易、信号生成 |
