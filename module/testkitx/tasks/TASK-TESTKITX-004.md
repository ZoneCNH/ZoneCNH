# TASK-TESTKITX-004

> FakeTracer 实现

---

```yaml
task_id: TASK-TESTKITX-004
module: testkitx
scope: "实现 FakeTracer，记录 spans 到内存供断言"
spec_ref:
  - "module/testkitx/SPEC.md#FR-004"
files:
  - "fake_tracer.go"
  - "fake_tracer_test.go"
acceptance_criteria:
  - "FakeTracer 实现 observex.Tracer 接口"
  - "Start 创建 span 并记录"
  - "Spans() 返回所有记录的 span"
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
| FR-004 | FakeTracer：记录 spans 到内存 | Spans() 可断言 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | Unit | Start 后 Spans() 包含该 span |
| — | Unit | 子 span 继承 trace_id |

## Implementation Notes

- 内部 `[]SpanData` 记录所有 span
- FakeSpan 记录 attrs、events、ended 状态

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `FakeTracer` 和 `FakeSpan` | `fake_tracer.go` | `go build ./...` 通过 |
| 2 | 实现 `Spans()` 断言方法 | `fake_tracer.go` | 全部测试通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Tracer 接口不完整 | Low | Medium | 对照 observex.Tracer 定义 |
