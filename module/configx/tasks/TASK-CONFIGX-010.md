# TASK-CONFIGX-010

> Security：敏感字段脱敏、配置文件权限检查、环境变量防泄露、日志安全

---

```yaml
task_id: TASK-CONFIGX-010
module: configx
scope: "实现敏感字段自动脱敏、配置文件权限检查、环境变量防泄露、CI secret 扫描"
spec_ref:
  - "module/configx/SPEC.md#19"
  - "module/configx/goal.md#11"
files:
  - "sanitize.go"
  - "sanitize_test.go"
acceptance_criteria:
  - "password/token/secret/key/accessKey/secretKey 字段自动脱敏为 ***"
  - "配置文件权限过宽（> 0o644）时输出 warning"
  - "错误消息中不包含环境变量值"
  - "日志输出不包含明文凭据"
  - "gitleaks detect --no-git 零泄露"
depends_on:
  - "TASK-CONFIGX-006"
estimated_effort: "1.5h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| §19 | 敏感配置不写日志、文件权限检查、环境变量不泄露 | 3 项安全要求 |
| goal §11 | 密码/token/accessKey/secretKey 脱敏，日志不泄露 | 安全快照 + 日志扫描 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | Unit | password 字段脱敏：`Get("db.password")` 返回 `"***"` |
| — | Unit | token 字段脱敏：`Get("api.token")` 返回 `"***"` |
| — | Unit | 普通字段不受影响：`Get("db.host")` 返回原始值 |
| — | Unit | 配置文件权限检查：0o777 文件输出 warning |
| — | Unit | 错误消息不包含环境变量原始值 |
| — | Unit | 嵌套敏感字段：`connections.db.password` 正确脱敏 |
| — | Security | gitleaks 扫描无泄露 |

## Implementation Notes

- 敏感字段匹配规则：`password`, `token`, `secret`, `key`, `accessKey`, `secretKey`, `apiKey`（大小写不敏感）
- 脱敏策略：匹配到敏感字段名时，值替换为 `"***"`（固定长度，不泄露原始长度）
- 嵌套 key 遍历：`connections.db.password` → 递归检查每个路径段 → 最后一段命中 `password` → 脱敏
- 权限检查：`os.Stat(path)` 获取文件 mode → 若 `mode.Perm() & 0o077 != 0`（group/other 有权限） → 输出 warning
- 环境变量防泄露：所有错误消息使用脱敏后的值，不直接引用 `os.Getenv()` 返回值
- 提供 `Reveal(key string) string` 方法供调试使用（需显式调用）

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `isSensitive(key string) bool`：匹配敏感字段名规则 | `sanitize.go` | `go test ./... -run TestIsSensitive` 通过 |
| 2 | 实现 `sanitize(data map[string]interface{}) map[string]interface{}`：递归脱敏 | `sanitize.go` | `go test ./... -run TestSanitize` 通过 |
| 3 | 实现 `checkFilePerm(path string) error`：权限检查和 warning | `sanitize.go` | `go test ./... -run TestFilePerm` 通过 |
| 4 | 实现 `Reveal(key string) string`：调试用原始值查看 | `sanitize.go` | `go test ./... -run TestReveal` 通过 |
| 5 | 集成到 Reader：Get 方法自动调用 sanitize | `reader.go` | 现有 Reader 测试仍通过 |
| 6 | 运行 gitleaks 扫描确认零泄露 | — | `gitleaks detect --no-git` 零泄露 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 脱敏影响性能（递归遍历） | Medium | Medium | 只脱敏最终值，路径匹配 O(n) |
| 敏感字段名遗漏（自定义命名） | Medium | High | 提供 `WithMaskPatterns(...)` Option 扩展 |
| Reveal() 被滥用 | Low | High | 文档标注仅用于调试，CI 扫描 Reveal 调用 |
