# ms_brain Goal

## 元数据

| 字段 | 值 |
| --- | --- |
| Target | v0.1.0-draft |
| Layer | 分析域 · M×S架构分析 |
| Status | Draft |
| Last-Updated | 2026-06-17 |
| Source | SPEC.md (待创建) |

## 定位

ms_brain 是分析域的M×S架构分析模块。M×S联合分析框架、可视化、决策推演。

## 目标

- 定义模块核心接口与数据模型
- 明确上游依赖和下游消费者
- 建立可测试的验收标准基线

## 边界

| 类型 | 说明 |
| --- | --- |
| Owns | M×S分析框架/架构可视化/决策推演 |
| Depends on | market_regime, macro_regime |
| Consumed by | regime_engine, 策略研发 |
| Excludes | 在线分类(→market_regime/macro_regime)、交易执行 |
