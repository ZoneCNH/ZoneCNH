# TASK-OBSERVEX-004

> Tracer 实现：Start/End span、context 传播、RecordError

---

```yaml
task_id: TASK-OBSERVEX-004
module: observex
scope: "实现 Tracer 接口，支持 span 创建/结束、context 传播 trace_id/span_id、RecordError"
spec_ref:
  - "module/observex/SPEC.md#FR-003"
  - "module/observex/SPEC.md#BR-003"
files:
  - "tracer/tracer.go"
  - "tracer/impl.go"
  - "tracer/propagation.go"
  - "tracer/tracer_test.go"
acceptance_criteria:
  - "Start 创建新 span，返回带 span 的 ctx"
  - "span.End() 结束 span"
  - "span.RecordError(err) 记录错误事件"
  - "子 span 继承父 trace_id"
  - "跨 goroutine context 传播 trace_id"
depends_on:
  - "TASK-OBSERVEX-001"
estimated_effort: "3h"
priority: P0
status: pending
```

---

## Non-scope

- 不涉及本 Task 范围外的功能

## Requirements Covered

| Requirement | Description                                 | Acceptance Criteria |
| ----------- | ------------------------------------------- | ------------------- |
| FR-003      | Tracer：Start/End/RecordError/上下文传播    | 4 个 WHEN/THEN 场景 |
| BR-003      | Tracer 必须从 context 传播 trace_id/span_id | 跨 goroutine 一致   |

## Test Plan

| Test Case | Type | Description                                                   |
| --------- | ---- | ------------------------------------------------------------- |
| TC-003    | Unit | Tracer 上下文传播：goroutine A 创建 span，B 读取同一 trace_id |
| —         | Unit | 子 span 继承父 trace_id                                       |
| —         | Unit | RecordError 记录到 span                                       |
| —         | Unit | span.End() 后 SpanID/TraceID 可读                             |
| —         | Unit | 采样率=0：不采样但不报错                                      |

## Implementation Notes

- trace_id/span_id 存储在 context.Context 中（`context.WithValue`）
- 使用 `SpanKind` 枚举区分 client/server/internal/producer/consumer
- `propagation.go` 处理 context 注入和提取
- span 创建时生成随机 trace_id（首次）或继承父 trace_id

## Implementation Plan

| Step | Description                                                        | Deliverables            | Verification                |
| ---- | ------------------------------------------------------------------ | ----------------------- | --------------------------- |
| 1    | 实现 `spanImpl` 结构体（traceID, spanID, attrs, events, ended）    | `tracer/impl.go`        | `go build ./...` 通过       |
| 2    | 实现 `TracerImpl.Start`：生成/继承 trace_id → 创建 span → 注入 ctx | `tracer/impl.go`        | `go test ./tracer/...` 通过 |
| 3    | 实现 context 传播：`Inject`/`Extract` 方法                         | `tracer/propagation.go` | TC-003 通过                 |
| 4    | 实现 RecordError 和采样逻辑                                        | `tracer/impl.go`        | 所有测试用例通过            |

### Risk Assessment

| Risk               | Probability | Impact | Mitigation                           |
| ------------------ | ----------- | ------ | ------------------------------------ |
| context key 冲突   | Low         | High   | 使用 unexported 类型作为 context key |
| 并发 span 创建竞态 | Low         | Medium | atomic 生成 span ID                  |
