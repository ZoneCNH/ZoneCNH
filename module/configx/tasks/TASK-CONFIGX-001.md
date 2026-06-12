# TASK-CONFIGX-001

> 接口定义：Reader、Config、Option 模式

---

```yaml
task_id: TASK-CONFIGX-001
module: configx
scope: "定义 Reader、Config 接口及 Option 函数模式"
spec_ref:
  - "module/configx/SPEC.md#BR-009"
  - "module/configx/SPEC.md#§9.1"
files:
  - "reader.go"
  - "config.go"
  - "options.go"
  - "config_test.go"
acceptance_criteria:
  - "Reader 接口包含 Get、GetString、GetInt、GetFloat、GetBool、GetDuration、IsSet 7 个方法"
  - "Config 接口嵌入 Reader 并扩展 Load、WithEnvOverride、Validate、Watch"
  - "New(opts ...Option) Config 构造函数可调用"
  - "go build ./... 编译通过"
depends_on:
  - "TASK-CONFIGX-000"
estimated_effort: "1h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description              | Acceptance Criteria                                     |
| ----------- | ------------------------ | ------------------------------------------------------- |
| §9          | Reader / Config 接口定义 | 所有方法签名与 SPEC 一致                                |
| §9.1        | Option 模式              | WithDefaults、WithSchema、WithEnvPrefix、WithStrictMode |

## Test Plan

| Test Case | Type    | Description                          |
| --------- | ------- | ------------------------------------ |
| —         | Compile | 接口完整性编译验证: `go build ./...` |
| —         | Unit    | New() 无参数返回可用 Config          |
| —         | Unit    | Option 组合叠加生效                  |

## Non-scope

- 不实现 Load/Merge/Validate 具体逻辑
- 不包含文件解析代码
- 不处理环境变量

## Implementation Notes

- Reader 是只读接口，Config 扩展 Reader 加入写操作
- `type Option func(*config)`，config 是私有实现结构体
- 默认值在 New() 中设置，Option 在之后应用
- `GetString` 等类型方法内部调用 `Get` 后做类型断言

## Implementation Plan

| Step | Description                                                             | Deliverables | Verification                      |
| ---- | ----------------------------------------------------------------------- | ------------ | --------------------------------- |
| 1    | 定义 `Reader` 接口（7 个方法）                                          | `reader.go`  | `go build ./...` 通过             |
| 2    | 定义 `Config` 接口（嵌入 Reader + Load/WithEnvOverride/Validate/Watch） | `config.go`  | 接口签名与 SPEC §9 一致           |
| 3    | 定义 `Option` 类型和 4 个 Option 函数                                   | `options.go` | `go build ./...` 通过             |
| 4    | 实现 `New(opts ...Option) Config` 构造函数，设置默认值                  | `config.go`  | `go test ./... -run TestNew` 通过 |

### Risk Assessment

| Risk                     | Probability | Impact | Mitigation                       |
| ------------------------ | ----------- | ------ | -------------------------------- |
| 接口方法签名与下游不匹配 | Medium      | High   | 对照 SPEC §9 和上游 configx 确认 |
| Option 函数遗漏          | Low         | Low    | 对照 §9.1 列表                   |
