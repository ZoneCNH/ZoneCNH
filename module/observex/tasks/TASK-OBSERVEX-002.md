# TASK-OBSERVEX-002

> Logger 实现：结构化日志、level 过滤、With 不变性、并发安全

---

```yaml
task_id: TASK-OBSERVEX-002
module: observex
scope: "实现 Logger 接口，支持结构化日志输出、level 过滤、With 不变性、并发安全"
spec_ref:
  - "module/observex/SPEC.md#FR-001"
  - "module/observex/SPEC.md#BR-001"
  - "module/observex/SPEC.md#BR-005"
files:
  - "logger/logger.go"
  - "logger/impl.go"
  - "logger/logger_test.go"
acceptance_criteria:
  - "Info/Warn/Error 输出结构化日志"
  - "Debug 在 level=info 时不输出"
  - "With 返回新实例，原实例不变"
  - "并发调用无 data race"
depends_on:
  - "TASK-OBSERVEX-001"
estimated_effort: "3h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description                               | Acceptance Criteria |
| ----------- | ----------------------------------------- | ------------------- |
| FR-001      | Logger：level 过滤、With 不变性、并发安全 | 4 个 WHEN/THEN 场景 |
| BR-001      | Logger 实现必须并发安全                   | `-race` 测试通过    |
| BR-005      | With 返回新实例，不修改原 Logger          | 不变性验证          |

## Test Plan

| Test Case | Type | Description                              |
| --------- | ---- | ---------------------------------------- |
| TC-001    | Unit | Logger.With 不变性：l1.With 不影响 l1    |
| —         | Unit | level 过滤：level=info → debug 不输出    |
| —         | Unit | 结构化输出：包含 msg 和所有 fields       |
| —         | Unit | 并发安全：多 goroutine 同时写日志无 race |

## Implementation Notes

- 内部使用 `sync.RWMutex` 保护输出
- `With` 创建新实例，复制 fields 后追加新字段
- level 过滤在 Debug/Info/Warn/Error 入口处检查
- 输出格式支持 JSON 和 text（通过配置）

## Implementation Plan

| Step | Description                                            | Deliverables            | Verification                      |
| ---- | ------------------------------------------------------ | ----------------------- | --------------------------------- |
| 1    | 定义 `loggerImpl` 结构体（level, fields, writer, mu）  | `logger/impl.go`        | `go build ./...` 通过             |
| 2    | 实现 Debug/Info/Warn/Error：level 检查 → 格式化 → 写入 | `logger/impl.go`        | `go test ./logger/...` 通过       |
| 3    | 实现 `With`：创建新实例，复制 fields                   | `logger/impl.go`        | TC-001 通过                       |
| 4    | 并发安全验证                                           | `logger/logger_test.go` | `go test -race ./logger/...` 通过 |

### Risk Assessment

| Risk                | Probability | Impact | Mitigation          |
| ------------------- | ----------- | ------ | ------------------- |
| With 共享底层 slice | Medium      | High   | 深拷贝 fields slice |
| 输出格式不一致      | Low         | Medium | 统一 JSON 编码器    |
