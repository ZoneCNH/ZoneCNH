# TASK-TESTKITX-002

> FakeLogger 实现

---

```yaml
task_id: TASK-TESTKITX-002
module: testkitx
scope: "实现 FakeLogger，记录日志到内存供断言"
spec_ref:
  - "specs/testkitx/SPEC.md#FR-002"
files:
  - "fake_logger.go"
  - "fake_logger_test.go"
acceptance_criteria:
  - "FakeLogger 实现 observex.Logger 接口"
  - "Debug/Info/Warn/Error 记录到内部 slice"
  - "With 返回新实例"
  - "提供 Entries() 断言方法"
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
| FR-002 | FakeLogger：记录日志到内存 | Entries() 可断言 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | Unit | Info 后 Entries() 包含该条目 |
| — | Unit | With 不变性 |

## Implementation Notes

- 内部 `[]LogEntry` 记录所有日志
- `LogEntry` 包含 Level、Msg、Fields
- `sync.Mutex` 保护并发写入

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `FakeLogger` 结构体和日志记录方法 | `fake_logger.go` | `go build ./...` 通过 |
| 2 | 实现 `Entries()` 断言方法 | `fake_logger.go` | 全部测试通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Logger 接口不完整 | Low | Medium | 对照 observex.Logger 定义 |
