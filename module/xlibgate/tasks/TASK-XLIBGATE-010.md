# TASK-XLIBGATE-010

> trust 子命令框架 + 统一 JSON 输出

---

```yaml
task_id: TASK-XLIBGATE-010
module: xlibgate
scope: "实现 trust 父命令注册、统一 JSON 输出 schema、reason_code 枚举定义"
spec_ref:
  - "module/xlibgate/spec/SPEC.md#FR-006"
  - "module/xlibgate/spec/SPEC.md#9.3.1 Trust Alignment 统一输出格式"
  - "module/xlibgate/spec/SPEC.md#BR-007"
files:
  - "cmd/trust.go"
  - "scanner/trust/common.go"
acceptance_criteria:
  - "AC-010: xlibgate trust --help 输出 8 子命令列表"
  - "AC-010: 所有 trust 子命令输出统一 JSON 格式 {check, repo, status, severity, findings, reason_code, evidence}"
  - "AC-010: reason_code 10 值枚举定义完整"
depends_on: []
estimated_effort: "1h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description                                     |
| ----------- | ----------------------------------------------- |
| FR-006      | 输出格式：JSON 包含 status、checks[]、summary   |
| §9.3.1      | Trust Alignment 统一输出格式                    |
| BR-007      | JSON 输出含 machine-readable status 字段        |

## Non-scope

- 不实现具体 trust 检查逻辑（由 TASK-011~018 负责）
- 不修改 check/l2 子命令

## Implementation Plan

| Step | Description                                  | Deliverables                 | Verification                    |
| ---- | -------------------------------------------- | ---------------------------- | ------------------------------- |
| 1    | 注册 trust 父命令到 cmd/root.go              | cmd/trust.go                 | `xlibgate trust --help` 输出    |
| 2    | 定义 reason_code 枚举和统一 JSON schema      | scanner/trust/common.go      | `go build ./...` 通过           |
| 3    | 实现 TrustResult 结构体和 MarshalJSON        | scanner/trust/common.go      | JSON 输出含全部必需字段         |
