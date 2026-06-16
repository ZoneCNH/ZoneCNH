# market_regime Goal

## 元数据

| 字段 | 值 |
| --- | --- |
| Target | v0.1.0-draft |
| Layer | 分析域 · 市场状态(S引擎) |
| Status | Draft |
| Last-Updated | 2026-06-17 |
| Source | SPEC.md (待创建) |

## 定位

market_regime 是分析域的市场状态(S引擎)模块。S1-S7市场状态分类、bias/permission gate。

## 目标

- 定义模块核心接口与数据模型
- 明确上游依赖和下游消费者
- 建立可测试的验收标准基线

## 边界

| 类型 | 说明 |
| --- | --- |
| Owns | S1-S7分类器/微观结构特征/bias/permission |
| Depends on | market-data, domain-market, flowx |
| Consumed by | regime-engine, factor-engine |
| Excludes | 宏观体制(→macro_regime)、联合决策(→regime-engine) |
