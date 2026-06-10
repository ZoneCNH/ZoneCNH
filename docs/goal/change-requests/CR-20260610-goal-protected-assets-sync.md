# CR-20260610 Goal Protected Assets Sync

Status: Proposed

Approval: Human Approval Required

Owner: workflow owner

## Scope

本 Change Request 仅请求在人工批准后同步受保护或跨控制面资产。它不是当前强规则源，不得用于绕过 `docs/goal/` 的现行 Gate。

受影响候选资产：

- `.config/goal/schema/rules.yaml`
- `.github/workflows/`
- `.claude/agents/`
- `.codex/agents/`
- `CONSTITUTION.md`

## Evidence

- [00-authority-map.md](../00-authority-map.md) 定义 `.config/goal/schema/rules.yaml` 是从 `docs/goal/` 镜像出的机器校验规则投影，不得反向定义新规则。
- [16-ci-cd.md](../16-ci-cd.md) 要求 CI 调用统一 validator 或 `docs/goal/tools/` wrapper，不在 workflow YAML 中复制第二套 Gate 规则。
- [14-agent-protocols.md](../14-agent-protocols.md) 要求 Agent 不得绕过 G0-G11，并要求单任务单 writer、worktree 隔离、多源 review 和 arbiter 边界。
- [04-gates.md](../04-gates.md)、[17-risk-and-decisions.md](../17-risk-and-decisions.md)、[20-metrics-evidence.md](../20-metrics-evidence.md) 已将 G10 Release Gate 绑定到 strict validator、Matrix check-only、Risk Register、Release Manifest、Evidence Bundle 和 rollback validation。

Hypothesis:

- `.config/goal/schema/rules.yaml`、`.github/workflows/`、`.claude/agents/`、`.codex/agents/` 可能需要同步上述更强的 G10 / Evidence Bundle / Matrix edge / Agent 协作规则。该项必须由 validator 输出、配置 diff 或 workflow owner 复核确认后才能改动。

## Impact

如果受保护资产未同步，可能出现以下漂移：

- 文档要求 Matrix canonical edge model，但 schema 或 agent prompt 仍按旧 row/table 口径执行。
- 文档要求 G10 同时证明 Release Manifest、Risk Register、Evidence Bundle 和 rollback validation，但 CI 只执行局部检查。
- Agent prompt 允许直接写共享文件或绕过 Gate，导致执行记录不可审计。
- `rules.yaml` 被误当成新规则源，而不是 `docs/goal/` 的机器投影。

## Root Cause

Goal Delivery OS 的规范权威、机器投影、CI 调度和 Agent 执行面分布在不同目录。`docs/goal/` 规则增强后，受保护资产需要显式同步流程，避免自动改写治理边界。

## Proposed Patch

人工批准后执行以下同步，且不得放宽任何 Gate：

1. 重新生成或手工对齐 `.config/goal/schema/rules.yaml`，确保它只投影 `docs/goal/` 的现行规则。
2. 检查 `.github/workflows/`，确保 workflow 调用统一 validator 和 `docs/goal/tools/` wrapper，不复制第二套 Gate 判定。
3. 检查 `.claude/agents/` 与 `.codex/agents/`，确保 agent prompt 包含单任务单 writer、worktree 隔离、多源 reviewer、pipeline-arbiter、Gate 不绕过、Evidence Bundle 和 Change Request 边界。
4. 仅当 `CONSTITUTION.md` 与 `docs/goal/` 的最高治理规则存在确认漂移时，提交单独 Constitution CR。

## Validation Command

```bash
python3 docs/goal/tools/rule-drift-check.py --root .
python3 docs/goal/tools/goal-validate.py --root . --mode strict
python3 docs/goal/tools/matrix-gen.py --check-only --matrix .config/goal/matrix/matrix.yaml
bash docs/goal/tools/goal-workflow.sh validate
```

同步受保护资产后，还应运行对应 CI workflow 的本地等价检查或 GitHub checks。

## Rollback Plan

- 对每个受保护资产独立提交，必要时逐个 revert。
- 如果 schema 投影导致 validator 异常，恢复上一版 `.config/goal/schema/rules.yaml`，保留本 CR 中的失败证据。
- 如果 workflow 或 agent prompt 同步引入误阻断，回滚该执行面变更，不回滚 `docs/goal/` 中更严格的规范，除非另有批准的规则 CR。

## Approval Requirement

- workflow owner 批准后方可修改 `.config/goal/schema/rules.yaml`、`.github/workflows/`、`.claude/agents/`、`.codex/agents/`。
- 修改 `CONSTITUTION.md` 必须单独审批。
- Release Gate、Rollback、Incident、P0/P1 AC、安全、隐私、资金、权限和数据保留约束不得在本 CR 中被放宽。
