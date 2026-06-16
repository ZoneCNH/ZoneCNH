# factor-engine Goal

## 元数据

| 字段 | 值 |
| --- | --- |
| Target | v0.1.0-draft |
| Layer | 分析域 · 因子计算 |
| Status | Draft |
| Last-Updated | 2026-06-17 |
| Source | SPEC.md (待创建) |

## 定位

factor-engine 是分析域的因子计算模块。消费 market-data MarketEventEnvelope，执行因子计算，输出到 feature-store。

## 目标

- 定义模块核心接口与数据模型
- 明确上游依赖和下游消费者
- 建立可测试的验收标准基线

## 边界

| 类型 | 说明 |
| --- | --- |
| Owns | Factor接口/FactorRegistry/FactorOutput |
| Depends on | market-data, domain-market, feature-store |
| Consumed by | factor-eval, signal-factory |
| Excludes | 特征存储(→feature-store)、因子评估(→factor-eval)、数据采集 |
