# TASK-SCHEDULEX-008

> Clock 抽象：可测试时间

---

```yaml
task_id: TASK-SCHEDULEX-008
module: schedulex
scope: "实现 Clock 接口，支持真实时钟和 mock 时钟"
spec_ref:
  - "specs/schedulex/SPEC.md#FR-009"
files:
  - "clock_impl.go"
  - "clock_test.go"
acceptance_criteria:
  - "RealClock 返回真实时间"
  - "MockClock 可控制时间推进"
  - "所有调度逻辑使用 Clock 接口"
depends_on:
  - "TASK-SCHEDULEX-001"
estimated_effort: "1h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-009 | Clock：可测试时间 | MockClock 可控 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | Unit | MockClock：设置时间后调度正确触发 |

## Implementation Notes

- `Clock` 接口：`Now() time.Time`, `After(d time.Duration) <-chan time.Time`
- `RealClock`：委托给 `time.Now()` 和 `time.After()`
- `MockClock`：内部维护可控时间，`Advance(d)` 推进时间

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `RealClock` | `clock_impl.go` | `go build ./...` 通过 |
| 2 | 实现 `MockClock`：Now/After/Advance | `clock_impl.go` | `go test ./... -run TestMockClock` 通过 |
| 3 | 集成到 scheduler | `scheduler_impl.go` | 调度测试使用 MockClock |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| MockClock 并发安全 | Low | High | sync.Mutex 保护状态 |
