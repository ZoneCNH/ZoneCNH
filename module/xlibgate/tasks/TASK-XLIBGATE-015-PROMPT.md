# Context Packet — TASK-XLIBGATE-015

> trust import-boundary：FOUNDATION-DEPS.yaml 驱动的 import 边界检查
> 来源：SPEC.md v1.1.1 FR-016, TC-022, TC-023

## Current Task

TASK-XLIBGATE-015: 实现 trust import-boundary 命令，消费 FOUNDATION-DEPS.yaml

## Related Spec

- module/xlibgate/SPEC.md FR-016 (trust import-boundary)
- module/xlibgate/SPEC.md TC-022 (pass), TC-023 (violation)

## Current Scope

| Deliverable | Description |
|-------------|-------------|
| cmd/trust_boundary.go | CLI 命令入口，--repo, --deps 参数 |
| scanner/trust/boundary.go | import 边界扫描逻辑 |

### 检查规则

- 解析 FOUNDATION-DEPS.yaml 的 `allowed_deps` 和 `forbidden_foundation_edges`
- 使用 `go/parser` + `go/ast` 解析源码 import 声明
- kernel 特殊检查：导入非 stdlib → 标记 kernel_stdlib_violation

### Exit Code

| 场景 | Exit | reason_code |
|------|------|-------------|
| 所有 import 合规 | 0 | "" |
| 违反 forbidden edge | 1 | IMPORT_BOUNDARY_VIOLATION |
| kernel 导入非 stdlib | 1 | IMPORT_BOUNDARY_VIOLATION |
| FOUNDATION-DEPS.yaml 缺失 | 2 | CONTRACT_PARSE_ERROR |

## Non-Scope

- 不实现 check imports 的 deps.yaml 逻辑（check 版独立）
- 不解析间接依赖图

## Acceptance Criteria

- TC-022: import 合规 → exit 0
- TC-023: binance import kernel → exit 1, IMPORT_BOUNDARY_VIOLATION
- kernel stdlib-only 违规 → kernel_stdlib_violation
- FOUNDATION-DEPS.yaml 缺失 → exit 2, CONTRACT_PARSE_ERROR

## Constraints

- FOUNDATION-DEPS.yaml schema 与 xlib-standard 一致（BR-009）
- findings 含文件路径、行号、违规 import 路径、违反的规则
- 统一 JSON 输出

## Verification

```bash
xlibgate trust import-boundary --repo testdata/trust-pass --deps FOUNDATION-DEPS.yaml 2>&1; [ $? -eq 0 ]
xlibgate trust import-boundary --repo testdata/trust-bad-boundary --deps FOUNDATION-DEPS.yaml 2>&1; [ $? -eq 1 ]
```
