# TASK-XLIB-003

> PR-4a：Config 标准 — pkg/templatex/config.go

---

```yaml
task_id: TASK-XLIB-003
module: xlib_standard
scope: "实现 Config 结构体、Validate、Sanitize，覆盖 FR-001 和 Version API"
spec_ref:
  - "module/xlib_standard/spec/SPEC.md#7"
  - "module/xlib_standard/goal/goal.md#7"
files:
  - "pkg/templatex/doc.go"
  - "pkg/templatex/config.go"
  - "pkg/templatex/config_test.go"

files_change:
- "pkg/templatex/doc.go"
  - "pkg/templatex/config.go"
  - "pkg/templatex/config_test.go"
acceptance_criteria:
  - "AC-001: Config 必填字段缺失返回 ErrorKindValidation"
  - "AC-002: 负数 timeout 返回 ErrorKindValidation"
  - "AC-003: Sanitize 脱敏 secret 替换为 `***`"
  - "AC-019: 版本信息返回 module path/version/commit/build time"
depends_on:
  - "TASK-XLIB-000"
  - "TASK-XLIB-001"
estimated_effort: "1.5h"
priority: P0
status: pending
```

---

## Scope

- 实现 `pkg/templatex/config.go` 的 Config、Validate、Sanitize。
- 实现 `pkg/templatex/doc.go` 与版本 API。
- 覆盖 FR-001 和 FR-006 的最小公共接口。

## Non-scope

- 不实现 Client、Error、Health 或 Metrics 标准。
- 不新增运行时配置发现、环境变量加载或 secret 管理器。
- 不修改生成脚本和 release gate。

## Acceptance

- Config 必填字段缺失和负数 timeout 返回 validation 类错误。
- Sanitize 对 secret 值输出 `***`。
- 版本 API 返回 module path、version、commit 与 build time。

## Requirements Covered

| Requirement | Description  | Acceptance Criteria           |
| ----------- | ------------ | ----------------------------- |
| FR-001      | Config 标准  | Config/Validate/Sanitize 存在 |
| FR-006      | Version 标准 | 版本信息返回正确              |

## Test Plan

```bash
# TC-001: Config 必填字段缺失返回 validation kind
GOWORK=off go test ./pkg/templatex/ -run TestConfigValidate -v

# TC-002: 负数 timeout 返回 validation kind
GOWORK=off go test ./pkg/templatex/ -run TestConfigNegativeTimeout -v

# TC-003: Sanitize 脱敏 secret 替换为 ***
GOWORK=off go test ./pkg/templatex/ -run TestConfigSanitize -v

# TC-019: 版本信息返回正确字段
GOWORK=off go test ./pkg/templatex/ -run TestVersion -v

# Race 检测
GOWORK=off go test -race ./pkg/templatex/

# 编译验证
GOWORK=off go build ./pkg/templatex/
```

## Implementation Notes

1. Config 按 goal.md §7.3 实现（显式传入、Validate、Sanitize）
2. Version 按 goal.md §7.7 实现
3. doc.go 包含 package-level 文档
