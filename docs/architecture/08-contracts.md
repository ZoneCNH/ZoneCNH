## 契约固化清单

按优先级固化到 `contracts` 仓库：

| 优先级 | 契约 | 生产方 | 消费方 | 状态 |
| --- | --- | --- | --- | --- |
| P0 | `RegimeSnapshot` DTO | market_regime | regime_engine, signal_factory, risk_engine | ✅ **2026-06-20** |
| P0 | `RegimeCard` DTO | macro_regime | regime_engine | ✅ **2026-06-20** |
| P0 | `DecisionCard` DTO | regime_engine | signal_factory, risk_engine, backtest_engine | ✅ **2026-06-20** |
| P0 | `MarketDataProvider` port | market_data | market_regime | ✅ **2026-06-20** |
| P0 | `MacroDataProvider` port | macro_data | macro_regime | ✅ **2026-06-20** |
| P0 | `DecisionCardProvider` port | regime_engine | signal_factory, risk_engine | ✅ **2026-06-20** |
| P1 | `SignalIntent` DTO | regime_engine | signal_factory, risk_engine | ✅ **2026-06-21**（PR #12） |
| P1 | `RegimeSnapshotEvent` (Kafka) | market_regime | regime_engine | ✅ **2026-06-21**（type alias 投影已补齐） |
| P1 | `RegimeCardEvent` (Kafka) | macro_regime | regime_engine | ✅ **2026-06-21**（type alias 投影已补齐） |
| P1 | `DecisionCardEvent` (Kafka) | regime_engine | signal_factory, risk_engine | ✅ **2026-06-21**（type alias 投影已补齐） |
| P2 | `MarketRegimePort` (interface) | contracts | market_regime 实现 | ✅ **2026-06-21**（type alias 投影已补齐） |
| P2 | `MacroRegimePort` (interface) | contracts | macro_regime 实现 | ✅ **2026-06-21**（type alias 投影已补齐） |
| P2 | `RegimeEnginePort` (interface) | contracts | regime_engine 实现 | ✅ **2026-06-21**（type alias 投影已补齐） |

> 注：P1/P2 行仅表示 contracts 中的兼容投影别名已落地；消息发布/消费、序列化和运行时验证仍按后续 AC/TC 推进。

### P0 固化内容（contracts PR #10，2026-06-20）

```
pkg/contracts/regime_snapshot.go  — RegimeSnapshot · MarketState(S1-S7) · FiveDimScores · TradePermission
pkg/contracts/regime_card.go      — RegimeCard · MacroState(M1-M7) · LGIPScore
pkg/contracts/decision_card.go    — DecisionCard · Action(A-E) · PositionCaps · StrategyTemplate
pkg/contracts/ports.go            — MarketDataProvider · MacroDataProvider · DecisionCardProvider
```

---

## 实现路径

```text
Phase 1a: market_regime 实现  ← 前置契约已就绪 ✅
  依赖: domain_market ✅ + contracts P0 DTO ✅
  退出: market_data → market_regime → RegimeSnapshot 可跑通

Phase 1b: macro_regime 实现（与 1a 并行）← 前置契约已就绪 ✅
  依赖: domain_macro ✅ + macro_data ✅ + contracts P0 DTO ✅
  退出: macro_data → macro_regime → RegimeCard 可跑通

Phase 1c: SignalIntent DTO 已升入 contracts ✅
  依赖: regime_engine / signal_factory ✅
  退出: DecisionCard → SignalIntent 下游口径统一

Phase 2: regime_engine 实现
  依赖: 1a ✅ + 1b ✅ + P0 DTO ✅
  退出: M State + S State → DecisionCard 可跑通

Phase 3: 下游集成
  signal_factory 消费 DecisionCard
  risk_engine 消费 trade_permission + position_caps
  backtest_engine 回放 M×S 决策日志
```
