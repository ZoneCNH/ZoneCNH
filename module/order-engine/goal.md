# order_engine Goal

## 元数据

| 字段 | 值 |
| --- | --- |
| Target | v0.1.0-draft |
| Layer | 执行域 · 订单执行 |
| Status | Draft |
| Last-Updated | 2026-06-17 |
| Source | SPEC.md (待创建) |

## 定位

order_engine 是执行域的订单执行模块。抽象交易所差异，订单生命周期管理、SOR智能路由。

## 目标

- 定义模块核心接口与数据模型
- 明确上游依赖和下游消费者
- 建立可测试的验收标准基线

## 边界

| 类型 | 说明 |
| --- | --- |
| Owns | 订单生命周期/订单路由SOR/执行算法/Exchange适配 |
| Depends on | risk_engine, domain_exchange, contracts |
| Consumed by | portfolio_engine, settlement |
| Excludes | 风控规则(→risk_engine)、交易所适配器实现 |
