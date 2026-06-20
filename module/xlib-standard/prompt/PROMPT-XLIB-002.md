# Context Packet — TASK-XLIB-002

> PR-3: 骨架代码 — Makefile、scripts、CI
> 工作分支: `feat/xlib-v1-build`
> 工作目录: worktree/xlib-v1-build/

## Current Task

TASK-XLIB-002: 骨架代码 — Makefile、scripts、CI

## Related Spec

- module/xlib_standard/SPEC.md (§11 错误处理, §19 CI Gate, §20 Release DoD)

## Related Requirements

- FR-011: CI 门禁校验
- FR-012: 自动生成校验
- AC-023: spec-lint 检查 SPEC 23 节完整性
- AC-024: task-lint 检查任务格式
- AC-026: trace-lint 检查追溯矩阵一致性
- AC-027: selfcheck-100.sh 运行 100 次无失败

## Current Scope

重写以下构建文件：

1. **Makefile** — 最小目标集：`build`、`test`、`lint`、`generate`、`spec-lint`、`task-lint`、`trace-lint`、`selfcheck`
2. **scripts/spec-lint.sh** — 检查 SPEC.md 23 节完整性
3. **scripts/task-lint.sh** — 检查任务文件格式（必填字段）
4. **scripts/trace-lint.sh** — 检查追溯矩阵一致性（FR↔AC↔TC 映射无断链）
5. **scripts/selfcheck-100.sh** — 运行 100 次 spec-lint + task-lint + trace-lint
6. **.github/workflows/ci.yml** — 最小 CI：lint + test + generate + 验证

## Out of Scope

- 不实现 `pkg/` 包代码（PR-4）
- 不实现 release manifest（PR-5）
- 不修改 `contracts/`、`examples/`、`testkit/`
- 不引入外部 CI actions（仅用 `go test`、`bash`）

## Validation Commands

```bash
# Makefile 目标存在
make -n build && make -n test && make -n lint
make -n spec-lint && make -n task-lint && make -n trace-lint

# 脚本可执行
test -x scripts/spec-lint.sh
test -x scripts/task-lint.sh
test -x scripts/trace-lint.sh
test -x scripts/selfcheck-100.sh

# CI 配置存在
test -f .github/workflows/ci.yml

# spec-lint 对当前 SPEC.md 通过
bash scripts/spec-lint.sh
```

## Required Output

1. 文件变更清单
2. 需求覆盖表
3. 验证结果
4. CI 流程说明

## Evidence Format

完成后提交 evidence 到 `.config/goal/evidence/` 目录，格式如下：

```markdown
- **Evidence ID**: EVID-TEST-TASK-XLIB-002-001
- **Status**: PASS
- **Files Changed**: <实际修改的文件列表>
- **Commands Run**: <实际执行的命令及输出>
```

## Project Rules

- Follow AGENTS.md
- 脚本使用 `#!/usr/bin/env bash` 和 `set -euo pipefail`
- Makefile 使用 `.PHONY` 声明伪目标
- 不引入外部依赖
