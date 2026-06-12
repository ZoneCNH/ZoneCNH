# TASK-REDISX-007

> Distributed lock acquire and release

---

```yaml
task_id: TASK-REDISX-007
module: redisx
scope: "Implement Locker Acquire/Release with holder token, TTL, and atomic release protection."
spec_ref:
  - "module/redisx/SPEC.md#FR-010"
  - "module/redisx/SPEC.md#FR-011"
files:
  - "locker.go"
  - "lock_script.go"
  - "locker_test.go"
  - "testutil_test.go"
acceptance_criteria:
  - "AC-007-1: Acquire succeeds only for an unheld lock, returns false for a competing holder, and always sets a TTL."
  - "AC-007-2: Release succeeds only for the current holder token and does not delete another holder's lock."
non_scope:
  - "Do not edit module/redisx/SPEC.md, TRACEABILITY.md, or goal.md as part of this implementation task."
  - "Do not add direct runtime dependencies on configx, observex, resiliencx, contracts, or any business-domain module."
  - "Do not implement unrelated Redis commands beyond the FR IDs listed for this task."
test_plan:
  - "TC-002: Two clients contend for one lock; only the holder can release it and TTL expiry allows reacquire."
depends_on:
  - "TASK-REDISX-001"
estimated_effort: "1d"
priority: P0
status: pending
```

---

## Purpose

提供最小计数和固定窗口限流 helper，覆盖 Redis 原子自增、窗口过期和并发安全，避免调用方重复编写易错的 TTL/INCR 组合逻辑。

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
| ----------- | ----------- | ------------------- |
| FR-010 | Locker.Acquire | AC-007-1 |
| FR-011 | Locker.Release | AC-007-2 |

## Acceptance Criteria

| AC ID | Criteria |
| ----- | -------- |
| AC-007-1 | Acquire succeeds only for an unheld lock, returns false for a competing holder, and always sets a TTL. |
| AC-007-2 | Release succeeds only for the current holder token and does not delete another holder's lock. |

## Non-Scope

- Do not edit module/redisx/SPEC.md, TRACEABILITY.md, or goal.md as part of this implementation task.
- Do not add direct runtime dependencies on configx, observex, resiliencx, contracts, or any business-domain module.
- Do not implement unrelated Redis commands beyond the FR IDs listed for this task.

## Test Plan

| Test Case | Type | Description | Same-task test file |
| --------- | ---- | ----------- | ------------------- |
| TC-002 | Unit/Integration | Two clients contend for one lock; only the holder can release it and TTL expiry allows reacquire. | `locker_test.go` |

## Implementation Notes

- Direct production imports are limited to stdlib, kernel, and the Redis client library; configx/observex/resiliencx/contracts remain integration boundaries expressed through local options, interfaces, docs, or adapters outside this task.
- Every listed test case must be implemented in a same-task `*_test.go` or `example_test.go` file listed in this task.
- Preserve context cancellation and timeout behavior for all Redis calls touched by this task.
- Use an atomic holder-token check for Release so one client cannot release another client's lock.
