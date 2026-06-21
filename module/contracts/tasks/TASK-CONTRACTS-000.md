# TASK-CONTRACTS-000

> 包边界、文档索引与依赖基线

```yaml
task_id: TASK-CONTRACTS-000
module: contracts
scope: "固定 contracts 包边界、README/goal/CHANGELOG 现状与零运行时依赖约束"
spec_ref:
  - "module/contracts/SPEC.md#FR-008"
  - "module/contracts/SPEC.md#BR-001"
  - "module/contracts/SPEC.md#BR-004"
  - "module/contracts/SPEC.md#BR-009"
  - "module/contracts/SPEC.md#NFR-004"
  - "module/contracts/SPEC.md#NFR-007"
files:
  - "README.md"
  - "goal.md"
  - "CHANGELOG.md"
acceptance_criteria:
  - "README 与 goal 只描述 contracts 共享契约边界，不回流业务实现叙事。"
  - "CHANGELOG 只记录文档真相同步，不改写发布历史。"
  - "README、goal、CHANGELOG 与 SPEC/TRACEABILITY/ACCEPTANCE 保持同一事实源。"
  - "stale-term 扫描不再命中稳定期、旧 API 名称和旧叙事。"
  - "文档不把 HTTP/gRPC/Kafka/NATS 写成契约本体。"
depends_on: []
estimated_effort: "0.5h"
priority: P0
status: pending
non_scope:
  - "不修改 /home/contracts/pkg/contracts 源码。"
  - "不引入新依赖或工具。"
  - "不恢复旧命名或历史叙事。"
```
