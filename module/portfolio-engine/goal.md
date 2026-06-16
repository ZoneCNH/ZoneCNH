# portfolio-engine Goal

## 元数据

| 字段 | 值 |
| --- | --- |
| Target | v0.1.0-draft |
| Layer | 执行域 · 投资组合 |
| Status | Draft |
| Last-Updated | 2026-06-17 |
| Source | SPEC.md (待创建) |

## 定位

portfolio-engine 是执行域的投资组合模块。组合管理、PnL计算、风险敞口监控。

## 目标

- 定义模块核心接口与数据模型
- 明确上游依赖和下游消费者
- 建立可测试的验收标准基线

## 边界

| 类型 | 说明 |
| --- | --- |
| Owns | 组合管理/PnL实时计算/风险敞口/再平衡 |
| Depends on | order-engine, settlement, domainx |
| Consumed by | risk-engine |
| Excludes | 订单执行(→order-engine)、风控规则(→risk-engine) |
