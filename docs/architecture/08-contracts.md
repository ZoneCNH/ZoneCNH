## 契约固化清单

按优先级固化到 `contracts` 仓库：

| 优先级   | 契约                           | 生产方        | 消费方                                       |
| -------- | ------------------------------ | ------------- | -------------------------------------------- |
| P0       | `RegimeSnapshot` DTO           | market_regime | regime_engine, signal_factory, risk_engine   |
| P0       | `RegimeCard` DTO               | macro_regime  | regime_engine                                |
| P0       | `DecisionCard` DTO             | regime_engine | signal_factory, risk_engine, backtest_engine |
| P1       | `RegimeSnapshotEvent` (Kafka)  | market_regime | regime_engine                                |
| P1       | `RegimeCardEvent` (Kafka)      | macro_regime  | regime_engine                                |
| P1       | `DecisionCardEvent` (Kafka)    | regime_engine | signal_factory, risk_engine                  |
| P2       | `MarketRegimePort` (interface) | contracts     | market_regime 实现                           |
| P2       | `MacroRegimePort` (interface)  | contracts     | macro_regime 实现                            |
| P2       | `RegimeEnginePort` (interface) | contracts     | regime_engine 实现                           |

---

## 实现路径

```text
Phase 1a: market_regime 实现
  依赖: domain_market ✅ + factor_engine (特征计算)
  退出: market_data → market_regime → RegimeSnapshot 可跑通

Phase 1b: macro_regime 实现 (与 1a 并行)
  依赖: domain_macro ✅ + macro_data ✅
  退出: macro_data → macro_regime → RegimeCard 可跑通

Phase 1c: contracts 固化 regime 端口
  依赖: 1a/1b 确定 DTO 结构
  退出: RegimeSnapshot / RegimeCard / DecisionCard 进入 contracts

Phase 2: regime_engine 实现
  依赖: 1a + 1b + 1c
  退出: M State + S State → DecisionCard 可跑通

Phase 3: 下游集成
  signal_factory 消费 DecisionCard
  risk_engine 消费 trade_permission + position_caps
  backtest_engine 回放 M×S 决策日志
```text

