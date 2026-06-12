# TASK-REDISX-005

> Pub/Sub subscription lifecycle

---

```yaml
task_id: TASK-REDISX-005
module: redisx
scope: "Implement Subscribe, message mapping, cancellation handling, and reconnect error surfacing."
spec_ref:
  - "module/redisx/SPEC.md#FR-008"
files:
  - "pubsub.go"
  - "message.go"
  - "pubsub_test.go"
  - "testutil_test.go"
acceptance_criteria:
  - "AC-005-1: Subscribe returns a receive-only message channel for requested channels when Redis is available."
  - "AC-005-2: Context cancellation closes the subscription and releases resources; reconnect failure is surfaced through the channel path."
non_scope:
  - "Do not edit module/redisx/SPEC.md, TRACEABILITY.md, or goal.md as part of this implementation task."
  - "Do not add direct runtime dependencies on configx, observex, resiliencx, contracts, or any business-domain module."
  - "Do not implement unrelated Redis commands beyond the FR IDs listed for this task."
test_plan:
  - "TC-008: A publisher sends a message and the subscriber receives matching channel and payload."
depends_on:
  - "TASK-REDISX-001"
estimated_effort: "1d"
priority: P0
status: pending
```

---

## Purpose

为高频 Redis 调用提供非原子的批量提交能力，并用稳定结果结构保留排队顺序、成功结果和第一个错误，避免调用方误以为 Pipeline 具备事务语义。

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
| ----------- | ----------- | ------------------- |
| FR-008 | Subscribe | AC-005-1 |

## Acceptance Criteria

| AC ID | Criteria |
| ----- | -------- |
| AC-005-1 | Subscribe returns a receive-only message channel for requested channels when Redis is available. |
| AC-005-2 | Context cancellation closes the subscription and releases resources; reconnect failure is surfaced through the channel path. |

## Non-Scope

- Do not edit module/redisx/SPEC.md, TRACEABILITY.md, or goal.md as part of this implementation task.
- Do not add direct runtime dependencies on configx, observex, resiliencx, contracts, or any business-domain module.
- Do not implement unrelated Redis commands beyond the FR IDs listed for this task.

## Test Plan

| Test Case | Type | Description | Same-task test file |
| --------- | ---- | ----------- | ------------------- |
| TC-008 | Integration | A publisher sends a message and the subscriber receives matching channel and payload. | `pubsub_test.go` |

## Implementation Notes

- Direct production imports are limited to stdlib, kernel, and the Redis client library; configx/observex/resiliencx/contracts remain integration boundaries expressed through local options, interfaces, docs, or adapters outside this task.
- Every listed test case must be implemented in a same-task `*_test.go` or `example_test.go` file listed in this task.
- Preserve context cancellation and timeout behavior for all Redis calls touched by this task.
