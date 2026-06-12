# TASK-REDISX-008

> Cross-feature integration and performance evidence

---

```yaml
task_id: TASK-REDISX-008
module: redisx
scope: "Add integration and benchmark coverage for high-risk Redis behavior without changing public API scope."
spec_ref:
  - "module/redisx/SPEC.md#FR-001"
  - "module/redisx/SPEC.md#FR-002"
  - "module/redisx/SPEC.md#FR-009"
files:
  - "integration_test.go"
  - "benchmark_test.go"
  - "reconnect_test.go"
  - "testutil_test.go"
acceptance_criteria:
  - "AC-008-1: End-to-end integration covers KV, reconnect, pipeline, and lock interactions against the same test Redis harness."
  - "AC-008-2: Benchmarks record Get/Set and Pipeline latency budgets from SPEC.md section 17."
non_scope:
  - "Do not edit module/redisx/SPEC.md, TRACEABILITY.md, or goal.md as part of this implementation task."
  - "Do not add direct runtime dependencies on configx, observex, resiliencx, contracts, or any business-domain module."
  - "Do not implement unrelated Redis commands beyond the FR IDs listed for this task."
test_plan:
  - "TC-001: End-to-end KV path passes against the integration harness."
  - "TC-003: Pipeline correctness and latency budget are measured."
  - "TC-004: Reconnect behavior is validated in the integration harness."
depends_on:
  - "TASK-REDISX-002"
  - "TASK-REDISX-006"
  - "TASK-REDISX-007"
estimated_effort: "1d"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
| ----------- | ----------- | ------------------- |
| FR-001 | Get | AC-008-1 |
| FR-002 | Set | AC-008-2 |
| FR-009 | Pipeline | AC-008-2 |

## Acceptance Criteria

| AC ID | Criteria |
| ----- | -------- |
| AC-008-1 | End-to-end integration covers KV, reconnect, pipeline, and lock interactions against the same test Redis harness. |
| AC-008-2 | Benchmarks record Get/Set and Pipeline latency budgets from SPEC.md section 17. |

## Non-Scope

- Do not edit module/redisx/SPEC.md, TRACEABILITY.md, or goal.md as part of this implementation task.
- Do not add direct runtime dependencies on configx, observex, resiliencx, contracts, or any business-domain module.
- Do not implement unrelated Redis commands beyond the FR IDs listed for this task.

## Test Plan

| Test Case | Type | Description | Same-task test file |
| --------- | ---- | ----------- | ------------------- |
| TC-001 | Integration | End-to-end KV path passes against the integration harness. | `integration_test.go` |
| TC-003 | Integration/Benchmark | Pipeline correctness and latency budget are measured. | `benchmark_test.go` |
| TC-004 | Integration | Reconnect behavior is validated in the integration harness. | `reconnect_test.go` |

## Implementation Notes

- Direct production imports are limited to stdlib, kernel, and the Redis client library; configx/observex/resiliencx/contracts remain integration boundaries expressed through local options, interfaces, docs, or adapters outside this task.
- Every listed test case must be implemented in a same-task `*_test.go` or `example_test.go` file listed in this task.
- Preserve context cancellation and timeout behavior for all Redis calls touched by this task.
- Benchmarks are evidence-producing checks; they must not become flaky release blockers without documented thresholds from SPEC.md section 17.
