# TASK-CONTRACTS-003

> 兼容别名与迁移投影

```yaml
task_id: TASK-CONTRACTS-003
module: contracts
scope: "维护兼容别名投影，保留旧入口的阶段性迁移"
spec_ref:
  - "module/contracts/SPEC.md#FR-007"
  - "module/contracts/SPEC.md#BR-008"
  - "module/contracts/SPEC.md#BR-010"
  - "module/contracts/SPEC.md#NFR-004"
  - "module/contracts/SPEC.md#NFR-008"
files:
  - "projections.go"
  - "projections_test.go"
acceptance_criteria:
  - "RegimeSnapshotEvent、RegimeCardEvent、DecisionCardEvent、MarketRegimePort、MacroRegimePort、RegimeEnginePort 的别名映射与 runtime 一致。"
  - "别名层只负责过渡，不创建新的语义层或命名族。"
  - "文档和测试不把别名重解释为独立契约。"
  - "任务文档不再描述旧的接口差异检测工具。"
depends_on:
  - "TASK-CONTRACTS-001"
  - "TASK-CONTRACTS-002"
estimated_effort: "1h"
priority: P1
status: pending
non_scope:
  - "不引入新的 semver 引擎。"
  - "不增加新的 DTO。"
  - "不恢复旧变更叙事。"
```
