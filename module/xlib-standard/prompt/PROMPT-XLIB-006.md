# Context Packet — TASK-XLIB-006

> PR-4b：Error + Client 标准 — pkg/templatex/errors.go + client.go
> 工作分支: `feat/xlib-v1-packages`

## Current Task

TASK-XLIB-006: ErrorKind 9 种、Error 结构体、Client New/Close

## Related Spec

- module/xlib-standard/SPEC.md §7 Functional Requirements, §9 Interfaces, §10 Data Model, §12 Error Handling

## Related Requirements

- FR-002: Error 标准 — 9 种 ErrorKind
- FR-005: Client 标准 — New/Close 存在
- AC-004~AC-008, AC-014~AC-018

## Current Scope

1. **pkg/templatex/errors.go** — ErrorKind、Error、NewError、WrapError、IsKind
2. **pkg/templatex/errors_test.go** — 完整测试
3. **pkg/templatex/client.go** — New、Close
4. **pkg/templatex/client_test.go** — 完整测试
5. **contracts/errors.schema.json** — 错误契约

## Out of Scope

- 不实现 Health、Metrics、render template 或 release manifest
- 不新增超出 9 类 ErrorKind 的错误分类
- 不引入具体业务客户端、网络连接或后台 goroutine

## Allowed Files

- `pkg/templatex/errors.go`
- `pkg/templatex/errors_test.go`
- `pkg/templatex/client.go`
- `pkg/templatex/client_test.go`
- `contracts/errors.schema.json`

## Prohibited Actions

- 禁止引入新依赖
- 禁止修改 health.go / metrics.go / config.go
- 禁止新增超过 9 种 ErrorKind

## Acceptance Criteria

- AC-004: NewError 创建 Error 字段正确
- AC-005: WrapError 包装 errors.Is 可穿透
- AC-006: IsKind 匹配返回 true
- AC-007: context.DeadlineExceeded ErrorKind = timeout
- AC-008: closed error ErrorKind = closed
- AC-014: New nil context 返回错误
- AC-015: New canceled context 返回错误
- AC-016: New 无效 config 返回错误
- AC-017: New 正常创建返回 *Client
- AC-018: Close 幂等多次调用不 panic

## Validation Commands

```bash
GOWORK=off go test ./pkg/templatex/ -run TestError -v
GOWORK=off go test ./pkg/templatex/ -run TestClient -v
GOWORK=off go test -race ./pkg/templatex/
grep -c "validation" contracts/errors.schema.json
grep -c "conflict" contracts/errors.schema.json
```

## Evidence Format

```markdown
- **Evidence ID**: EVID-TEST-TASK-XLIB-006-001
- **Task ID**: TASK-XLIB-006
- **Status**: PASS/FAIL
- **Validation Run**: <命令及输出>
- **Files Changed**: <文件列表>
- **AC Verified**: AC-004~AC-008, AC-014~AC-018
- **Timestamp**: <ISO-8601>
- **Verifier**: <agent/human>
```

## Test Case Reference

参见 `module/xlib-standard/TRACEABILITY.md` FR-002 / FR-005 对应 TC-004~TC-008, TC-014~TC-018。
