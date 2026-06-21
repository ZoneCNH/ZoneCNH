# TASK-CONTRACTS-002

> 基础封装与核心 DTO

```yaml
task_id: TASK-CONTRACTS-002
module: contracts
scope: "对齐 Event、Command、Query、DTO、Port、ErrorCode 与 P0 载体字段"
spec_ref:
  - "module/contracts/SPEC.md#FR-001"
  - "module/contracts/SPEC.md#FR-002"
  - "module/contracts/SPEC.md#FR-003"
  - "module/contracts/SPEC.md#BR-001"
  - "module/contracts/SPEC.md#BR-005"
  - "module/contracts/SPEC.md#NFR-002"
  - "module/contracts/SPEC.md#NFR-005"
files:
  - "contracts.go"
  - "regime_snapshot.go"
  - "regime_card.go"
  - "decision_card.go"
  - "p0_dto_test.go"
acceptance_criteria:
  - "Event、Command、Query 的字段集与 runtime 一致。"
  - "DTO 和 Port 只承担标记语义。"
  - "ErrorCode 仅暴露 Code、Domain、Severity、Retryable。"
  - "RegimeSnapshot、RegimeCard、DecisionCard 的导出字段与 JSON tag 与 runtime 一致。"
  - "不引入旧事件命名族。"
depends_on:
  - "TASK-CONTRACTS-000"
estimated_effort: "1.5h"
priority: P0
status: pending
non_scope:
  - "不增加端口方法。"
  - "不增加 ingestion。"
  - "不增加兼容别名。"
```
