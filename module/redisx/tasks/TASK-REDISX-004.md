# TASK-REDISX-004

> List operations

---

```yaml
task_id: TASK-REDISX-004
module: redisx
scope: "Implement LPush and LRange list helpers."
spec_ref:
  - "module/redisx/SPEC.md#FR-007"
files:
  - "list.go"
  - "list_test.go"
  - "testutil_test.go"
acceptance_criteria:
  - "AC-004-1: LPush inserts all values at the list head and LRange returns the requested range in Redis order."
  - "AC-004-2: LRange on a missing list returns an empty slice and nil error."
non_scope:
  - "Do not edit module/redisx/SPEC.md, TRACEABILITY.md, or goal.md as part of this implementation task."
  - "Do not add direct runtime dependencies on configx, observex, resiliencx, contracts, or any business-domain module."
  - "Do not implement unrelated Redis commands beyond the FR IDs listed for this task."
test_plan:
  - "TC-007: LPush two elements and LRange verifies order and missing-list behavior."
depends_on:
  - "TASK-REDISX-001"
estimated_effort: "1d"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
| ----------- | ----------- | ------------------- |
| FR-007 | LPush / LRange | AC-004-1 |

## Acceptance Criteria

| AC ID | Criteria |
| ----- | -------- |
| AC-004-1 | LPush inserts all values at the list head and LRange returns the requested range in Redis order. |
| AC-004-2 | LRange on a missing list returns an empty slice and nil error. |

## Non-Scope

- Do not edit module/redisx/SPEC.md, TRACEABILITY.md, or goal.md as part of this implementation task.
- Do not add direct runtime dependencies on configx, observex, resiliencx, contracts, or any business-domain module.
- Do not implement unrelated Redis commands beyond the FR IDs listed for this task.

## Test Plan

| Test Case | Type | Description | Same-task test file |
| --------- | ---- | ----------- | ------------------- |
| TC-007 | Unit/Integration | LPush two elements and LRange verifies order and missing-list behavior. | `list_test.go` |

## Implementation Notes

- Direct production imports are limited to stdlib, kernel, and the Redis client library; configx/observex/resiliencx/contracts remain integration boundaries expressed through local options, interfaces, docs, or adapters outside this task.
- Every listed test case must be implemented in a same-task `*_test.go` or `example_test.go` file listed in this task.
- Preserve context cancellation and timeout behavior for all Redis calls touched by this task.
