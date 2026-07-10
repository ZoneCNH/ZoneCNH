# Sol/Luna 编排改进追溯矩阵

[COMPUTED, HIGH] 本矩阵把 `SPEC.md` 的 FR、AC、Task、实现路径和验证证据闭合；最终命令结果记录在 `evidence/2026-07-10/test/VALIDATION.md`。

| FR | AC | Task | 实现 | 验证 |
|----|----|------|------|------|
| FR-001 | AC-001 | TASK-003 | `.codex/config.toml` | `codex --strict-config doctor --json` |
| FR-002 | AC-002, AC-003, AC-007 | TASK-001 | Sol plan schema、`ThreadPoolExecutor`、显式模型参数 | probe、unit、E2E smoke |
| FR-003 | AC-003, AC-006 | TASK-001 | scope 校验、primary-root runtime worktree | unit、受保护路径检查 |
| FR-004 | AC-003, AC-005 | TASK-001, TASK-002 | `_batch_details`、task/integration retry、`_sol_escalation` | unit |
| FR-005 | AC-004, AC-007 | TASK-001, TASK-002 | `_integration_repair`、combined patch | unit、E2E smoke |
| FR-006 | AC-004 | TASK-001, TASK-002 | `_workspace_info`、`_assert_parent_unchanged` | unit |
| FR-007 | AC-002, AC-003, AC-007 | TASK-001 | `.omx/state/orchestration/<run_id>/` 证据包 | probe、unit、E2E smoke |
| FR-001–FR-007 | AC-008 | TASK-003 | `AGENTS.md`、`docs/workflow/README.md`、本目录 | `git diff --check`、人工可读审查 |

[COMPUTED, HIGH] 没有 FR 仅映射到文档而缺少实现或验证命令。
