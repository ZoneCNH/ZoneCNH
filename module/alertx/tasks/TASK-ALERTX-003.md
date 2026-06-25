# TASK-ALERTX-003

> 去重抑制：指纹 + 时间窗口

---

```yaml
task_id: TASK-ALERTX-003
module: alertx
scope: "实现 Deduper 接口（DedupKey 指纹 + SuppressWindow 时间窗口去重）+ 空 DedupKey 派生逻辑"
spec_ref:
  - "module/alertx/SPEC.md#FR-002"
  - "module/alertx/SPEC.md#BR-003"
files:
  - "pkg/alertx/dedup.go"
  - "pkg/alertx/dedup_test.go"
acceptance_criteria:
  - "AC-002: 同 DedupKey 在 SuppressWindow 内的重复告警被抑制（Status=suppressed）；空 DedupKey 由 alertx 按 (Source, subject) 派生"
  - "AC-010: 零 SuppressWindow 用全局默认值"
  - "TestDeduper_SuppressWindow 通过：窗口内重复→suppressed，窗口外→firing"
  - "TestDeduper_ConcurrentSameKey 通过（-race，多 goroutine 仅一个 firing）"
  - "TestDeduper_MissingTraceID 通过（trace_id 缺失时 DedupKey 正常派生）"
depends_on:
  - "TASK-ALERTX-002"
estimated_effort: "2h"
priority: P0
status: pending
```

## Non-scope

- 不实现规则评估（TASK-002）/分级（TASK-004）
- 不实现持久化存储（仅内存 DedupKey 索引）
