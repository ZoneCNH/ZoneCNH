# TASK-XLIBGATE-002

> check imports 实现

---

```yaml
task_id: TASK-XLIBGATE-002
module: xlibgate
scope: "实现 check imports 命令：解析依赖矩阵配置，检查 import 路径合规性"
spec_ref:
  - "module/xlibgate/SPEC.md#FR-001"
  - "module/xlibgate/SPEC.md#BR-002"
  - "module/xlibgate/SPEC.md#BR-008"
  - "module/xlibgate/SPEC.md#BR-009"
files:
  - "check_imports.go"
  - "check_imports_test.go"
  - "config.go"
  - "internal/scan/imports/imports.go"
  - "internal/ast/parser.go"
acceptance_criteria:
  - "AC-001: 合规 import → exit 0，输出 pass"
  - "AC-001: 禁止 import → exit 1，输出违规详情（文件路径、行号、违规 import 路径）"
  - "AC-001: 无 --config → exit 2"
  - "AC-008: FOUNDATION-DEPS.yaml 解析正确，无效 yaml → ErrConfigInvalid"
  - "BR-002: testkitx 边界规则检查（生产包不得 import testkitx）"
depends_on:
  - "TASK-XLIBGATE-001"
estimated_effort: "3h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description                                       | Acceptance Criteria     |
| ----------- | ------------------------------------------------- | ----------------------- |
| FR-001      | check imports：依赖矩阵校验                       | 4 个 WHEN/THEN 场景     |
| BR-002      | import 规则从 deps.yaml 读取，不硬编码            | --config 参数覆盖       |
| BR-008      | human-readable 输出含文件路径和行号               | 违规输出含位置信息      |
| BR-009      | FOUNDATION-DEPS.yaml schema 与 xlib_standard 一致 | YAML 解析 + schema 校验 |

## Non-scope

- 不实现 gitleaks 集成（由 TASK-006 check all 负责，BR-005）
- 不实现 go.mod tidy 检查（由 TASK-003 负责）
- 不实现配置文件热更新
- 不处理非 Go 源文件的 import 检查

## Test Plan

| Test Case | Type      | Description                                      |
| --------- | --------- | ------------------------------------------------ |
| TC-001    | Unit      | 合规 import：exit 0                              |
| TC-001    | Unit      | 禁止 import：exit 1（含文件路径、行号）          |
| TC-001    | Unit      | 无 --config：exit 2                              |
| TC-001    | Unit      | testkitx 边界规则：生产包 import testkitx → fail |
| NFR-002   | Benchmark | `BenchmarkCheckImports` — 50 模块 < 10s          |

## Implementation Notes

- 解析 `deps.yaml` 配置文件，定义允许/禁止的 import 路径
- 使用 `go/parser` 和 `go/ast` 解析 Go 源文件
- 遍历所有 `.go` 文件检查 import 声明
- BR-002 要求 import 规则从配置文件读取，不硬编码 DefaultForbiddenModules

## Implementation Plan

| Step | Description                                                | Deliverables                                                 | Verification          |
| ---- | ---------------------------------------------------------- | ------------------------------------------------------------ | --------------------- |
| 1    | 实现 `config.go`：解析 deps.yaml 配置                      | `config.go`                                                  | `go build ./...` 通过 |
| 2    | 实现 `check_imports.go`：遍历文件 → 解析 import → 检查合规 | `check_imports.go`                                           | TC-001 通过           |
| 3    | 实现 testkitx 边界规则检查                                 | `check_imports.go`                                           | TC-001 通过           |
| 4    | 参数校验和错误处理                                         | `check_imports.go`                                           | TC-001 通过           |
| 5    | 实现 internal/scan/imports/*.go 和 internal/ast/*.go       | `internal/scan/imports/imports.go`, `internal/ast/parser.go` | `go build ./...` 通过 |

### Risk Assessment

| Risk         | Probability | Impact | Mitigation         |
| ------------ | ----------- | ------ | ------------------ |
| AST 解析性能 | Low         | Medium | 仅解析 import 声明 |
