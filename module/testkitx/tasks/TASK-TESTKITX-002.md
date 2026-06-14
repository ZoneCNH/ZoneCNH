# TASK-TESTKITX-002

> FakeLogger 实现

---

```yaml
task_id: TASK-TESTKITX-002
module: testkitx
scope: "实现 FakeLogger，记录日志到内存供断言"
non_scope: "不写入文件或外部系统，不实现日志采样"
spec_ref:
  - "module/testkitx/SPEC.md#FR-002"
files:
  - "fake_logger.go"
  - "fake_logger_test.go"
acceptance_criteria:
  - "AC-002: FakeLogger 实现 observex.Logger 接口"
  - "AC-002: Debug/Info/Warn/Error 记录到内部 slice"
  - "AC-002: With 返回新实例（不可变性）"
  - "AC-002: AssertLogged/AssertNoErrors/Entries 可用"
depends_on:
  - "TASK-TESTKITX-000"
estimated_effort: "1h"
priority: P0
status: pending
```

---

## Non-scope

- 不涉及本 Task 范围外的功能

## Requirements Covered

| Requirement | Description                | Acceptance Criteria |
| ----------- | -------------------------- | ------------------- |
| FR-002      | FakeLogger：记录日志到内存 | AC-002              |

## Test Plan

| Test Case | Type | Description                  |
| --------- | ---- | ---------------------------- |
| TC-002    | Unit | Info 后 Entries() 包含该条目 |
| TC-002    | Unit | AssertLogged 匹配正确        |
| TC-002    | Unit | With 不变性                  |

## Implementation Notes

- 内部 `[]LogEntry` 记录所有日志
- `LogEntry` 包含 Level、Msg、Fields
- `sync.Mutex` 保护并发写入

## Implementation Plan

| Step | Description                            | Deliverables     | Verification          |
| ---- | -------------------------------------- | ---------------- | --------------------- |
| 1    | 实现 `FakeLogger` 结构体和日志记录方法 | `fake_logger.go` | `go build ./...` 通过 |
| 2    | 实现 `Entries()` 断言方法              | `fake_logger.go` | 全部测试通过          |

### Risk Assessment

| Risk              | Probability | Impact | Mitigation                |
| ----------------- | ----------- | ------ | ------------------------- |
| Logger 接口不完整 | Low         | Medium | 对照 observex.Logger 定义 |
