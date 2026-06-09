# Context Packet — TASK-XLIB-008

> PR-4d：API 模板 + examples + testkit — 公共 API 模板和辅助包
> 工作分支: `feat/xlib-v1-packages`

## Current Task

TASK-XLIB-008: 公共 API 模板、examples/basic、testkit 辅助包

## Related Spec

- module/xlib-standard/SPEC.md §7 Functional Requirements (FR-007, FR-008)

## Related Requirements

- FR-007: 公共 API 模板 — 全部 API 存在
- FR-008: 模板可编译 — go test 通过
- AC-020, AC-021

## Current Scope

1. **examples/basic/main.go** — 最小可运行示例
2. **testkit/metrics.go** — NoopMetrics 测试辅助
3. **testkit/assertions.go** — 断言函数

## Out of Scope

- 不新增复杂示例、二级模板或业务专用 helper
- 不修改标准错误、配置、health 或 metrics 合约
- 不引入外部测试框架

## Allowed Files

- `examples/basic/main.go`
- `testkit/metrics.go`
- `testkit/assertions.go`

## Prohibited Actions

- 禁止引入新依赖
- 禁止修改 pkg/templatex/
- 禁止添加 examples/ 或 testkit/ 下的其他文件
- 禁止引入 CGO

## Acceptance Criteria

- AC-020: `GOWORK=off go vet ./...` 零警告
- AC-021: `GOWORK=off go test ./...` 全部通过

## Validation Commands

```bash
GOWORK=off go build ./...
GOWORK=off go vet ./... 2>&1 | tee /tmp/vet.out
test ! -s /tmp/vet.out
GOWORK=off go test ./... -v 2>&1 | tee /tmp/test.out
grep -c 'FAIL' /tmp/test.out  # 应为 0
GOWORK=off go test -race ./...
test $(ls pkg/templatex/ | wc -l) -eq 11
GOWORK=off go run examples/basic/main.go
```

## Evidence Format

```markdown
- **Evidence ID**: EVID-TEST-TASK-XLIB-008-001
- **Task ID**: TASK-XLIB-008
- **Status**: PASS/FAIL
- **Validation Run**: <命令及输出>
- **Files Changed**: <文件列表>
- **AC Verified**: AC-020, AC-021
- **Timestamp**: <ISO-8601>
- **Verifier**: <agent/human>
```

## Test Case Reference

参见 `module/xlib-standard/TRACEABILITY.md` FR-007 / FR-008 对应 TC-019。
