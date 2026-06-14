# TASK-OBSERVEX-005

> Exporter 实现：OTLP、noop、test exporter、Shutdown flush

---

```yaml
task_id: TASK-OBSERVEX-005
module: observex
scope: "实现 Exporter 接口：OTLP exporter、noop exporter、test exporter，支持 Shutdown flush"
spec_ref:
  - "module/observex/SPEC.md#FR-004"
  - "module/observex/SPEC.md#BR-004"
  - "module/observex/SPEC.md#BR-008"
files:
  - "exporter/otlp/otlp.go"
  - "exporter/noop/noop.go"
  - "exporter/test/test.go"
  - "exporter/exporter_test.go"
acceptance_criteria:
  - "OTLP exporter 可发送 logs/metrics/spans"
  - "noop exporter 静默丢弃所有数据"
  - "test exporter 记录所有数据供测试断言"
  - "Shutdown flush 缓冲区"
  - "不直接绑定 Prometheus/Otel/Zap"
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

| Requirement | Description                                   | Acceptance Criteria    |
| ----------- | --------------------------------------------- | ---------------------- |
| FR-004      | Exporter：ExportLogs/Metrics/Spans + Shutdown | 2 个 WHEN/THEN 场景    |
| BR-004      | Exporter.Shutdown 必须 flush 缓冲区           | Shutdown 后数据不丢失  |
| BR-008      | 不直接绑定 Prometheus/Otel/Zap                | 通过 Exporter 接口抽象 |

## Test Plan

| Test Case | Type | Description                              |
| --------- | ---- | ---------------------------------------- |
| TC-004    | Unit | Exporter 降级：exporter 不可达不影响业务 |
| —         | Unit | noop exporter：所有方法返回 nil          |
| —         | Unit | test exporter：记录所有数据              |
| —         | Unit | Shutdown flush：Shutdown 后数据已发送    |

## Implementation Notes

- `exporter/noop` 包：所有方法返回 nil，最简单的实现
- `exporter/test` 包：内部 slice 记录所有 entries/metrics/spans，供测试断言
- `exporter/otlp` 包：使用 OTLP gRPC/HTTP 协议发送（可选依赖）
- Shutdown 通过 `sync.WaitGroup` 等待所有 pending 发送完成

## Implementation Plan

| Step | Description                                                                             | Deliverables            | Verification                       |
| ---- | --------------------------------------------------------------------------------------- | ----------------------- | ---------------------------------- |
| 1    | 实现 `exporter/noop`：所有方法返回 nil                                                  | `exporter/noop/noop.go` | `go build ./...` 通过              |
| 2    | 实现 `exporter/test`：记录数据到 slice，提供 `Entries()`/`Metrics()`/`Spans()` 断言方法 | `exporter/test/test.go` | `go test ./exporter/test/...` 通过 |
| 3    | 实现 `exporter/otlp`：gRPC/HTTP 发送，带 buffer 和重试                                  | `exporter/otlp/otlp.go` | `go test ./exporter/otlp/...` 通过 |
| 4    | 实现 Shutdown flush 逻辑和降级处理                                                      | 各 exporter             | TC-004 通过                        |

### Risk Assessment

| Risk                   | Probability | Impact | Mitigation                  |
| ---------------------- | ----------- | ------ | --------------------------- |
| OTLP 依赖引入冲突      | Medium      | Medium | 可选依赖，go build tag 控制 |
| Shutdown 未 flush 完成 | Low         | High   | WaitGroup 等待所有 pending  |
