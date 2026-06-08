# TASK-OBSERVEX-001

> 接口定义：Logger、Meter、Tracer、Exporter、Field、Attr、Span

---

```yaml
task_id: TASK-OBSERVEX-001
module: observex
scope: "定义 Logger、Meter、Tracer、Exporter 接口及 Field、Attr、Span 类型"
spec_ref:
  - "module/observex/SPEC.md#9.1"
  - "module/observex/SPEC.md#9.2"
  - "module/observex/SPEC.md#9.3"
  - "module/observex/SPEC.md#9.4"
files:
  - "logger/logger.go"
  - "meter/meter.go"
  - "tracer/tracer.go"
  - "exporter/exporter.go"
acceptance_criteria:
  - "Logger 接口包含 Debug/Info/Warn/Error/With/Named 6 个方法"
  - "Meter 接口包含 Counter/Histogram/Gauge 3 个方法"
  - "Tracer 接口包含 Start 方法，Span 接口包含 End/SetAttributes/RecordError/SpanID/TraceID"
  - "Exporter 接口包含 ExportLogs/ExportMetrics/ExportSpans/Shutdown 4 个方法"
  - "go build ./... 编译通过"
depends_on:
  - "TASK-OBSERVEX-000"
estimated_effort: "1h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| §9.1 | Logger 接口（6 方法 + Field 结构体） | 签名与 SPEC 一致 |
| §9.2 | Meter 接口（Counter/Histogram/Gauge + Attr） | 签名与 SPEC 一致 |
| §9.3 | Tracer/Span 接口（Start/End/SetAttributes/RecordError） | 签名与 SPEC 一致 |
| §9.4 | Exporter 接口（ExportLogs/Metrics/Spans + Shutdown） | 签名与 SPEC 一致 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | Compile | 接口完整性编译验证 |
| — | Compile | Field/Attr/SpanConfig 类型可用 |

## Implementation Notes

- `Field` 结构体 `{Key string, Value any}` 在 `logger/logger.go` 中定义
- `Attr` 结构体 `{Key, Value string}` 在 `meter/meter.go` 中定义
- `SpanKind` 枚举（client/server/internal/producer/consumer）在 `tracer/tracer.go` 中定义
- 各接口在各自子包中定义，避免循环依赖

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 定义 `Logger` 接口和 `Field` 结构体 | `logger/logger.go` | `go build ./...` 通过 |
| 2 | 定义 `Meter` 接口（Counter/Histogram/Gauge）和 `Attr` 结构体 | `meter/meter.go` | `go build ./...` 通过 |
| 3 | 定义 `Tracer`/`Span` 接口和 `SpanKind`/`SpanOption` 类型 | `tracer/tracer.go` | `go build ./...` 通过 |
| 4 | 定义 `Exporter` 接口和 `LogEntry`/`MetricPoint`/`SpanData` 数据类型 | `exporter/exporter.go` | `go build ./...` 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 接口方法签名与下游不匹配 | Medium | High | 对照 SPEC §9 和上游 observex 确认 |
| 子包间循环依赖 | Low | High | 各接口独立子包，不互相引用 |
