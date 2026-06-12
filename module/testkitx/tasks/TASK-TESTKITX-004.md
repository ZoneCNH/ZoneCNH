# TASK-TESTKITX-004

> FakeTracer 实现

---

```yaml
task_id: TASK-TESTKITX-004
module: testkitx
scope: "实现 FakeTracer，记录 spans 到内存供断言"
non_scope: "不导出到外部 tracing 系统，不实现采样"
spec_ref:
  - "module/testkitx/SPEC.md#FR-004"
files:
  - "fake_tracer.go"
  - "fake_tracer_test.go"
acceptance_criteria:
  - "AC-004: FakeTracer 实现 observex.Tracer 接口"
  - "AC-004: Start 创建 span 并记录"
  - "AC-004: AssertSpanCount/AssertTraceID 可用"
depends_on:
  - "TASK-TESTKITX-000"
estimated_effort: "1h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description                   | Acceptance Criteria |
| ----------- | ----------------------------- | ------------------- |
| FR-004      | FakeTracer：记录 spans 到内存 | AC-004              |

## Test Plan

| Test Case | Type | Description                  |
| --------- | ---- | ---------------------------- |
| TC-004    | Unit | Start 后 Spans() 包含该 span |
| TC-004    | Unit | AssertSpanCount 验证数量     |
| TC-004    | Unit | 子 span 继承 trace_id        |

## Implementation Notes

- 内部 `[]SpanData` 记录所有 span
- FakeSpan 记录 attrs、events、ended 状态

## Implementation Plan

| Step | Description                     | Deliverables     | Verification          |
| ---- | ------------------------------- | ---------------- | --------------------- |
| 1    | 实现 `FakeTracer` 和 `FakeSpan` | `fake_tracer.go` | `go build ./...` 通过 |
| 2    | 实现 `Spans()` 断言方法         | `fake_tracer.go` | 全部测试通过          |

### Risk Assessment

| Risk              | Probability | Impact | Mitigation                |
| ----------------- | ----------- | ------ | ------------------------- |
| Tracer 接口不完整 | Low         | Medium | 对照 observex.Tracer 定义 |
