# TASK-XLIB-000

> PR-1：删除治理运行时与冗余目录

---

```yaml
task_id: TASK-XLIB-000
module: xlib_standard
scope: "删除 governance-runtime、evidence-runtime、debt-governance、adrs、internal 等非目标目录和文件"
spec_ref:
  - "module/xlib_standard/SPEC.md#5"
  - "module/xlib_standard/goal.md#4"
files:
  - ".agent/ (删除)"
  - ".codex/ (删除)"
  - ".devcontainer/ (删除)"
  - ".githooks/ (删除)"
  - ".omx/ (删除)"
  - ".worktree/ (删除)"
  - ".xlib/ (删除)"
  - "cmd/ (删除)"
  - "mk/ (删除)"
  - "release/debt/ (删除)"
  - "templates/l2/ (删除)"
  - ".dockerignore (删除)"
  - "Dockerfile (删除)"
  - "docker-compose.yml (删除)"
  - "AGENTS.md (删除)"
  - "CLAUDE.md (删除)"
  - "CONSTITUTION.md (删除)"
  - "releasemanifest (删除)"
  - "renovate.json (删除)"
  - "docs/goal/ (删除)"
  - "docs/adr/ (删除)"

files_change:
- ".agent/ (删除)"
  - ".codex/ (删除)"
  - ".devcontainer/ (删除)"
  - ".githooks/ (删除)"
  - ".omx/ (删除)"
  - ".worktree/ (删除)"
  - ".xlib/ (删除)"
  - "cmd/ (删除)"
  - "mk/ (删除)"
  - "release/debt/ (删除)"
  - "templates/l2/ (删除)"
  - ".dockerignore (删除)"
  - "Dockerfile (删除)"
  - "docker-compose.yml (删除)"
  - "AGENTS.md (删除)"
  - "CLAUDE.md (删除)"
  - "CONSTITUTION.md (删除)"
  - "releasemanifest (删除)"
  - "renovate.json (删除)"
  - "docs/goal/ (删除)"
  - "docs/adr/ (删除)"
acceptance_criteria:
  - "AC-001: test ! -e .agent && test ! -e cmd && test ! -e Dockerfile"
  - "AC-002: test ! -e docker-compose.yml && test ! -e templates/l2"
  - "AC-003: test ! -e docs/goal && test ! -e docs/adr"
  - "AC-004: GOWORK=off go test ./... 通过"
depends_on: []
estimated_effort: "0.5h"
priority: P0
status: pending
```

---

## Scope

- 删除 xlib_standard 目标边界之外的治理运行时、agent runtime、债务治理、Docker 与历史模板目录。
- 保留 `README.md`、`docs/`、`templates/`、`scripts/`、`contracts/`、`pkg/templatex/` 等标准库交付所需资产。
- 更新残留引用，使公开文档只描述 xlib_standard 标准库职责。

## Non-scope

- 不实现业务运行时、Goal Runtime 或 Debt Governance。
- Evidence Runtime（release manifest 与发布证据生成）是五类职责之一，属于本模块范围，见 goal.md 五角色定义。
- 不引入新的脚本依赖、包管理器或外部服务。
- 不修改本任务未列出的模块仓库。

## Acceptance

- 不再存在 `.agent`、`.codex`、`.omx`、`cmd`、`templates/l2`、`docs/goal`、`docs/adr` 等非目标目录。
- `GOWORK=off go test ./...` 通过。
- `README.md` 不再引用已删除目录。

## Requirements Covered

| Requirement  | Description                         | Acceptance Criteria |
| ------------ | ----------------------------------- | ------------------- |
| §5 Non-goals | 不做 Goal Runtime / Debt Governance | 相关目录不存在      |
| goal.md §4   | PR-1 删除命令                       | 目录删除 + 测试通过 |

## Test Plan

```bash
# 验收命令
test ! -e .agent
test ! -e cmd
test ! -e Dockerfile
test ! -e docker-compose.yml
test ! -e templates/l2
test ! -e docs/goal
test ! -e docs/adr
GOWORK=off go test ./...
```

## Implementation Notes

1. 执行 goal.md §4.1 的删除命令
2. 执行 goal.md §4.2 的验收命令
3. 确保 README.md 不再引用已删目录
