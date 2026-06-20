# factor_eval Goal

## 元数据

| 字段 | 值 |
| --- | --- |
| Target | v0.1.0-draft |
| Layer | 分析域 · 因子评估 |
| Status | Draft |
| Last-Updated | 2026-06-17 |
| Source | SPEC.md (待创建) |

## 定位

factor_eval 是分析域的因子评估模块。IC/RankIC分析、分层回测、换手率、因子衰减评估。

## 目标

- 定义模块核心接口与数据模型
- 明确上游依赖和下游消费者
- 建立可测试的验收标准基线

## 边界

| 类型 | 说明 |
| --- | --- |
| Owns | IC计算/分层回测/换手率/衰减分析/评估报告 |
| Depends on | factor_engine, feature_store, domain_market |
| Consumed by | signal_factory, backtestx |
| Excludes | 因子计算(→factor_engine)、策略回测(→backtestx) |
