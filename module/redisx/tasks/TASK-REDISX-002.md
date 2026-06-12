# TASK-REDISX-002

> KV deletion, existence, and expiration

---

```yaml
task_id: TASK-REDISX-002
module: redisx
scope: "Implement Del, Exists, and Expire behavior on top of the Redis client."
spec_ref:
  - "module/redisx/SPEC.md#FR-003"
  - "module/redisx/SPEC.md#FR-004"
  - "module/redisx/SPEC.md#FR-005"
files:
  - "kv.go"
  - "kv_test.go"
  - "expiration_test.go"
  - "testutil_test.go"
acceptance_criteria:
  - "AC-002-1: Del is idempotent for missing keys and succeeds for mixed existing/missing keys."
  - "AC-002-2: Exists returns the number of present keys and Expire updates TTL without failing on missing keys."
non_scope:
  - "Do not edit module/redisx/SPEC.md, TRACEABILITY.md, or goal.md as part of this implementation task."
  - "Do not add direct runtime dependencies on configx, observex, resiliencx, contracts, or any business-domain module."
  - "Do not implement unrelated Redis commands beyond the FR IDs listed for this task."
test_plan:
  - "TC-001: KV chain covers Set/Get/Del behavior for existing and missing keys."
  - "TC-005: Exists and Expire update and report TTL state as specified."
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
| FR-003 | Del | AC-002-1 |
| FR-004 | Exists | AC-002-2 |
| FR-005 | Expire | AC-002-2 |

## Acceptance Criteria

| AC ID | Criteria |
| ----- | -------- |
| AC-002-1 | Del is idempotent for missing keys and succeeds for mixed existing/missing keys. |
| AC-002-2 | Exists returns the number of present keys and Expire updates TTL without failing on missing keys. |

## Non-Scope

- Do not edit module/redisx/SPEC.md, TRACEABILITY.md, or goal.md as part of this implementation task.
- Do not add direct runtime dependencies on configx, observex, resiliencx, contracts, or any business-domain module.
- Do not implement unrelated Redis commands beyond the FR IDs listed for this task.

## Test Plan

| Test Case | Type | Description | Same-task test file |
| --------- | ---- | ----------- | ------------------- |
| TC-001 | Unit/Integration | KV chain covers Set/Get/Del behavior for existing and missing keys. | `kv_test.go` |
| TC-005 | Unit/Integration | Exists and Expire update and report TTL state as specified. | `expiration_test.go` |

## Implementation Notes

- Direct production imports are limited to stdlib, kernel, and the Redis client library; configx/observex/resiliencx/contracts remain integration boundaries expressed through local options, interfaces, docs, or adapters outside this task.
- Every listed test case must be implemented in a same-task `*_test.go` or `example_test.go` file listed in this task.
- Preserve context cancellation and timeout behavior for all Redis calls touched by this task.
