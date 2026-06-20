## 契约固化清单

按优先级固化到 `contracts` 仓库：

| 优先级   | 契约                           | 生产方        | 消费方                                       |
| -------- | ------------------------------ | ------------- | -------------------------------------------- |
| P0       | `RegimeSnapshot` DTO           | market_regime | regime-engine, signal-factory, risk-engine   |
| P0       | `RegimeCard` DTO               | macro_regime  | regime-engine                                |
| P0       | `DecisionCard` DTO             | regime-engine | signal-factory, risk-engine, backtest-engine |
| P1       | `RegimeSnapshotEvent` (Kafka)  | market_regime | regime-engine                                |
| P1       | `RegimeCardEvent` (Kafka)      | macro_regime  | regime-engine                                |
| P1       | `DecisionCardEvent` (Kafka)    | regime-engine | signal-factory, risk-engine                  |
| P2       | `MarketRegimePort` (interface) | contracts     | market_regime 实现                           |
| P2       | `MacroRegimePort` (interface)  | contracts     | macro_regime 实现                            |
| P2       | `RegimeEnginePort` (interface) | contracts     | regime-engine 实现                           |

---

## 实现路径

```text
Phase 1a: market_regime 实现
  依赖: domain-market ✅ + factor-engine (特征计算)
  退出: market-data → market_regime → RegimeSnapshot 可跑通

Phase 1b: macro_regime 实现 (与 1a 并行)
  依赖: domain-macro ✅ + macro-data ✅
  退出: macro-data → macro_regime → RegimeCard 可跑通

Phase 1c: contracts 固化 regime 端口
  依赖: 1a/1b 确定 DTO 结构
  退出: RegimeSnapshot / RegimeCard / DecisionCard 进入 contracts

Phase 2: regime_engine 实现
  依赖: 1a + 1b + 1c
  退出: M State + S State → DecisionCard 可跑通

Phase 3: 下游集成
  signal-factory 消费 DecisionCard
  risk-engine 消费 trade_permission + position_caps
  backtest-engine 回放 M×S 决策日志
```text

