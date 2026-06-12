# TASK-REDISX-001

> Client construction and reconnect behavior

---

```yaml
task_id: TASK-REDISX-001
module: redisx
scope: "Implement New/Close/client lifecycle and reconnect-safe command execution for basic KV calls."
spec_ref:
  - "module/redisx/SPEC.md#FR-001"
  - "module/redisx/SPEC.md#FR-002"
files:
  - "client.go"
  - "redis_client.go"
  - "client_test.go"
  - "reconnect_test.go"
  - "testutil_test.go"
acceptance_criteria:
  - "AC-001-1: New validates options, creates a Redis client, and Close is idempotent."
  - "AC-001-2: Get/Set use context-aware commands and recover after a transient connection loss."
non_scope:
  - "Do not edit module/redisx/SPEC.md, TRACEABILITY.md, or goal.md as part of this implementation task."
  - "Do not add direct runtime dependencies on configx, observex, resiliencx, contracts, or any business-domain module."
  - "Do not implement unrelated Redis commands beyond the FR IDs listed for this task."
test_plan:
  - "TC-001: Set then Get returns the stored value through a constructed client."
  - "TC-004: A transient disconnect followed by recovery allows the next operation to succeed."
depends_on:
  - "TASK-REDISX-000"
estimated_effort: "1d"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
| ----------- | ----------- | ------------------- |
| FR-001 | Get | AC-001-1 |
| FR-002 | Set | AC-001-2 |

## Acceptance Criteria

| AC ID | Criteria |
| ----- | -------- |
| AC-001-1 | New validates options, creates a Redis client, and Close is idempotent. |
| AC-001-2 | Get/Set use context-aware commands and recover after a transient connection loss. |

## Non-Scope

- Do not edit module/redisx/SPEC.md, TRACEABILITY.md, or goal.md as part of this implementation task.
- Do not add direct runtime dependencies on configx, observex, resiliencx, contracts, or any business-domain module.
- Do not implement unrelated Redis commands beyond the FR IDs listed for this task.

## Test Plan

| Test Case | Type | Description | Same-task test file |
| --------- | ---- | ----------- | ------------------- |
| TC-001 | Integration | Set then Get returns the stored value through a constructed client. | `client_test.go` |
| TC-004 | Integration | A transient disconnect followed by recovery allows the next operation to succeed. | `reconnect_test.go` |

## Implementation Notes

- Direct production imports are limited to stdlib, kernel, and the Redis client library; configx/observex/resiliencx/contracts remain integration boundaries expressed through local options, interfaces, docs, or adapters outside this task.
- Every listed test case must be implemented in a same-task `*_test.go` or `example_test.go` file listed in this task.
- Preserve context cancellation and timeout behavior for all Redis calls touched by this task.
