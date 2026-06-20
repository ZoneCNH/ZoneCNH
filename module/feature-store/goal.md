# feature_store Goal

## 元数据

| 字段 | 值 |
| --- | --- |
| Target | v0.1.0-draft |
| Layer | 分析域 · 特征存储 |
| Status | Draft |
| Last-Updated | 2026-06-17 |
| Source | SPEC.md (待创建) |

## 定位

feature_store 是分析域的特征存储模块。接收 FactorOutput，特征版本化存储、回测时点查询、特征血缘追踪。

## 目标

- 定义模块核心接口与数据模型
- 明确上游依赖和下游消费者
- 建立可测试的验收标准基线

## 边界

| 类型 | 说明 |
| --- | --- |
| Owns | Feature存储接口/特征版本管理/血缘追踪/point-in-time查询 |
| Depends on | factor_engine, domain_market, decimalx |
| Consumed by | factor_eval, signal_factory, backtestx |
| Excludes | 因子计算(→factor_engine)、数据库实现(→postgresx/taosx) |
