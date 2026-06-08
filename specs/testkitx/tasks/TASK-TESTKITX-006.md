# TASK-TESTKITX-006

> Eventually 实现

---

```yaml
task_id: TASK-TESTKITX-006
module: testkitx
scope: "实现 Eventually 断言函数，轮询条件直到满足或超时"
spec_ref:
  - "specs/testkitx/SPEC.md#FR-007"
files:
  - "eventually.go"
  - "eventually_test.go"
acceptance_criteria:
  - "Eventually(fn) 在 fn 返回 true 时通过"
  - "Eventually(fn, timeout) 超时后 fail"
  - "默认轮询间隔可配置"
depends_on:
  - "TASK-TESTKITX-000"
estimated_effort: "1h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-007 | Eventually：轮询条件断言 | 超时/成功两种场景 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | Unit | 条件立即满足：通过 |
| — | Unit | 条件延迟满足：通过 |
| — | Unit | 超时：fail |

## Implementation Notes

- `Eventually(t *testing.T, fn func() bool, opts ...Option)`
- 默认 timeout=5s，interval=100ms
- 使用 `time.Ticker` 轮询

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `Eventually` 函数 | `eventually.go` | 全部测试通过 |
| 2 | 实现 Option：WithTimeout/WithInterval | `eventually.go` | 配置生效 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 测试不稳定 | Medium | Low | 合理默认 timeout |
