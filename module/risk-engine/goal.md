# risk-engine Goal

## 元数据

| 字段 | 值 |
| --- | --- |
| Target | v0.1.0-draft |
| Layer | 执行域 · 风险管理 |
| Status | Draft |
| Last-Updated | 2026-06-17 |
| Source | SPEC.md (待创建) |

## 定位

risk-engine 是执行域的风险管理模块。策略只通过risk-engine提交订单，执行事前风控、回撤控制、熔断机制。

## 目标

- 定义模块核心接口与数据模型
- 明确上游依赖和下游消费者
- 建立可测试的验收标准基线

## 边界

| 类型 | 说明 |
| --- | --- |
| Owns | 事前风控规则/回撤控制/熔断机制/风险限额 |
| Depends on | signal-factory, portfolio-engine, domainx |
| Consumed by | order-engine |
| Excludes | 订单执行(→order-engine)、策略逻辑、仓位管理(→portfolio-engine) |
