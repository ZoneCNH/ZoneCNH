# TASK-XLIBGATE-003

> check gomod 实现

---

```yaml
task_id: TASK-XLIBGATE-003
module: xlibgate
scope: "实现 check gomod 命令：运行 go mod tidy 检查 diff"
spec_ref:
  - "module/xlibgate/SPEC.md#FR-002"
files:
  - "check_gomod.go"
  - "check_gomod_test.go"
  - "internal/gomod/parser.go"
acceptance_criteria:
  - "AC-002: go mod tidy 无 diff → pass，exit 0"
  - "AC-002: go mod tidy 有 diff → 输出 diff 详情，exit 1"
  - "AC-002: 无 go.mod → error，exit 2"
depends_on:
  - "TASK-XLIBGATE-001"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-002 | check gomod：go mod tidy diff 检查 | 3 个 WHEN/THEN 场景 |

## Non-scope

- 不实现 go.sum 手动校验（由 go mod tidy 自动处理）
- 不修改 go.mod 内容（只读检查，不自动修复）
- 不实现跨模块 go.mod 版本比较（由 TASK-004 check baseline 负责）
- 不检查 go.mod 中的 replace 指令合法性

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| TC-002 | Unit | go mod tidy 无 diff：exit 0 |
| TC-002 | Unit | go mod tidy 有 diff：exit 1，输出 diff 详情 |
| TC-002 | Unit | 无 go.mod：exit 2 |
| NFR-003 | Benchmark | `BenchmarkCheckGomod` — 50 模块 < 5s |

## Implementation Notes

- 执行 `go mod tidy` 后检查 `git diff go.mod go.sum`
- 使用 `os/exec` 调用外部命令

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `check_gomod.go`：执行 go mod tidy → 检查 diff | `check_gomod.go` | TC-002 全部通过 |
| 2 | 实现 `internal/gomod/parser.go`：go.mod 解析封装 | `internal/gomod/parser.go` | `go build ./...` 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 外部命令依赖 | Low | Low | 检查 go 命令可用性 |
