# CR-20260610 Goal Protected Assets Sync

Status: Implemented for approved local scope

Approval: User granted full local modification authorization in-thread on 2026-06-11; this CR only permits strengthening or projection sync and does not permit relaxing protected constraints.

Owner: workflow owner

## Scope

本 Change Request 仅请求在人工批准后同步受保护或跨控制面资产。它不是当前强规则源，不得用于绕过 `docs/goal/` 的现行 Gate。

本 CR 的验证指标：4个 validation command 均 PASS，lint / strict validator / Matrix check / workflow wrapper 合计 0个 error；未批准资产保持 Change Request 状态。

受影响候选资产：

- `.config/goal/schema/rules.yaml`
- `.github/workflows/`
- `.claude/agents/`
- `.codex/agents/`
- `.copilot/agents/`
- `CONSTITUTION.md`

## Evidence

- [00-authority-map.md](../00-authority-map.md) 定义 `.config/goal/schema/rules.yaml` 是从 `docs/goal/` 镜像出的机器校验规则投影，不得反向定义新规则。
- [16-ci-cd.md](../16-ci-cd.md) 要求 CI 调用统一 validator 或 `docs/goal/tools/` wrapper，不在 workflow YAML 中复制第二套 Gate 规则。
- [14-agent-protocols.md](../14-agent-protocols.md) 要求 Agent 不得绕过 G0-G11，并要求单任务单 writer、worktree 隔离、多源 review 和 arbiter 边界。
- [04-gates.md](../04-gates.md)、[17-risk-and-decisions.md](../17-risk-and-decisions.md)、[20-metrics-evidence.md](../20-metrics-evidence.md) 已将 G10 Release Gate 绑定到 strict validator、Matrix check-only、Risk Register、Release Manifest、Evidence Bundle 和 rollback validation。
- [04-gates.md](../04-gates.md)、[17-risk-and-decisions.md](../17-risk-and-decisions.md)、[20-metrics-evidence.md](../20-metrics-evidence.md)、[25-execution-guide.md](../25-execution-guide.md) 均要求 G10 / Release Evidence 包含 `validation_summary`；本 CR 验证到 `.config/goal/schema/rules.yaml` 曾未显式列出该字段，2026-06-11 已同步为 schema 回归要求。
- [CONSTITUTION.md](../../CONSTITUTION.md) §17 曾描述 `Goal → Spec → Matrix → Tasks → Plan → Prompt → Code → Test → Release → Metrics`，而 [03-pipeline.md](../03-pipeline.md) 定义 11 层主流程并将 Matrix 定位为横切追溯制品；2026-06-11 已对齐为当前主流程。由于 Constitution 是最高治理源，后续再次修改仍必须单独审批。
- `.codex/agents/goal-*.toml` 已补齐并与 [14-agent-protocols.md](../14-agent-protocols.md) 对齐；2026-06-11 已补齐 `.copilot/agents/goal-*.md`，并在 `.copilot/AGENTS.md` 中声明这些文件只是 `docs/goal/` 的 prompt 投影，不是独立规则源。
- `python3 docs/goal/tools/rule-drift-check.py --root .` 已在 2026-06-11 验证通过；此前 CI job 漂移已作为本 CR 的第 2 项部分实现完成，后续作为回归检查保留。

Remaining Hypothesis:

- Copilot CLI runtime smoke 尚未在本地验证；prompt 投影已存在，但平台运行行为仍需要人工或平台 smoke 后才能声明。
- 未来若再次怀疑 schema / workflow / agent / Constitution 漂移，MUST 先通过 validator 输出、配置 diff 或 workflow owner 复核重新建立证据，不能沿用本 CR 的旧 Hypothesis。

## Impact

如果受保护资产未同步，可能出现以下漂移：

