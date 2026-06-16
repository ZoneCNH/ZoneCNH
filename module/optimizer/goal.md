# optimizer Goal

## 元数据

| 字段 | 值 |
| --- | --- |
| Target | v0.1.0-draft |
| Layer | 决策域 · 参数优化 |
| Status | Draft |
| Last-Updated | 2026-06-17 |
| Source | SPEC.md (待创建) |

## 定位

optimizer 是决策域的参数优化模块。Walk-Forward优化、网格搜索、贝叶斯优化、过拟合检测。

## 目标

- 定义模块核心接口与数据模型
- 明确上游依赖和下游消费者
- 建立可测试的验收标准基线

## 边界

| 类型 | 说明 |
| --- | --- |
| Owns | Walk-Forward/网格搜索/贝叶斯优化/过拟合检测 |
| Depends on | backtest-engine, signal-factory |
| Consumed by | strategyx, 策略研发 |
| Excludes | 回测执行(→backtest-engine)、策略定义(→strategyx) |
