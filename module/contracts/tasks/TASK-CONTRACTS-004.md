# TASK-CONTRACTS-004

> 追溯闭合与文档基线一致性

```yaml
task_id: TASK-CONTRACTS-004
module: contracts
scope: "同步 SPEC、TRACEABILITY、ACCEPTANCE、FEATURES 与 IMPLEMENTATION-PLAN 的事实口径"
spec_ref:
  - "module/contracts/SPEC.md#FR-008"
  - "module/contracts/SPEC.md#BR-002"
  - "module/contracts/SPEC.md#BR-003"
  - "module/contracts/SPEC.md#BR-009"
  - "module/contracts/SPEC.md#NFR-004"
  - "module/contracts/SPEC.md#NFR-008"
files:
  - "SPEC.md"
  - "TRACEABILITY.md"
  - "ACCEPTANCE.md"
  - "FEATURES.md"
  - "IMPLEMENTATION-PLAN.md"
acceptance_criteria:
  - "这些文档与 README、goal、CHANGELOG 共享同一事实源。"
  - "TRACEABILITY 覆盖 FR-001..FR-008，并指向当前 TASK-CONTRACTS-000..TASK-CONTRACTS-005。"
  - "依赖图只使用 TASK-CONTRACTS-000..TASK-CONTRACTS-005。"
  - "文档不残留旧术语、旧 API 名称或旧任务编号。"
  - "文档不把传输实现写成主线事实。"
depends_on:
  - "TASK-CONTRACTS-000"
  - "TASK-CONTRACTS-001"
  - "TASK-CONTRACTS-002"
  - "TASK-CONTRACTS-003"
estimated_effort: "1h"
priority: P1
status: pending
non_scope:
  - "不修改 /home/contracts/pkg/contracts 源码。"
  - "不添加新的规格章节或任务编号。"
  - "不恢复旧术语。"
```
