# TASK-REDISX-000

> Package contract, options, and codec foundation

---

```yaml
task_id: TASK-REDISX-000
module: redisx
scope: "Define package skeleton, public options, codec boundary, and shared errors that support Get/Set/Health without introducing cross-module runtime dependencies."
spec_ref:
  - "module/redisx/SPEC.md#FR-001"
  - "module/redisx/SPEC.md#FR-002"
  - "module/redisx/SPEC.md#FR-012"
files:
  - "go.mod"
  - "doc.go"
  - "options.go"
  - "codec.go"
  - "errors_test.go"
acceptance_criteria:
  - "AC-000-1: Public options expose address, DB, pool, timeout, and codec knobs needed by Get/Set and Health."
  - "AC-000-2: Default codec and error contracts are documented and compile-tested without importing configx/observex/resiliencx/contracts."
non_scope:
  - "Do not edit module/redisx/SPEC.md, TRACEABILITY.md, or goal.md as part of this implementation task."
  - "Do not add direct runtime dependencies on configx, observex, resiliencx, contracts, or any business-domain module."
  - "Do not implement unrelated Redis commands beyond the FR IDs listed for this task."
test_plan:
  - "TC-001: Compile and default-codec checks cover basic Set/Get serialization behavior."
  - "TC-009: Health status type and default option construction are compile-checked."
depends_on: []
estimated_effort: "1d"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
| ----------- | ----------- | ------------------- |
| FR-001 | Get | AC-000-1 |
| FR-002 | Set | AC-000-2 |
| FR-012 | Health | AC-000-2 |

## Acceptance Criteria

| AC ID | Criteria |
| ----- | -------- |
| AC-000-1 | Public options expose address, DB, pool, timeout, and codec knobs needed by Get/Set and Health. |
| AC-000-2 | Default codec and error contracts are documented and compile-tested without importing configx/observex/resiliencx/contracts. |

## Non-Scope

- Do not edit module/redisx/SPEC.md, TRACEABILITY.md, or goal.md as part of this implementation task.
- Do not add direct runtime dependencies on configx, observex, resiliencx, contracts, or any business-domain module.
- Do not implement unrelated Redis commands beyond the FR IDs listed for this task.

## Test Plan

| Test Case | Type | Description | Same-task test file |
| --------- | ---- | ----------- | ------------------- |
| TC-001 | Unit | Compile and default-codec checks cover basic Set/Get serialization behavior. | `errors_test.go` |
| TC-009 | Unit | Health status type and default option construction are compile-checked. | `errors_test.go` |

## Implementation Notes

- Direct production imports are limited to stdlib, kernel, and the Redis client library; configx/observex/resiliencx/contracts remain integration boundaries expressed through local options, interfaces, docs, or adapters outside this task.
- Every listed test case must be implemented in a same-task `*_test.go` or `example_test.go` file listed in this task.
- Preserve context cancellation and timeout behavior for all Redis calls touched by this task.
