# TASK-REDISX-003

> Hash operations

---

```yaml
task_id: TASK-REDISX-003
module: redisx
scope: "Implement HGet and HSet for Redis hashes with missing-field behavior matching the specification."
spec_ref:
  - "module/redisx/SPEC.md#FR-004"
  - "module/redisx/SPEC.md#FR-005"
  - "module/redisx/SPEC.md#FR-006"
files:
  - "hash.go"
  - "hash_test.go"
  - "testutil_test.go"
acceptance_criteria:
  - "AC-003-1: HSet stores one or more field values and HGet returns existing field values."
  - "AC-003-2: HGet returns redis.Nil for missing fields without wrapping it into an unrelated error."
non_scope:
  - "Do not edit module/redisx/SPEC.md, TRACEABILITY.md, or goal.md as part of this implementation task."
  - "Do not add direct runtime dependencies on configx, observex, resiliencx, contracts, or any business-domain module."
  - "Do not implement unrelated Redis commands beyond the FR IDs listed for this task."
test_plan:
  - "TC-006: HSet followed by HGet returns the stored field value and missing fields return redis.Nil."
depends_on:
  - "TASK-REDISX-001"
estimated_effort: "1d"
priority: P0
status: pending
```

---

## Purpose

交付面向业务读路径的缓存客户端，同时保持 redisx 的基础设施边界：调用方通过 typed Options 和 Codec 注入策略，redisx 不读取配置中心、不暴露完整 Key、不承担业务缓存模型。

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
| ----------- | ----------- | ------------------- |
| FR-006 | HGet / HSet | AC-003-1 |

## Acceptance Criteria

| AC ID | Criteria |
| ----- | -------- |
| AC-003-1 | HSet stores one or more field values and HGet returns existing field values. |
| AC-003-2 | HGet returns redis.Nil for missing fields without wrapping it into an unrelated error. |

## Non-Scope

- Do not edit module/redisx/SPEC.md, TRACEABILITY.md, or goal.md as part of this implementation task.
- Do not add direct runtime dependencies on configx, observex, resiliencx, contracts, or any business-domain module.
- Do not implement unrelated Redis commands beyond the FR IDs listed for this task.

## Test Plan

| Test Case | Type | Description | Same-task test file |
| --------- | ---- | ----------- | ------------------- |
| TC-006 | Unit/Integration | HSet followed by HGet returns the stored field value and missing fields return redis.Nil. | `hash_test.go` |

## Implementation Notes

- Direct production imports are limited to stdlib, kernel, and the Redis client library; configx/observex/resiliencx/contracts remain integration boundaries expressed through local options, interfaces, docs, or adapters outside this task.
- Every listed test case must be implemented in a same-task `*_test.go` or `example_test.go` file listed in this task.
- Preserve context cancellation and timeout behavior for all Redis calls touched by this task.