- 文档要求 Matrix canonical edge model，但 schema 或 agent prompt 仍按旧 row/table 口径执行。
- 文档要求 G10 同时证明 Release Manifest、Risk Register、Evidence Bundle 和 rollback validation，但 CI 只执行局部检查。
- Agent prompt 允许直接写共享文件或绕过 Gate，导致执行记录不可审计。
- `rules.yaml` 被误当成新规则源，而不是 `docs/goal/` 的机器投影。
- Constitution 与 `docs/goal/` 对主流程阶段顺序给出不同口径，可能导致 Agent 在 Matrix 定位和 Release 前置条件上执行不一致。
- Copilot Goal Agent prompt 投影若再次缺失或与 `docs/goal/` 漂移，会让执行者假设不存在或过期的 agent 能力，从而破坏协作和审计预期。
- 若后续 workflow required jobs 再次漂移，`goal-workflow validate` 或 `rule-drift-check` MUST 阻断；该阻断不能通过删除 required jobs 或跳过 rule-drift-check 解决。
- schema 若再次未显式投影 `validation_summary`，执行面可能错误接受缺少验证摘要的 Evidence Bundle 或 G10 Release 输入。

## Root Cause

Goal Delivery OS 的规范权威、机器投影、CI 调度和 Agent 执行面分布在不同目录。`docs/goal/` 规则增强后，受保护资产需要显式同步流程，避免自动改写治理边界。

## Proposed Patch

批准后执行以下同步，且不得放宽任何 Gate：

1. 重新生成或手工对齐 `.config/goal/schema/rules.yaml`，确保它只投影 `docs/goal/` 的现行规则。
   - `evidence.bundle_required_fields` 和 / 或 `release_gate.required_inputs` 应显式投影 `validation_summary`，不得把该字段降级为可选说明。
2. 检查 `.github/workflows/`，确保 workflow 调用统一 validator 和 `docs/goal/tools/` wrapper，不复制第二套 Gate 判定；对齐 `id-format-check`、`matrix-coverage`、`gate-check`、`orphan-check` 的 workflow job 定义或经审批更新 required job 投影，不得为了通过检查删除 Gate。
3. 检查 `.claude/agents/`、`.codex/agents/` 与 `.copilot/agents/`，确保 agent prompt 包含单任务单 writer、worktree 隔离、多源 reviewer、pipeline-arbiter、Gate 不绕过、Evidence Bundle 和 Change Request 边界；若任一平台 `goal-*` agent 缺失，应在审批后补齐或继续作为投影缺口记录。
4. 对齐 `CONSTITUTION.md` 与 `docs/goal/` 主流程 / Matrix 横切定位漂移；该同步不得改变已批准 Goal、Non-goals、P0/P1 验收、安全约束或 Release Gate 阻断要求。

## Implementation Note

2026-06-11: 已执行第 2 项的 CI workflow 同步：在 `.github/workflows/goal-ci.yml` 中补齐 `id-format-check`、`matrix-coverage`、`gate-check`、`orphan-check` job，并让它们调用现有 `docs/goal/tools/` validator / wrapper。

2026-06-11: 已执行第 1、3、4 项中的保守同步：`.config/goal/schema/rules.yaml` 显式投影 G10 `validation_summary`；`CONSTITUTION.md` 对齐主流程与 Matrix 横切定位；`.claude/agents/goal-*` 中的旧文档数量、Release Gate 和 Evidence 字段口径已同步；`.codex/agents/goal-*.toml` 已补齐 Goal 专用投影。

2026-06-11: 已执行第 3 项剩余同步：新增 `.copilot/agents/goal-*.md`，并更新 `.copilot/AGENTS.md`，使 Copilot Goal prompt 投影包含单任务单 writer、worktree 隔离、多源 reviewer、Gate 不绕过、Matrix edge graph、Evidence Bundle、Release Gate、Rollback 和 Change Request 边界。Copilot prompt 投影仍不构成独立规则源，运行时能力需要由 Copilot CLI 人工或平台 smoke 另行验证。

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

- workflow owner 批准后方可修改 `.config/goal/schema/rules.yaml`、`.github/workflows/`、`.claude/agents/`、`.codex/agents/`、`.copilot/agents/`。
- 修改 `CONSTITUTION.md` 必须单独审批。
- Release Gate、Rollback、Incident、P0/P1 AC、安全、隐私、资金、权限和数据保留约束不得在本 CR 中被放宽。
