# TASK-OBSERVEX-006

> Redaction：secret 字段自动脱敏、文本扫描

---

```yaml
task_id: TASK-OBSERVEX-006
module: observex
scope: "实现日志/metrics 脱敏策略，自动识别 secret 字段并替换为 ***"
spec_ref:
  - "module/observex/SPEC.md#FR-005"
  - "module/observex/SPEC.md#BR-007"
  - "module/observex/SPEC.md#19"
files:
  - "redact.go"
  - "redact_test.go"
acceptance_criteria:
  - "secret 字段值被替换为 ***"
  - "redact.Check 检测文本中的泄露 secret"
  - "支持 password/token/api_key 等模式"
depends_on:
  - "TASK-OBSERVEX-002"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Non-scope

- 不涉及本 Task 范围外的功能

## Requirements Covered

| Requirement | Description                                 | Acceptance Criteria                       |
| ----------- | ------------------------------------------- | ----------------------------------------- |
| FR-005      | Redaction：secret 模式匹配→替换，Check 扫描 | 2 个 WHEN/THEN 场景                       |
| BR-007      | 日志中 secret 字段必须自动脱敏              | 自动匹配并替换                            |
| §19         | secret 识别模式                             | 正则匹配 password/secret/token/api_key 等 |

## Test Plan

| Test Case | Type | Description                                              |
| --------- | ---- | -------------------------------------------------------- |
| TC-005    | Unit | Redaction 脱敏：secret/token/password 字段值被替换为 *** |
| —         | Unit | Check 扫描：检测文本中的泄露 secret                      |
| —         | Unit | 非 secret 字段不被脱敏                                   |
| —         | Unit | 嵌套 map 中的 secret 字段被脱敏                          |

## Implementation Notes

- secret 识别正则：`(?i)(password|passwd|secret|token|api[_-]?key|access[_-]?key|private[_-]?key|credential|auth)`
- `Redact(fields []Field) []Field` 遍历 fields，匹配 key 则替换 value
- `Check(input string) []string` 扫描文本，返回匹配的 secret 位置
- 脱敏在 Logger 输出前自动执行

## Implementation Plan

| Step | Description                                                       | Deliverables     | Verification                        |
| ---- | ----------------------------------------------------------------- | ---------------- | ----------------------------------- |
| 1    | 定义 secret 识别正则模式                                          | `redact.go`      | 正则编译正确                        |
| 2    | 实现 `Redact(fields)` 遍历 fields，匹配 key 则替换 value 为 `***` | `redact.go`      | TC-005 通过                         |
| 3    | 实现 `Check(input)` 扫描文本，返回匹配的 secret 位置              | `redact.go`      | `go test ./... -run TestCheck` 通过 |
| 4    | 集成到 Logger：输出前自动调用 Redact                              | `logger/impl.go` | 日志中 secret 字段被脱敏            |

### Risk Assessment

| Risk       | Probability | Impact | Mitigation                 |
| ---------- | ----------- | ------ | -------------------------- |
| 正则误匹配 | Low         | Medium | 仅匹配字段名，不匹配值内容 |
| 性能影响   | Low         | Low    | 正则预编译，仅在输出时执行 |
