# Agent 协议

> 本文档从原 `advanced-operations.md` 拆分而来，聚焦于 Agent Team 协作、Worktree 隔离和 Context Recovery。

---

## 0. 执行不变量

- Agent MUST 遵守单任务单 writer：一个 Task 同一时间只能有一个 writer 修改可交付文件；其他 Agent 只能 review、verify 或补证据。
- Agent MUST 使用 worktree 或等价隔离机制处理并行任务，并在 Context Package 中记录分支、commit、allowed files 和禁止范围。
- Reviewer MUST 多源化：至少区分 writer、reviewer、verifier；高风险变更还需要 pipeline-arbiter 或 workflow owner 汇总裁决。
- Agent MUST NOT 绕过 G0-G11；Gate FAIL/BLOCKED 时只能修复、补证据、重计划或发起 CR。
- Agent MUST 把不可确认内容标记为 Hypothesis，不得写成事实或放入 Release Manifest。
- Agent MUST 把 Matrix 当作横切 edge graph 更新，不得把 Matrix 当作主流程阶段。
- 当 `.claude/agents/`、`.codex/agents/`、CI、schema 投影或 Constitution 与 `docs/goal/` 发生漂移时，Agent MUST 在 `docs/goal/change-requests/` 生成 Change Request，并标记 Human Approval；不得在未审批时放宽 Gate、Release、Rollback、Incident、P0/P1 或安全约束。

---

## 1. Agent Team 协议

将任务分配给以下虚拟 Agent 团队。

| Agent             | 职责                                                |
| ----------------- | --------------------------------------------------- |
| Architect Agent   | 架构边界、模块关系、设计取舍、技术债识别            |
| Spec Agent        | 需求规格、验收标准、输入输出契约                    |
| Planner Agent     | 里程碑、依赖关系、优先级、任务切片                  |
| Implementer Agent | 代码、配置、文档、脚本实现                          |
| Test Agent        | 测试、验证、失败复现、回归检查                      |
| Reviewer Agent    | 审查是否满足 Goal / Spec / Design / DoD             |
| Release Agent     | PR、CHANGELOG、Release Manifest、Rollback           |
| Governance Agent  | 风险、决策、复盘、Prompt / Harness / Rule Patch     |
| Research Agent    | 未知项、外部资料、API 行为、版本变更的 AutoResearch |

> 已实现的 Claude Code Agent 定义文件见 [.claude/agents/goal-*.md](../../.claude/agents/)：`goal-spec`、`goal-matrix`、`goal-reviewer`、`goal-prompt-builder`、`goal-evidence`。
>
> 已实现的 Codex Agent 定义文件见 [.codex/agents/goal-*.toml](../../.codex/agents/)：`goal-spec`、`goal-matrix`、`goal-reviewer`、`goal-prompt-builder`、`goal-evidence`。

> 已实现的 Copilot Agent prompt 投影见 [.copilot/agents/goal-*.md](../../.copilot/agents/)：`goal-spec`、`goal-matrix`、`goal-reviewer`、`goal-prompt-builder`、`goal-evidence`。

Claude、Codex 和 Copilot 的 `goal-*` Agent 定义都是 `docs/goal/` 的平台投影，不是独立规则源。任一平台投影与本文件、[00-authority-map.md](00-authority-map.md)、[04-gates.md](04-gates.md)、[20-metrics-evidence.md](20-metrics-evidence.md) 或 `.config/goal/schema/rules.yaml` 漂移时，执行者 MUST 生成 Change Request 并运行 drift / validator 检查；不得宣称漂移平台已经实现当前 Goal Delivery OS 规则。

---

## 2. Agent Worktree 协议

### Worktree 命名

```text
.worktrees/
  issue-1393-market_data/
  issue-1394-macro_data/
  task-goal-20260531-001-003/
```

### 每个 Worktree 必须有

```text
.config/goal/agent-local/
  context.md          — 上下文恢复文件
  task.md             — 当前任务描述
  registry_snapshot.yaml — Registry 快照
  evidence/           — 证据目录
  test.log            — 测试日志
  diff_summary.md     — 变更摘要
```

### 文件锁规则

```yaml
locks:
  - file: internal/market_data/provider.go
    owner: agent-market_data
    task: TASK-GOAL-20260531-001-003
    expires_at: 2026-06-01T12:00:00Z
```

### 冲突规则

```text
1. 多 Agent 不允许同时改同一公共接口
2. 同一文件需要多 Agent 修改时，必须指定 file owner
3. 公共接口变更必须先合并 design branch
4. 合并前必须通过 Review Gate
5. 冲突超过 2 次进入 NEEDS_REPLAN
```

---

## 3. Context Recovery

每轮执行前必须恢复上下文。

### 恢复文件

```text
.config/goal/state/current_context.md      — 当前上下文
.config/goal/state/execution_state.md      — 执行状态
.config/goal/state/last_run_summary.md     — 上轮摘要
```

### 恢复字段

```text
Current goal:      [当前目标]
Current phase:     [当前阶段]
Current branch:    [当前分支]
Current version:   [当前版本]
Completed tasks:   [已完成任务]
Pending tasks:     [待处理任务]
Blocked tasks:     [被阻塞任务]
Known risks:       [已知风险]
Key decisions:     [关键决策]
Latest evidence:   [最新证据]
Next action:       [下一步行动]
```
