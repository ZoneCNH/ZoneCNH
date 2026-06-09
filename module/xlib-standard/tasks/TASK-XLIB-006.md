# TASK-XLIB-006

> PR-4b：Error + Client 标准 — pkg/templatex/errors.go + client.go

---

```yaml
task_id: TASK-XLIB-006
module: xlib-standard
scope: "实现 ErrorKind 8 种、Error 结构体、Client New/Close，覆盖 FR-002 和 FR-005"
spec_ref:
  - "module/xlib-standard/SPEC.md#7"
  - "module/xlib-standard/SPEC.md#9"
  - "module/xlib-standard/SPEC.md#10"
  - "module/xlib-standard/SPEC.md#12"
  - "module/xlib-standard/goal.md#7"
  - "module/xlib-standard/goal.md#8"
  - "module/xlib-standard/goal.md#9"
files:
  - "pkg/templatex/errors.go"
  - "pkg/templatex/errors_test.go"
  - "pkg/templatex/client.go"
  - "pkg/templatex/client_test.go"
  - "contracts/errors.schema.json"

files_change:
- "pkg/templatex/errors.go"
  - "pkg/templatex/errors_test.go"
  - "pkg/templatex/client.go"
  - "pkg/templatex/client_test.go"
  - "contracts/errors.schema.json"
acceptance_criteria:
  - "AC-004: NewError 创建 Error 字段正确"
  - "AC-005: WrapError 包装 errors.Is 可穿透"
  - "AC-006: IsKind 匹配返回 true"
  - "AC-007: context.DeadlineExceeded ErrorKind = timeout"
  - "AC-008: closed error ErrorKind = closed"
  - "AC-014: New nil context 返回错误"
  - "AC-015: New canceled context 返回错误"
  - "AC-016: New 无效 config 返回错误"
  - "AC-017: New 正常创建返回 *Client"
  - "AC-018: Close 幂等多次调用不 panic"
depends_on:
  - "TASK-XLIB-003"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Scope

- 实现 `pkg/templatex/errors.go` 的 ErrorKind、Error、NewError、WrapError、IsKind。
- 实现 `pkg/templatex/client.go` 的 New 和 Close。
- 更新 `contracts/errors.schema.json`。

## Non-scope

- 不实现 Health、Metrics、render template 或 release manifest。
- 不新增超出 8 类 ErrorKind 的错误分类。
- 不引入具体业务客户端、网络连接或后台 goroutine。

## Acceptance

- Error 创建、包装、errors.Is 穿透和 kind 匹配全部通过测试。
- deadline、closed、nil context、canceled context 与 invalid config 均映射到标准错误。
- Close 可重复调用且不会 panic。

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-002 | Error 标准 | 8 种 ErrorKind |
| FR-005 | Client 标准 | New/Close 存在 |
| §9 | Interface Contract | 接口定义正确 |
| §10 | Data Model | ErrorKind 正确 |
| §12 | Error Handling | 8 个错误变量 |

## Test Plan

```bash
# TC-004: NewError 创建 Error 字段正确
GOWORK=off go test ./pkg/templatex/ -run TestNewError -v

# TC-005: WrapError 包装 errors.Is 可穿透
GOWORK=off go test ./pkg/templatex/ -run TestWrapError -v

# TC-006: IsKind 匹配返回 true
GOWORK=off go test ./pkg/templatex/ -run TestIsKind -v

# TC-007: deadline cause → timeout kind
GOWORK=off go test ./pkg/templatex/ -run TestErrorDeadline -v

# TC-008: closed cause → closed kind
GOWORK=off go test ./pkg/templatex/ -run TestErrorClosed -v

# TC-014~018: Client New/Close
GOWORK=off go test ./pkg/templatex/ -run TestClient -v

# Race 检测
GOWORK=off go test -race ./pkg/templatex/

# Contract 验证
grep -c "validation" contracts/errors.schema.json
grep -c "conflict" contracts/errors.schema.json
```

## Implementation Notes

1. ErrorKind 按 goal.md §7.4 只有 8 种
2. Client 按 goal.md §7.5 实现 New/Close
3. contracts/errors.schema.json 按 goal.md §8 更新
