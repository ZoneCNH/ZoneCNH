# TASK-REDISX-006

> Pipeline command execution

---

```yaml
task_id: TASK-REDISX-006
module: redisx
scope: "Implement Pipeline creation, command queuing, ordered Exec results, and partial-error behavior."
spec_ref:
  - "module/redisx/SPEC.md#FR-009"
files:
  - "pipeline.go"
  - "commands.go"
  - "pipeline_test.go"
  - "testutil_test.go"
acceptance_criteria:
  - "AC-006-1: Pipeline returns a new command queue and Exec returns command results in queue order."
  - "AC-006-2: Exec returns successful command results plus the first command error when a subset fails."
non_scope:
  - "Do not edit module/redisx/SPEC.md, TRACEABILITY.md, or goal.md as part of this implementation task."
  - "Do not add direct runtime dependencies on configx, observex, resiliencx, contracts, or any business-domain module."
  - "Do not implement unrelated Redis commands beyond the FR IDs listed for this task."
test_plan:
  - "TC-003: Three queued Set commands execute in one pipeline and leave all keys set."
depends_on:
  - "TASK-REDISX-000"
  - "TASK-REDISX-001"
estimated_effort: "1d"
priority: P0
status: pending
```

---

## Purpose

提供单 Redis 实例语义下的分布式锁基础能力，重点保证 holder token、TTL、续期和释放保护，而不是扩展为多节点一致性算法。

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
| ----------- | ----------- | ------------------- |
| FR-009 | Pipeline | AC-006-1 |

## Acceptance Criteria

| AC ID | Criteria |
| ----- | -------- |
| AC-006-1 | Pipeline returns a new command queue and Exec returns command results in queue order. |
| AC-006-2 | Exec returns successful command results plus the first command error when a subset fails. |

## Non-Scope

- Do not edit module/redisx/SPEC.md, TRACEABILITY.md, or goal.md as part of this implementation task.
- Do not add direct runtime dependencies on configx, observex, resiliencx, contracts, or any business-domain module.
- Do not implement unrelated Redis commands beyond the FR IDs listed for this task.

## Test Plan

| Test Case | Type | Description | Same-task test file |
| --------- | ---- | ----------- | ------------------- |
| TC-003 | Unit/Integration | Three queued Set commands execute in one pipeline and leave all keys set. | `pipeline_test.go` |

## Implementation Notes

- Direct production imports are limited to stdlib, kernel, and the Redis client library; configx/observex/resiliencx/contracts remain integration boundaries expressed through local options, interfaces, docs, or adapters outside this task.
- Every listed test case must be implemented in a same-task `*_test.go` or `example_test.go` file listed in this task.
- Preserve context cancellation and timeout behavior for all Redis calls touched by this task.
