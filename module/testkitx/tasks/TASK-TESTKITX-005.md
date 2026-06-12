# TASK-TESTKITX-005

> FakeClock + FakeBreaker 实现

---

```yaml
task_id: TASK-TESTKITX-005
module: testkitx
scope: "实现 FakeClock（可控制时间）和 FakeBreaker（可控制熔断状态）"
non_scope: "不实现真实时间源，不调用真实熔断逻辑"
spec_ref:
  - "module/testkitx/SPEC.md#FR-005"
  - "module/testkitx/SPEC.md#FR-006"
  - "module/testkitx/SPEC.md#BR-002"
files:
  - "fake_clock.go"
  - "fake_breaker.go"
  - "fake_clock_test.go"
  - "fake_breaker_test.go"
acceptance_criteria:
  - "AC-005: FakeClock.Now() 返回可控时间"
  - "AC-005: FakeClock.Advance(d) 推进时间"
  - "AC-005: FakeClock.Set(t) 设置时间"
  - "AC-006: FakeBreaker 可设置状态（Closed/Open/Half-Open）"
  - "AC-006: FakeBreaker.Execute 受状态控制"
  - "BR-002: 确定性 — 不引入 time.Now() 或 math.Rand()"
depends_on:
  - "TASK-TESTKITX-000"
estimated_effort: "1h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description                 | Acceptance Criteria           |
| ----------- | --------------------------- | ----------------------------- |
| FR-005      | FakeClock：可控制时间       | AC-005                        |
| FR-006      | FakeBreaker：可控制熔断状态 | AC-006                        |
| BR-002      | fake 行为确定性             | 不引入 time.Now()/math.Rand() |

## Test Plan

| Test Case | Type | Description                                   |
| --------- | ---- | --------------------------------------------- |
| TC-005    | Unit | Advance 后 Now() 返回新时间                   |
| TC-005    | Unit | Set 后 Now() 返回设置值                       |
| TC-006    | Unit | SetState(Open) 后 Execute 返回 ErrCircuitOpen |

## Implementation Notes

- FakeClock 内部维护 `time.Time`，`Advance(d)` 推进
- FakeBreaker 内部维护 `CircuitState`，`SetState(s)` 设置

## Implementation Plan

| Step | Description                                | Deliverables      | Verification |
| ---- | ------------------------------------------ | ----------------- | ------------ |
| 1    | 实现 `FakeClock`：Now/After/Advance        | `fake_clock.go`   | 测试通过     |
| 2    | 实现 `FakeBreaker`：Execute/State/SetState | `fake_breaker.go` | 测试通过     |

### Risk Assessment

| Risk               | Probability | Impact | Mitigation      |
| ------------------ | ----------- | ------ | --------------- |
| FakeClock 并发安全 | Low         | High   | sync.Mutex 保护 |
