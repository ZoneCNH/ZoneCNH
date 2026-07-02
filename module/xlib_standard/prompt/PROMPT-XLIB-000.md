# Context Packet — TASK-XLIB-000

> PR-1: 删除治理运行时与冗余目录
> 工作分支: `feat/xlib-v1-prune`
> 工作目录: /home/workspace/xlib_standard/.worktree/workspaces/feat/xlib-v1-prune

## Current Task

TASK-XLIB-000: 删除治理运行时与冗余目录

## Related Spec

- module/xlib_standard/SPEC.md (§14 目录结构)

## Related Requirements

- FR-013: 发布制品与版本管理
- AC-025: release 目录仅含 manifest 和兼容性矩阵

## Current Scope

删除以下文件和目录：

| 类型   | 目标                                                                                  |
| ------ | ------------------------------------------------------------------------------------- |
| 目录   | `.agent/`, `.codex/`, `.devcontainer/`, `.githooks/`, `.omx/`, `.worktree/`, `.xlib/` |
| 目录   | `cmd/`, `mk/`, `release/debt/`, `templates/l2/`                                       |
| 文件   | `.dockerignore`, `Dockerfile`, `docker-compose.yml`                                   |
| 文件   | `AGENTS.md`, `CLAUDE.md`, `CONSTITUTION.md`, `releasemanifest`, `renovate.json`       |
| 目录   | `docs/goal/`, `docs/adr/`                                                             |

## Out of Scope

- 不删除 `pkg/`、`contracts/`、`examples/`、`testkit/`
- 不删除 `scripts/`、`.github/`、`Makefile`
- 不删除 `docs/` 中保留的 9 个文件
- 不修改任何文件内容，只做删除

## Validation Commands

```bash
# 验证目标已删除
test ! -d .agent && test ! -d .codex && test ! -d .devcontainer && echo "dirs deleted"
test ! -f Dockerfile && test ! -f docker-compose.yml && echo "docker files deleted"
test ! -f AGENTS.md && test ! -f CLAUDE.md && echo "agent files deleted"

# 验证保留目录存在
test -d pkg && test -d contracts && test -d examples && test -d testkit && echo "core dirs preserved"
test -d scripts && test -d .github && echo "build dirs preserved"
test -f Makefile && echo "Makefile preserved"
```

## Required Output

1. 文件变更清单（删除了什么）
2. 验证结果
3. 风险评估

## Evidence Format

完成后提交 evidence 到 `.config/goal/evidence/` 目录，格式如下：

```markdown
- **Evidence ID**: EVID-TEST-TASK-XLIB-000-001
- **Status**: PASS
- **Files Changed**: <实际删除的文件列表>
- **Commands Run**: <验证命令及输出>
```

## Project Rules

- Follow AGENTS.md
- 只删除，不修改
- 删除前确认目标文件/目录存在
- 不引入新依赖

## Test Case Reference

参见 `module/xlib_standard/TRACEABILITY.md`。本 task 为治理清理，无特定 TC，验证通过目录删除和 git status 确认。
