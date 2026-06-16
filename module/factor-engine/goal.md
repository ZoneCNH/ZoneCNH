# factor-engine Goal

## 元数据

| 字段 | 值 |
| --- | --- |
| Target | v0.1.0-draft |
| Layer | 分析域 · 因子计算引擎 |
| Status | Draft |
| Last-Updated | 2026-06-17 |
| Source | [SPEC.md](./SPEC.md) |

## 定位

`factor-engine` 是分析域的因子计算引擎，消费 market-data 输出的 canonical MarketEventEnvelope，执行因子计算并将结果写入 feature-store。它是连接数据域与分析域的核心计算层。

## 目标

- 消费 market-data DownstreamDispatchPort 输出的 MarketEventEnvelope
- 定义因子注册与发现机制（FactorRegistry）
- 实现标准因子接口（Factor interface）
- 支持 Tick/Bar/OrderBook 三种输入类型的因子计算
- 输出 FactorOutput 到 feature-store
- 提供因子计算可观测性（latency、throughput、error rate）

## 边界

| 类型 | 说明 |
| --- | --- |
| Owns | Factor 接口定义、FactorRegistry、因子计算编排、FactorOutput DTO |
| Depends on | market-data（MarketEventEnvelope 输入）、domain-market（canonical 类型）、feature-store（输出写入） |
| Consumed by | factor-eval（因子评估）、signal-factory（信号生成） |
| Excludes | 特征存储实现（→ feature-store）、因子评估逻辑（→ factor-eval）、回测引擎（→ backtestx）、数据采集 |

## 不做什么

- 不实现特征存储（由 feature-store 负责）
- 不做因子评估/回测（由 factor-eval / backtestx 负责）
- 不直接连接交易所或数据源
- 不实现信号生成或策略逻辑

