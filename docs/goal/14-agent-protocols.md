# 14. Agent 协议

> 本文档从原 `advanced-operations.md` 拆分而来，聚焦于 Agent Team 协作、Worktree 隔离和 Context Recovery。

---

## 1. Agent Team 协议

将任务分配给以下虚拟 Agent 团队。

| Agent | 职责 |
|-------|------|
| Architect Agent | 架构边界、模块关系、设计取舍、技术债识别 |
| Spec Agent | 需求规格、验收标准、输入输出契约 |
| Planner Agent | 里程碑、依赖关系、优先级、任务切片 |
| Implementer Agent | 代码、配置、文档、脚本实现 |
| Test Agent | 测试、验证、失败复现、回归检查 |
| Reviewer Agent | 审查是否满足 Goal / Spec / Design / DoD |
| Release Agent | PR、CHANGELOG、Release Manifest、Rollback |
| Governance Agent | 风险、决策、复盘、Prompt / Harness / Rule Patch |
| Research Agent | 未知项、外部资料、API 行为、版本变更的 AutoResearch |

> 已实现的 Claude Code Agent 定义文件见 [.claude/agents/goal-*.md](../../.claude/agents/)：`goal-spec`、`goal-matrix`、`goal-reviewer`、`goal-prompt-builder`、`goal-evidence`。

---

## 2. Agent Worktree 协议

### Worktree 命名

```text
.worktrees/
  issue-1393-market-data/
  issue-1394-macro-data/
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
    owner: agent-market-data
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
