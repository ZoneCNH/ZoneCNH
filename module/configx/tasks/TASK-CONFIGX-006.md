# TASK-CONFIGX-006

> Reader 实现：Get/GetString/GetInt 等类型安全读取、并发安全

---

```yaml
task_id: TASK-CONFIGX-006
module: configx
scope: "实现 Reader 接口的所有方法，支持类型安全读取和并发安全"
spec_ref:
  - "module/configx/SPEC.md#FR-004"
  - "module/configx/SPEC.md#BR-005"
files:
  - "reader.go"
  - "reader_test.go"
acceptance_criteria:
  - "Get 存在的 key 返回对应值"
  - "Get 不存在的 key 返回 nil"
  - "多 goroutine 并发 Get 无数据竞争"
  - "Reader 只读，不能修改底层配置"
depends_on:
  - "TASK-CONFIGX-003"
  - "TASK-CONFIGX-004"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description                        | Acceptance Criteria |
| ----------- | ---------------------------------- | ------------------- |
| FR-004      | Get：存在→值，不存在→nil，并发安全 | 3 个 WHEN/THEN 场景 |
| BR-005      | Reader 接口只能读，不能写          | 只暴露读方法        |

## Test Plan

| Test Case | Type      | Description                                                       |
| --------- | --------- | ----------------------------------------------------------------- |
| TC-003    | Unit      | 并发安全：100 goroutine 并发 Get 无 data race（-race 通过）       |
| TC-005    | Unit      | Reader 只读：不能通过 Reader 修改底层配置                         |
| —         | Unit      | Get 存在 key：返回正确值                                          |
| —         | Unit      | Get 不存在 key：返回 nil                                          |
| —         | Unit      | 类型方法转换正确（GetString/GetInt/GetFloat/GetBool/GetDuration） |
| —         | Benchmark | Load 1000 key < 50ms                                              |
| —         | Benchmark | Get 单次 < 100ns                                                  |

## Non-scope

- 不做配置文件解析（→ TASK-002）
- 不做环境变量处理（→ TASK-004）
- 不做 schema 校验（→ TASK-005）
- 不做文件监控（→ TASK-007）

## Implementation Notes

- Reader 实现使用 `sync.RWMutex` 保护内部 data map
- `Get` 通过点分路径遍历嵌套 map 获取值
- 类型方法内部调用 Get 后做类型断言，失败返回零值

## Implementation Plan

| Step | Description                                                            | Deliverables     | Verification                          |
| ---- | ---------------------------------------------------------------------- | ---------------- | ------------------------------------- |
| 1    | 实现 `Get(key)` 方法：点分路径遍历嵌套 map                             | `reader.go`      | `go test ./... -run TestGet` 通过     |
| 2    | 实现类型方法：GetString、GetInt、GetFloat、GetBool、GetDuration、IsSet | `reader.go`      | `go test ./... -run TestGetType` 通过 |
| 3    | 添加 `sync.RWMutex` 保证并发安全                                       | `reader.go`      | `go test -race ./...` 通过            |
| 4    | 编写只读验证测试                                                       | `reader_test.go` | TC-005 通过                           |

### Risk Assessment

| Risk               | Probability | Impact | Mitigation                   |
| ------------------ | ----------- | ------ | ---------------------------- |
| 点分路径遍历 panic | Medium      | High   | 逐层检查 nil，不存在返回 nil |
| 类型断言 panic     | Low         | High   | 使用 comma-ok 模式           |
