# TASK-XLIB-008

> PR-4d：API 模板 + examples + testkit — 公共 API 模板和辅助包

---

```yaml
task_id: TASK-XLIB-008
module: xlib_standard
scope: "实现公共 API 模板、examples/basic、testkit，覆盖 FR-007 和 FR-008"
spec_ref:
  - "module/xlib_standard/SPEC.md#7"
  - "module/xlib_standard/goal.md#7"
  - "module/xlib_standard/goal.md#10"
files:
  - "examples/basic/main.go"
  - "testkit/metrics.go"
  - "testkit/assertions.go"

files_change:
- "examples/basic/main.go"
  - "testkit/metrics.go"
  - "testkit/assertions.go"
acceptance_criteria:
  - "AC-020: 模板 go vet 零警告"
  - "AC-021: 模板 go test 全部通过"
depends_on:
  - "TASK-XLIB-007"
estimated_effort: "0.5h"
priority: P1
status: pending
```

---

## Scope

- 实现 `examples/basic/main.go`。
- 实现 `testkit/metrics.go` 与 `testkit/assertions.go`。
- 验证公共 API 模板可 build、vet、test 和 race。

## Non-scope

- 不新增复杂示例、二级模板或业务专用 helper。
- 不修改标准错误、配置、health 或 metrics 合约。
- 不引入外部测试框架。

## Acceptance

- `GOWORK=off go build ./...` 通过。
- `GOWORK=off go vet ./...` 零警告。
- `GOWORK=off go test ./...` 与 `GOWORK=off go test -race ./...` 通过。

## Requirements Covered

| Requirement | Description   | Acceptance Criteria |
| ----------- | ------------- | ------------------- |
| FR-007      | 公共 API 模板 | 全部 API 存在       |
| FR-008      | 模板可编译    | go test 通过        |

## Test Plan

```bash
# TC-019: 模板 go vet 零警告
GOWORK=off go vet ./... 2>&1 | tee /tmp/vet.out
test ! -s /tmp/vet.out

# TC-020: 模板 go test 全部通过
GOWORK=off go test ./... -v 2>&1 | tee /tmp/test.out
grep -c 'FAIL' /tmp/test.out  # 应为 0

# Race 检测
GOWORK=off go test -race ./...

# 文件数量验证
test $(ls pkg/templatex/ | wc -l) -eq 11

# Example 可运行
GOWORK=off go run examples/basic/main.go
```

## Implementation Notes

1. examples 按 goal.md §10.1 只保留 basic/main.go
2. testkit 按 goal.md §10.2 只保留 metrics.go 和 assertions.go
3. 确保 pkg/templatex/ 总共 11 个文件
