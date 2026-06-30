# TASK-DEX-001 开发 Prompt

- 上游 Task：[tasks/](../tasks/)
- 追溯矩阵：[TRACEABILITY.md](../TRACEABILITY.md)
- 权威 Spec：[SPEC.md](../SPEC.md)

## 任务

实现 domain_exchange 交易所领域建模：Venue/ProductType/MarketStatus/TimeInForce 等枚举与值对象。

## 关联需求

FR-001~007（Venue/ProductType/TradingPair/MarketStatus/TimeInForce/Fee 模型）。

## 实现要点

1. 交易所无关的中立枚举
2. 值对象不可变性
3. 与 domain_market InstrumentKey 互操作
4. 不含 vendor-specific 字段
