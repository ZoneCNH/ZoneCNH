# TASK-CONTRACTS-005

> 摄入契约与拒绝码集

```yaml
task_id: TASK-CONTRACTS-005
module: contracts
scope: "对齐 MarketDataService.Ingest 单次请求/单次结果契约、请求/结果结构体与 canonical reject code"
spec_ref:
  - "module/contracts/SPEC.md#FR-006"
  - "module/contracts/SPEC.md#BR-006"
  - "module/contracts/SPEC.md#BR-007"
  - "module/contracts/SPEC.md#BR-010"
  - "module/contracts/SPEC.md#NFR-001"
  - "module/contracts/SPEC.md#NFR-006"
files:
  - "ingestion.go"
  - "ingestion_test.go"
acceptance_criteria:
  - "MarketDataService.Ingest(in IngestRequest) (IngestResult, error) 是单次请求/单次结果契约，不是双向流。"
  - "IngestRequest 仅包含 RequestID、Source、ProductLine、InstrumentKey、EventType、EventTime、ReceivedAt、SchemaVersion、Payload、Sequence、OrderingKey、SourceMetadata 这 12 个字段。"
  - "IngestResult 仅保留 Ack 或 Reject 分支。"
  - "IngestAck 与 IngestReject 的字段与 runtime 一致。"
  - "AllRejectCodes() 返回 10 个 canonical code；RejectUnsupportedChannel 仍导出且属于 canonical 集合。"
  - "文档和测试不再使用旧的双向流叙事。"
depends_on:
  - "TASK-CONTRACTS-000"
  - "TASK-CONTRACTS-002"
estimated_effort: "1.5h"
priority: P0
status: pending
non_scope:
  - "不恢复双向流实现。"
  - "不恢复 RejectUnsupportedChannel 非 canonical 的旧叙事。"
  - "不引入新的传输实现。"
```
