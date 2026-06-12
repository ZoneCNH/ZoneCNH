# TASK-KERNEL-003

> obsx 子包：可观测抽象接口 + Noop 实现 + SecretString 脱敏

---

```yaml
task_id: TASK-KERNEL-003
module: kernel
scope: "实现 obsx 子包：Logger/Metrics/Tracer/Span 接口、Noop* 零值实现、SecretString、Sanitizer 接口、Field 类型"
spec_ref:
  - "module/kernel/SPEC.md#FR-004"
  - "module/kernel/SPEC.md#BR-006"
  - "module/kernel/SPEC.md#9.4"
files:
  - "obsx/obsx.go"
  - "obsx/obsx_test.go"
  - "obsx/example_test.go"
acceptance_criteria:
  - "AC-006: NoopLogger/NoopMetrics/NoopTracer/NoopSpan 所有方法静默成功不 panic"
  - "AC-007: SecretString 所有公开方法返回 \"***\"，仅 Reveal() 可访问原始值"
  - "AC-OBSX-01: Logger 接口包含 Debug/Info/Warn/Error 四方法"
  - "AC-OBSX-02: Metrics 接口包含 Count/Observe 两方法"
  - "AC-OBSX-03: Tracer.Start 返回 (context.Context, Span)"
  - "AC-OBSX-04: Span 接口包含 End/RecordError/SetFields 三方法"
  - "AC-OBSX-05: SecretString 的 String()/GoString()/MarshalJSON() 均返回 \"***\""
  - "AC-OBSX-06: SecretString 空值 String() 返回 \"\""
  - "AC-OBSX-07: go test -race -count=1 ./obsx/... 通过"
depends_on:
  - "TASK-KERNEL-000"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description |
|---|---|
| FR-004 | 可观测抽象 |
| BR-006 | 所有接口必须有 Noop 零值实现 |

## Non-scope

- 不实现具体的日志/指标/追踪后端（→ observex）
- 不包含 OpenTelemetry 适配

## Implementation Notes

- Noop* 类型是空结构体，所有方法静默成功
- SecretString 实现 fmt.Stringer、json.Marshaler、gob.GobEncoder
- Field 使用 `[]Field` 而非 `...any`
