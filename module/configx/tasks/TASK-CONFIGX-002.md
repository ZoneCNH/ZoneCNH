# TASK-CONFIGX-002

> 配置加载：YAML/TOML/JSON 解析器、格式自动检测

---

```yaml
task_id: TASK-CONFIGX-002
module: configx
scope: "实现 Load(path) 方法，支持 YAML/TOML/JSON 格式自动检测和解析"
spec_ref:
  - "module/configx/SPEC.md#FR-001"
  - "module/configx/SPEC.md#13"
files:
  - "config.go"
  - "internal/yaml/parser.go"
  - "internal/toml/parser.go"
  - "internal/json/parser.go"
  - "config_test.go"
acceptance_criteria:
  - "Load 存在且有效的 YAML 文件返回 nil"
  - "Load 不存在的文件返回 os.ErrNotExist"
  - "Load 格式无效的文件返回解析错误"
  - ".yaml/.toml/.json 自动检测格式"
depends_on:
  - "TASK-CONFIGX-001"
estimated_effort: "3h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-001 | Load：文件存在有效→nil，不存在→ErrNotExist，格式无效→解析错误 | 3 个 WHEN/THEN 场景 |
| §13 | 空配置文件→使用默认值，只有注释→使用默认值 | 边界场景覆盖 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| TC-001 | Unit | YAML 加载：解析正确，支持嵌套结构 |
| — | Unit | TOML 加载：解析正确 |
| — | Unit | JSON 加载：解析正确 |
| — | Unit | 文件不存在：返回 os.ErrNotExist |
| — | Unit | 格式无效：返回 ErrInvalidFormat |
| — | Unit | 空文件：使用默认值 |
| — | Unit | 格式自动检测：.yaml/.toml/.json 正确选择解析器 |

## Implementation Notes

- 每个解析器在 `internal/` 子包中实现，返回 `map[string]interface{}`
- 格式检测通过文件扩展名（.yaml/.yml, .toml, .json）
- 解析结果存储在 config 结构体的 `data` 字段中
- 空文件和只有注释的文件返回空 map，不报错

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `internal/yaml` 解析器：读取文件 → 解析为 map | `internal/yaml/parser.go` | `go test ./internal/yaml/...` 通过 |
| 2 | 实现 `internal/toml` 和 `internal/json` 解析器 | `internal/toml/`, `internal/json/` | `go test ./internal/...` 通过 |
| 3 | 实现 `Load(path)` 方法：格式检测 → 选择解析器 → 存储结果 | `config.go` | `go test ./... -run TestLoad` 通过 |
| 4 | 编写边界测试：空文件、只有注释、格式无效、文件不存在 | `config_test.go` | 所有边界用例通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| TOML/JSON 解析器依赖引入冲突 | Medium | Medium | 检查 go.mod 依赖兼容性 |
| 嵌套 key 解析不一致 | Low | Medium | 三种格式统一输出 map[string]interface{} |
