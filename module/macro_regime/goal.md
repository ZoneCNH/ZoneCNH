# macro_regime Goal

## 元数据

| 字段 | 值 |
| --- | --- |
| Target | v0.1.0-draft |
| Layer | 分析域 · 宏观体制(M引擎) |
| Status | Draft |
| Last-Updated | 2026-06-17 |
| Source | SPEC.md (待创建) |

## 定位

macro_regime 是分析域的宏观体制(M引擎)模块。M1-M7宏观体制分类、regime transition检测。

## 目标

- 定义模块核心接口与数据模型
- 明确上游依赖和下游消费者
- 建立可测试的验收标准基线

## 边界

| 类型 | 说明 |
| --- | --- |
| Owns | M1-M7分类器/宏观指标管线/transition检测 |
| Depends on | macro-data, domain-macro, flowx |
| Consumed by | regime-engine |
| Excludes | 市场状态(→market_regime)、联合决策(→regime-engine) |
