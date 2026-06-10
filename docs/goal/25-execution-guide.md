# Goal Delivery OS 执行指南

本文档是新 Agent 或人工执行者进入 `docs/goal/` 的操作入口。它不替代各规范文档的权威定义，而是把主流程、Gate、Evidence、Matrix、Release、Risk 和 Agent 协作串成一条可执行路径。

## 1. 阅读顺序

首次执行 MUST 按以下顺序建立上下文：

1. [00-authority-map.md](00-authority-map.md)：确认 SSOT、投影、运行态和受保护资产边界。
2. [README.md](README.md)：确认目录入口和主流程。
3. [03-pipeline.md](03-pipeline.md)：确认状态机和主流程阶段。
4. [04-gates.md](04-gates.md)：确认 G0-G11 的阻断条件。
5. [05-layer-standards.md](05-layer-standards.md)：确认每层 DoR / DoD 和 Matrix edge model。
6. [20-metrics-evidence.md](20-metrics-evidence.md)：确认 Evidence Bundle 和 No Evidence, No Done。
7. [17-risk-and-decisions.md](17-risk-and-decisions.md)：确认 Risk Register、Release Manifest 和 rollback validation。
8. [14-agent-protocols.md](14-agent-protocols.md)：确认 Agent 协作边界。
9. [21-controlled-rsi.md](21-controlled-rsi.md)：确认自我改进边界。

任何无法从上述文档或仓库文件验证的内容 MUST 标记为 `Hypothesis`。

## 2. 主流程

Goal Delivery 主流程固定为：

```text
Goal -> Spec -> Design -> Plan -> Tasks -> Prompt -> Code -> Test -> Review -> Release -> Retrospective
```

Matrix 是横切追溯制品，不是主流程阶段。它必须在各阶段持续更新，用 canonical edge model 连接 Goal、Spec、Acceptance Criteria、Task、Prompt、Code、Test、Evidence、Risk、Gate 和 Release。

## 3. 阶段执行表

| 阶段 | 最低输入 | 最低输出 | 关联 Gate | 证据要求 |
|------|----------|----------|-----------|----------|
| Goal | 业务目标、owner、成功指标、non-goals | 可验证 Goal | G0 / G1 | G0 上下文恢复；G1 owner、指标、边界、优先级 |
| Spec | Approved Goal | 需求、AC、NFR、约束、风险 | G2 | AC 可测、P0/P1 明确 |
| Design | Approved Spec | 设计方案、边界、ADR、风险缓解 | G3 | 设计评审、风险记录 |
| Plan | Approved Design | 执行顺序、依赖、验证点 | G4 | 计划评审、资源与阻塞 |
| Tasks | Approved Plan + Matrix draft | 原子任务、允许文件、完成标准 | G5 | Task DoR、owner、依赖、Matrix coverage |
| Prompt | Task + Context Package | 可执行 Prompt | G6 | 边界、禁止事项、验证命令 |
| Code | Prompt + Task | 代码与测试变更 | G6 / G7 | G6 实现边界；G7 测试输出 |
| Test | Code + Test Plan | 测试报告和失败/通过记录 | G7 / G8 | Evidence Bundle、失败证据保留 |
| Review | Code + Evidence | 评审结论和问题闭环 | G9 | reviewer、finding、处理状态 |
| Release | Review PASS | Release Manifest | G10 | strict validator、Matrix、Risk Register、rollback validation |
| Retrospective | Release + Metrics | 复盘和改进 Backlog | G11 | Metrics Review、Gap Report、RSI 记录 |

Gate 编号 MUST 以 [04-gates.md](04-gates.md) 为权威，不得按阶段顺序自行重排。Matrix 不是主流程阶段；G5 是 Task 和 Matrix 追溯完整性的执行门禁。

### Matrix 横切控制点

Matrix 不占用主流程阶段号，但 G5 是全流程追溯完整性门禁。执行者 MUST 在以下控制点更新或校验 Matrix：

