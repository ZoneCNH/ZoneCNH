# TASK-XLIB-003D

> PR-4d：API 模板 + examples + testkit — 公共 API 模板和辅助包

---

```yaml
task_id: TASK-XLIB-003D
module: xlib-standard
scope: "实现公共 API 模板、examples/basic、testkit，覆盖 FR-007 和 FR-008"
spec_ref:
  - "module/xlib-standard/SPEC.md#7"
  - "module/xlib-standard/goal.md#7"
  - "module/xlib-standard/goal.md#10"
files:
  - "examples/basic/main.go"
  - "testkit/metrics.go"
  - "testkit/assertions.go"
acceptance_criteria:
  - "AC-020: 模板 go vet 零警告"
  - "AC-021: 模板 go test 全部通过"
depends_on:
  - "TASK-XLIB-003C"
estimated_effort: "0.5h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-007 | 公共 API 模板 | 全部 API 存在 |
| FR-008 | 模板可编译 | go test 通过 |

## Test Plan

```bash
# 1. 编译验证
GOWORK=off go build ./...

# 2. vet 零警告
GOWORK=off go vet ./... 2>&1 | tee /tmp/vet.out
test ! -s /tmp/vet.out  # 无输出 = 零警告

# 3. 全量测试
GOWORK=off go test ./... -v 2>&1 | tee /tmp/test.out
grep -c 'FAIL' /tmp/test.out  # 应为 0

# 4. 竞态检测
GOWORK=off go test -race ./...

# 5. 文件数量验证
test $(ls pkg/templatex/ | wc -l) -eq 11

# 6. example 可运行
GOWORK=off go run examples/basic/main.go
```

## Implementation Notes

1. examples 按 goal.md §10.1 只保留 basic/main.go
2. testkit 按 goal.md §10.2 只保留 metrics.go 和 assertions.go
3. 确保 pkg/templatex/ 总共 11 个文件
