# Context Packet — TASK-XLIBGATE-016

> trust testkit-prod-import：testkitx 生产隔离检查
> 来源：SPEC.md v1.1.1 FR-017, TC-024, TC-025

## Current Task

TASK-XLIBGATE-016: 实现 trust testkit-prod-import 命令，检测生产代码中的 testkitx import

## Related Spec

- module/xlibgate/SPEC.md FR-017 (trust testkit-prod-import)
- module/xlibgate/SPEC.md TC-024 (pass), TC-025 (violation)

## Current Scope

| Deliverable | Description |
|-------------|-------------|
| cmd/trust_testkit.go | CLI 命令入口，--repo, --strict 参数 |
| scanner/trust/testkit.go | 路径分类 + import 检测 |

### 路径分类规则

| 路径模式 | 判定 |
|----------|------|
| pkg/ | 生产代码 |
| internal/ | 生产代码（--strict 含子目录） |
| internal/test* | 允许 |
| cmd/ (生产二进制) | 生产代码 |
| cmd/test* | 允许 |
| *_test.go | 允许 |
| test/ | 允许 |
| testkit/ | 允许 |
| examples/ | 允许 |

## Non-Scope

- 不检查 go.mod 中的 testkitx 依赖
- testkitx 自身仓库自动跳过

## Acceptance Criteria

- TC-024: test 文件有 testkitx 但生产代码无 → exit 0
- TC-025: pkg/ 中 import testkitx → exit 1, TESTKIT_PROD_IMPORT
- --strict 模式：internal/ 非 test 子目录 → 视为生产代码

## Constraints

- 使用 go/parser + go/ast 解析 import
- 统一 JSON 输出
- Edge case: testkitx 自身仓库跳过（testkitx 允许引用自身）

## Verification

```bash
xlibgate trust testkit-prod-import --repo testdata/trust-pass 2>&1; [ $? -eq 0 ]
xlibgate trust testkit-prod-import --repo testdata/trust-bad-testkit 2>&1; [ $? -eq 1 ]
```
