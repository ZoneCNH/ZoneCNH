# TASK-TESTKITX-001

> FakeConfig 实现

---

```yaml
task_id: TASK-TESTKITX-001
module: testkitx
scope: "实现 FakeConfig，内存配置源，支持测试注入"
spec_ref:
  - "module/testkitx/SPEC.md#FR-001"
files:
  - "fake_config.go"
  - "fake_config_test.go"
acceptance_criteria:
  - "FakeConfig 实现 configx.Reader 接口"
  - "支持 Set 注入配置值"
  - "Get/GetString/GetInt 返回注入值"
  - "并发安全"
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
| FR-001 | FakeConfig：内存配置源 | Set/Get/GetString/GetInt |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | Unit | Set 后 Get 返回正确值 |
| — | Unit | 未设置的 key 返回默认值 |
| — | Unit | 并发安全 |

## Implementation Notes

- 内部使用 `map[string]any` 存储配置
- `sync.RWMutex` 保护并发访问
- 实现 `configx.Reader` 接口的所有方法

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `FakeConfig` 结构体和 `Set` 方法 | `fake_config.go` | `go build ./...` 通过 |
| 2 | 实现 `configx.Reader` 接口方法 | `fake_config.go` | 全部测试通过 |
| 3 | 并发安全验证 | `fake_config_test.go` | `go test -race` 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Reader 接口不完整 | Low | Medium | 对照 configx.Reader 定义 |
