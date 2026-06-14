# TASK-TESTKITX-001

> FakeConfig 实现

---

```yaml
task_id: TASK-TESTKITX-001
module: testkitx
scope: "实现 FakeConfig，内存配置源，支持测试注入"
non_scope: "不实现热重载，不读取外部文件"
spec_ref:
  - "module/testkitx/SPEC.md#FR-001"
files:
  - "fake_config.go"
  - "fake_config_test.go"
acceptance_criteria:
  - "AC-001: FakeConfig 实现 configx.Reader 接口"
  - "AC-001: Set 注入后 Get/GetString/GetInt 返回注入值"
  - "AC-001: 未设置的 key 返回 nil"
  - "AC-001: 并发安全（-race 通过）"
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

| Requirement | Description            | Acceptance Criteria |
| ----------- | ---------------------- | ------------------- |
| FR-001      | FakeConfig：内存配置源 | AC-001              |

## Test Plan

| Test Case | Type | Description           |
| --------- | ---- | --------------------- |
| TC-001    | Unit | Set 后 Get 返回正确值 |
| TC-001    | Unit | 未设置的 key 返回 nil |
| TC-001    | Unit | 并发安全（-race）     |

## Implementation Notes

- 内部使用 `map[string]any` 存储配置
- `sync.RWMutex` 保护并发访问
- 实现 `configx.Reader` 接口的所有方法

## Implementation Plan

| Step | Description                           | Deliverables          | Verification          |
| ---- | ------------------------------------- | --------------------- | --------------------- |
| 1    | 实现 `FakeConfig` 结构体和 `Set` 方法 | `fake_config.go`      | `go build ./...` 通过 |
| 2    | 实现 `configx.Reader` 接口方法        | `fake_config.go`      | 全部测试通过          |
| 3    | 并发安全验证                          | `fake_config_test.go` | `go test -race` 通过  |

### Risk Assessment

| Risk              | Probability | Impact | Mitigation               |
| ----------------- | ----------- | ------ | ------------------------ |
| Reader 接口不完整 | Low         | Medium | 对照 configx.Reader 定义 |
