# Codex Agents

FoundationX 文档仓库的 Codex 代理配置。Codex 是三大 LLM scorer 之一；默认运行时状态写入 `.omx/state/...`。

## 执行类代理

| Agent          | 模型    | reasoning   | 职责                                    |
| -------------- | ------- | ----------- | --------------------------------------- |
| spec → 见 goal-spec           | gpt-5.5 | high        | 编写或修订模块 Spec（已合并到 goal-spec）                     |
| spec-review    | gpt-5.5 | high        | 对抗性审查 spec，作为结构评分证据与参考 |
| matrix → 见 goal-matrix         | gpt-5.5 | high        | 生成或校验需求追溯矩阵（已合并到 goal-matrix）                  |
| task-split → 见 goal-planner     | gpt-5.5 | high        | 将 Approved Spec 拆分为可执行的 Task（已合并到 goal-planner）    |
| task-planner → 见 goal-planner   | gpt-5.5 | high        | 为单个 TASK 生成实现计划（已合并到 goal-planner）                |
| prompt-builder → 见 goal-prompt-builder | gpt-5.5 | medium      | 为单个 Task 生成 Context Packet（已合并到 goal-prompt-builder）         |
| task-executor  | gpt-5.5 | high        | 按 Task spec 编写代码                   |

## 评分类代理（Codex 平台）

| Agent                   | 阶段   | Rubric                                     |
| ----------------------- | ------ | ------------------------------------------ |
| spec-structural-score   | Spec   | `docs/governance/scoring/RUBRIC-spec.md`   |
| matrix-structural-score | Matrix | `docs/governance/scoring/RUBRIC-matrix.md` |
| tasks-structural-score  | Tasks  | `docs/governance/scoring/RUBRIC-tasks.md`  |
| plan-structural-score   | Plan   | `docs/governance/scoring/RUBRIC-plan.md`   |
| prompt-structural-score | Prompt | `docs/governance/scoring/RUBRIC-prompt.md` |
| code-structural-score   | Code   | `docs/governance/scoring/RUBRIC-code.md`   |

## 仲裁类代理

| Agent            | 用途                                                                                                   |
| ---------------- | ------------------------------------------------------------------------------------------------------ |
| pipeline-arbiter | 汇总四源评分，按 `docs/governance/scoring/ARBITER-PROTOCOL.md` 输出 gate 判定                          |
| meta-arbiter     | 读 `.omx/state/outer-metrics/`，按宪法 §14.4 诊断 Goodhart 信号、输出 RSI 建议（不修改任何受保护文件） |

所有评分与仲裁 agent 均使用 `gpt-5.5` 模型 + `high` reasoning。

## Goal Delivery OS Agent 投影

| Agent                  | 模型    | reasoning | 职责                                       |
| ---------------------- | ------- | --------- | ------------------------------------------ |
| goal-spec              | gpt-5.5 | high      | Goal/Spec/Design/Plan/Task 编写，Registry 注册 |
| goal-architect         | gpt-5.5 | high      | 架构设计，生成 Design 文档和 ADR           |
| goal-planner           | gpt-5.5 | high      | 将 Spec 拆分为原子任务，生成执行计划       |
| goal-matrix            | gpt-5.5 | high      | 追溯矩阵生成与维护                         |
| goal-prompt-builder    | gpt-5.5 | high      | Context Package 构建与版本管理             |
| goal-evidence          | gpt-5.5 | high      | 证据收集与验证                             |
| goal-reviewer          | gpt-5.5 | high      | G0-G11 对抗性审查，Gate 状态记录           |
| goal-governance        | gpt-5.5 | high      | SSOT 一致性审计、漂移检测                  |
| goal-lint              | gpt-5.5 | high      | Lint 规则验证与漂移检查                    |
| goal-context-recovery  | gpt-5.5 | high      | 会话中断后上下文恢复                       |
| ci-governance-auditor  | gpt-5.5 | high      | 跨仓 CI/CD 治理审计（只读）                |

Goal Agent 是 `docs/goal/` 体系的 Codex TOML 投影，权威边界以 `docs/goal/00-authority-map.md` 为准。三平台 agent 镜像由 `scripts/sync-agents.py` 在 preflight 阶段检测漂移。

## 使用方式

```bash
codex --agent spec
codex --agent spec-structural-score
codex --agent pipeline-arbiter
```

## 端到端工作流入口

```text
$spec-code-pipeline {module}
$spec-code-pipeline {module} --from matrix
$spec-code-pipeline {module} --stage prompt
```

## 管线流程

每个阶段都由 **agent team** 执行：

```text
executor → [claude scorer | codex scorer | copilot scorer | rules scorer]（并行/独立）
        → pipeline-arbiter（composite_score = min(claude.score, codex.score, copilot.score, rules.score)；composite_score >= 98 且无红线、无 LLM 低置信度、LLM 分差与 rules 异构分歧在阈值内）
        → 通过则进入下一阶段；失败则路由回 executor 修复
```

详见 `docs/governance/STRUCTURAL-SCORING.md` 与 `docs/governance/scoring/ARBITER-PROTOCOL.md`。

## Beads Issue Tracking

This project uses [Beads (bd)](https://github.com/steveyegge/beads) for issue tracking.

### Core Rules

- Track ALL work in bd (never use markdown TODOs or comment-based task lists)
- Use `bd ready` to find available work
- Use `bd create` to track new issues/tasks/bugs
- Use `bd dolt push` at end of session to sync with remote
- Run `bd prime` for complete workflow context (SSOT for operational commands)

### Quick Reference

```bash
bd prime                              # Load complete workflow context (SSOT)
bd ready                              # Show issues ready to work (no blockers)
bd list --status=open                 # List all open issues
bd create "title" -t task -p 2        # Create new issue
bd update <id> --claim                # Claim work atomically
bd close <id>                         # Mark complete
bd dep add <issue> <depends-on>       # Add dependency
bd dolt push                          # Sync with remote
```

### Workflow

1. Check for ready work: `bd ready`
2. Claim an issue atomically: `bd update <id> --claim`
3. Do the work
4. Mark complete: `bd close <id>`
5. Push changes: `bd dolt push`

### Issue Types

- `bug` - Something broken
- `feature` - New functionality
- `task` - Work item (tests, docs, refactoring)
- `epic` - Large feature with subtasks
- `chore` - Maintenance (dependencies, tooling)

### Priorities

- `0` - Critical (security, data loss, broken builds)
- `1` - High (major features, important bugs)
- `2` - Medium (default, nice-to-have)
- `3` - Low (polish, optimization)
- `4` - Backlog (future ideas)

### Context Loading

Run `bd prime` to get complete workflow documentation in AI-optimized format.
`bd prime` is the single source of truth for operational commands and session workflow.

For detailed docs: see AGENTS.md, QUICKSTART.md, or run `bd --help`
