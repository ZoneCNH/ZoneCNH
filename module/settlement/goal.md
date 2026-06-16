# settlement Goal

## 元数据

| 字段 | 值 |
| --- | --- |
| Target | v0.1.0-draft |
| Layer | 执行域 · 结算对账 |
| Status | Draft |
| Last-Updated | 2026-06-17 |
| Source | SPEC.md (待创建) |

## 定位

settlement 是执行域的结算对账模块。交易结算、资金对账、手续费核算。

## 目标

- 定义模块核心接口与数据模型
- 明确上游依赖和下游消费者
- 建立可测试的验收标准基线

## 边界

| 类型 | 说明 |
| --- | --- |
| Owns | 结算流程/资金对账/手续费核算/结算报告 |
| Depends on | order-engine, portfolio-engine, domainx |
| Consumed by | observex |
| Excludes | 订单执行(→order-engine)、风控(→risk-engine) |
