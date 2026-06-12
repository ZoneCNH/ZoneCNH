# TASK-XLIBGATE-002

> check imports 实现

---

```yaml
task_id: TASK-XLIBGATE-002
module: xlibgate
scope: "实现 check imports 命令：解析依赖矩阵配置，检查 import 路径合规性"
spec_ref:
  - "module/xlibgate/SPEC.md#FR-001"
files:
  - "check_imports.go"
  - "check_imports_test.go"
  - "config.go"
acceptance_criteria:
  - "合规 import：exit 0"
  - "禁止 import：输出违规详情，exit 1"
  - "无 --config：exit 2"
  - "testkitx 边界规则检查"
depends_on:
  - "TASK-XLIBGATE-001"
estimated_effort: "3h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-001 | check imports：依赖矩阵校验 | 4 个 WHEN/THEN 场景 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| TC-001 | Unit | 合规 import：exit 0 |
| TC-002 | Unit | 禁止 import：exit 1 |
| TC-003 | Unit | 无 --config：exit 2 |
| TC-004 | Unit | testkitx 边界规则 |

## Implementation Notes

- 解析 `deps.yaml` 配置文件，定义允许/禁止的 import 路径
- 使用 `go/parser` 和 `go/ast` 解析 Go 源文件
- 遍历所有 `.go` 文件检查 import 声明

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `config.go`：解析 deps.yaml 配置 | `config.go` | `go build ./...` 通过 |
| 2 | 实现 `check_imports.go`：遍历文件 → 解析 import → 检查合规 | `check_imports.go` | TC-001, TC-002 通过 |
| 3 | 实现 testkitx 边界规则检查 | `check_imports.go` | TC-004 通过 |
| 4 | 参数校验和错误处理 | `check_imports.go` | TC-003 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| AST 解析性能 | Low | Medium | 仅解析 import 声明 |
