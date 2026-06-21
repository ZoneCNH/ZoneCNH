# signal_factory Goal

## 元数据

| 字段 | 值 |
| --- | --- |
| Target | v0.1.0-draft |
| Layer | 决策域 · 信号生成 |
| Status | Draft |
| Last-Updated | 2026-06-17 |
| Source | SPEC.md (待创建) |

## 定位

signal_factory 是决策域的信号生成模块。消费因子评估+DecisionCard，生成交易信号。

## 目标

- 定义模块核心接口与数据模型
- 明确上游依赖和下游消费者
- 建立可测试的验收标准基线

## 边界

| 类型 | 说明 |
| --- | --- |
| Owns | 信号生成接口/信号组合/权重管理/Signal DTO |
| Depends on | factor_eval, regime_engine, feature_store |
| Consumed by | backtestx, riskx, orderx |
| Excludes | 因子计算(→factor_engine)、订单执行(→orderx) |
