# regime-engine Goal

## 元数据

| 字段 | 值 |
| --- | --- |
| Target | v0.1.0-draft |
| Layer | 分析域 · M×S联合决策 |
| Status | Draft |
| Last-Updated | 2026-06-17 |
| Source | SPEC.md (待创建) |

## 定位

regime-engine 是分析域的M×S联合决策模块。融合M+S输出，生成DecisionCard(action/risk/permission)。

## 目标

- 定义模块核心接口与数据模型
- 明确上游依赖和下游消费者
- 建立可测试的验收标准基线

## 边界

| 类型 | 说明 |
| --- | --- |
| Owns | M×S融合逻辑/DecisionCard/三元输出 |
| Depends on | market_regime, macro_regime, domain-market |
| Consumed by | signal-factory, riskx |
| Excludes | 单引擎分类、交易执行、订单路由 |