| 控制点 | 更新时机 | 关联 Gate | 证据要求 |
|--------|----------|-----------|----------|
| 初始化 | Spec 审批后 | G2 / G5 | Goal、Spec、Acceptance Criteria edge 可追溯 |
| 执行更新 | Design、Plan、Tasks、Prompt、Code、Test、Evidence 或 Risk 变化后 | G2-G9 | release-critical edge 无 orphan，变更来源可追溯 |
| 发布校验 | Release 前 | G10 | Matrix check-only 通过；release-critical edge 为 `Verified` 或 `Dropped` with reason |

## 4. 停止条件

执行者遇到以下情况 MUST 停止推进到下一阶段：

- Gate 返回 `FAIL` 或 `BLOCKED`。
- P0 / P1 AC 没有测试证据和评审或验证证据。
- Evidence Bundle 缺少命令、环境、commit/artifact、结果或 owner。
- Matrix release-critical edge 存在 orphan、未验证或未说明 drop reason。
- Risk Register 存在未解除（`Open` / `Escalated`）的 `release_blocking` 风险。
- G10 缺少 Release Manifest、Risk Register、validation summary 或 rollback validation。
- 需要修改 Constitution、CI、agent 配置、schema 投影、Release Gate、Rollback、Incident 规则、P0/P1 语义或安全相关约束，但没有 Change Request 和 Human Approval。
- 发现 `docs/goal/` 与 `.config/goal/`、CI、Constitution 或 Agent 配置漂移，且漂移会影响 Gate、Evidence、Release 或安全边界。

## 5. 验证命令

优先使用仓库现有统一 validator，不在 workflow 或人工步骤里复制第二套规则。

```bash
python3 docs/goal/tools/rule-drift-check.py --root .
python3 docs/goal/tools/goal-validate.py --root . --mode strict
python3 docs/goal/tools/matrix-gen.py --check-only --matrix .config/goal/matrix/matrix.yaml
bash docs/goal/tools/goal-workflow.sh validate
bash docs/goal/tools/goal-workflow.sh release
```

`release` 命令仅在准备 tag、部署或发布时作为硬门禁；普通文档 PR 可以记录未运行原因，但不得宣称 Release 通过。

如果某个命令不可用或失败，执行者 MUST 记录失败命令、失败原因、替代检查和未验证风险，不能把未验证结果声明为通过。

## 6. Agent 协作规则

- 单个 Task 同一时间只能有一个 writer。
- 并行工作 MUST 使用 worktree 或等效隔离，并记录 branch、commit、allowed files 和 prohibited scope。
- Reviewer / Verifier MUST 与 writer 分离；高风险或发布相关变更 SHOULD 由 pipeline-arbiter 或 workflow owner 汇总裁决。
- Agent MUST NOT 绕过 G0-G11、删除失败证据、放宽 Release Gate、或把 projection 当成新权威源。
- Agent 发现跨 `docs/goal/`、`.config/goal/`、CI、Constitution、agent 配置的漂移时，MUST 记录 evidence 和影响范围。

## 7. Change Request 规则

以下资产属于受保护或跨控制面资产，修改前 MUST 生成 Change Request 并标记 Human Approval：

- `CONSTITUTION.md`
- `.github/workflows/`
- `.config/goal/schema/rules.yaml`
- `.claude/agents/`
- `.codex/agents/`
- Release Gate、Rollback、Incident、P0/P1 AC、安全、隐私、资金、权限、数据保留相关规则

Change Request 至少包含 evidence、impact、root cause、proposed patch、validation command、rollback plan、owner / approval requirement。未批准的 Change Request 是提案，不是当前强规则。

## 8. 完成声明

完成声明必须同时回答：

- 哪个 Goal / Task / Release 被完成。
- 哪些 Gate 通过，哪些 Gate 有风险接受。
- Evidence Bundle 的路径或 ID 是什么。
- Matrix release-critical edges 是否全部 Verified 或 Dropped with reason。
- Risk Register 是否存在未解除（`Open` / `Escalated`）的 `release_blocking` 风险。
- Release Manifest 和 rollback validation 是否存在。
- 哪些内容仍是 `Hypothesis` 或需要 Human Approval。
