# TASK-CONTRACTS-001

> 端口与信号工厂契约

```yaml
task_id: TASK-CONTRACTS-001
module: contracts
scope: "对齐 MarketDataProvider、MacroDataProvider、DecisionCardProvider 与 SignalFactoryProvider.Generate"
spec_ref:
  - "module/contracts/SPEC.md#FR-004"
  - "module/contracts/SPEC.md#FR-005"
  - "module/contracts/SPEC.md#BR-003"
  - "module/contracts/SPEC.md#BR-008"
  - "module/contracts/SPEC.md#NFR-005"
files:
  - "ports.go"
  - "signal_intent.go"
  - "signal_intent_test.go"
acceptance_criteria:
  - "MarketDataProvider 仅暴露 LatestRegimeSnapshot 和 SubscribeRegimeSnapshots。"
  - "MacroDataProvider 仅暴露 LatestRegimeCard 和 SubscribeRegimeCards。"
  - "DecisionCardProvider 仅暴露 LatestDecisionCard 和 SubscribeDecisionCards。"
  - "SignalFactoryProvider.Generate(card DecisionCard, symbols []string) ([]SignalIntent, error) 与 runtime 一致。"
  - "签名不出现旧版快照查询名、旧版历史查询名、旧版最新值查询名或旧订阅入口。"
depends_on:
  - "TASK-CONTRACTS-000"
estimated_effort: "1h"
priority: P0
status: pending
non_scope:
  - "不实现 DTO、Port 以外的新抽象。"
  - "不加入 ingestion 或兼容别名。"
  - "不保留旧 API 入口。"
```
