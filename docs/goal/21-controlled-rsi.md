# 受控递归改进

Controlled RSI 是基于证据改进工程工作流的机制，不是让 Agent 自动重写产品目标或生产代码。它改进的是模板、Prompt、Gate、矩阵字段、检查清单和评估集。

## 可改进对象

| 对象 | 示例 |
|------|------|
| Templates | Goal、Spec、Task、Review、Metrics Review 模板 |
| Prompts | Task Prompt、Review Prompt、Verifier Prompt |
| Gates | 追溯检查、风险检查、证据检查、发布检查 |
| Matrix Fields | 新增风险、指标、证据、owner 字段 |
| Checklists | 安全、隐私、性能、回滚、观测性清单 |
| Knowledge Libraries | 常见失败模式、风险库、决策记录 |
| Eval Datasets | 用历史失败案例评估 Prompt 和 Gate |
| Scorecards | 工作流质量、交付质量、改进有效性评分 |

Controlled RSI 的价值来自重复问题的系统性消除，而不是生成更多文本。

## 禁止自动改动

以下内容不得由 RSI 自动修改：

- 已批准 Goal 的核心目标、非目标和成功指标。
- P0/P1 验收标准。
- 安全、隐私、资金、权限、数据保留约束。
- 发布 Gate、回滚要求和事故处理要求。
- 生产代码和生产配置。
- 失败测试、测试标准和证据要求。
- 任何会降低审查强度或改变责任归属的规则。

这类变更必须走显式 CR，并由人或授权的 workflow owner 批准。

## 改进循环

| 阶段 | 输入 | 输出 |
|------|------|------|
| Observe | 测试失败、评审发现、指标偏差、事故、重复返工 | 事实清单 |
| Diagnose | 追溯缺口、Prompt 误导、Gate 缺失、模板歧义 | 根因分析 |
| Propose | 模板补丁、Prompt 补丁、Gate 补丁、评估集补充 | 改进提案 |
| Validate | 历史案例回放、规则测试、样例任务验证 | 验证报告 |
| Approve | workflow owner 审核 | 批准或拒绝 |
| Apply | 版本化合入工作流资产 | Workflow Change Log |
| Measure | 后续任务的缺陷率、返工率、漏检率 | Scorecard |

改进必须先证明“为什么现在的工作流漏掉了问题”，再提出补丁。

## R0-R9 控制 Gate

Controlled RSI 的每次改进都必须通过 R0-R9。任一 Gate 无法证明时，改进进入 Backlog 或 Change Request，MUST NOT 直接应用。

| Gate | 证明对象 | 阻断条件 |
|------|----------|----------|
| R0 Evidence Intake | 改进有事实来源 | 没有失败证据、评审发现、指标偏差或事故记录；Hypothesis 未标记 |
| R1 Scope Classification | 改进对象分类正确 | 把 Goal 语义、P0/P1 AC、安全/隐私/资金/权限/数据保留约束伪装成模板优化 |
| R2 Protected Asset Check | 是否触碰受保护资产 | 需要改 Constitution、CI、agent 配置、schema 投影、Release Gate、Rollback 或 Incident 规则但没有 CR |
| R3 Safety Preservation | 不降低现有约束 | 删除失败测试、降低 Gate、放宽证据要求、改变责任归属或减少审查源 |
| R4 Evaluation Replay | 历史案例可回放 | Prompt、Template、Gate、Matrix、Checklist 改动无法用历史样例或当前任务验证 |
| R5 Projection Consistency | 投影与 SSOT 一致 | `.config/goal/schema/rules.yaml`、CI 或 Agent 配置与 `docs/goal/` 新规则漂移且未登记 |
| R6 Approval | 审批状态明确 | Propose-only / Approval-required 项没有 workflow owner 或 Human Approval |
| R7 Rollout Scope | 灰度范围可控 | 无适用范围、无回退边界、无版本记录 |
| R8 Rollback | 可回滚 | 没有 rollback plan、无法恢复旧模板/Prompt/Gate/字段 |
| R9 Retrospective | 改进效果可衡量 | 无后续指标、无复盘窗口、无法判断改进是否减少缺陷或返工 |

## RSI Scorecard

每个改进提案必须按 0-5 分记录以下维度：

| 维度 | 说明 |
|------|------|
| Impact | 能减少多少真实缺陷、返工或发布风险 |
| Risk | 是否可能改变语义、责任、审批或安全边界 |
| Verifiability | 是否能通过 replay、validator、CI 或样例任务证明 |
| Maintenance Cost | 是否增加持续维护负担或规则复杂度 |
| Safety Preservation | 是否保持或增强安全、隐私、资金、权限、数据保留和证据要求 |

Auto-allowed 只适用于低风险、可回滚、不触碰受保护资产、且 R0-R9 均通过的澄清性改进。任何会改变执行行为、Gate 强度、Release 条件或投影规则的改进 MUST 至少进入 Propose-only，并由 workflow owner 审批。

## Rollback 与 Replay

- 每个 Workflow Asset Patch MUST 记录 rollback plan，说明如何恢复旧模板、Prompt、Gate、Checklist 或 Matrix 字段。
- 触碰 Prompt、Template、Gate、Matrix、Checklist 的改进 MUST 在应用前执行 Evaluation Replay；没有可用历史样例时，必须记录验证缺口。
- `.config/goal/schema/rules.yaml`、`.github/workflows/`、`.claude/agents/`、`.codex/agents/` 是投影或执行面，MUST NOT 由 RSI 自动改写为新权威源。
- 投影不一致时，先在 `docs/goal/change-requests/` 记录 CR；Human Approval 后再同步受保护资产。
- Rollback、Release Gate、Incident 处理、P0/P1 AC、安全、隐私、资金、权限和数据保留约束 MUST NOT 被 RSI 自动放宽。

## 触发信号

| 信号 | 可能含义 |
|------|----------|
| 同类 review finding 重复出现 | Review Checklist 或 Prompt 缺少约束 |
| 测试覆盖声称完整但线上指标失败 | Matrix 没连接真实指标 |
| Task 反复返工 | Spec/Task 切分不清或 Prompt Pack 缺上下文 |
| Agent 修改越界文件 | Allowed Files 或执行边界不清 |
| AC 无法验证 | Goal/Spec 的验收标准不可测 |
| 发布后才发现回滚困难 | Release Gate 缺少 rollback evidence |
| 指标口径争议 | Observability Contract 缺字段或 owner |

这些信号应进入 Improvement Backlog，而不是只在复盘会上口头讨论。

## 必备产物

| 产物 | 用途 |
|------|------|
| Retrospective Report | 汇总事实、影响和改进方向 |
| Root Cause Analysis | 区分产品、工程、数据、工作流根因 |
| Improvement Backlog | 管理候选改进项 |
| Improvement Matrix | 映射问题、补丁、验证、风险 |
| Workflow Change Log | 记录工作流版本变化 |
| Eval Dataset | 用历史样例回测 Prompt/Gate |
| Scorecard | 度量改进是否真的有效 |
| Safety Case | 说明改进不会降低安全和质量门槛 |

## 不变量

Controlled RSI 必须保持以下不变量：

- 不修改原始目标来适配实现结果。
- 不删除失败证据来获得通过。
- 不用新指标替代旧指标，除非 CR 记录映射关系。
- 不把建议型改进伪装成自动批准。
- 不让同一个 Agent 同时绕过 builder/reviewer 分离。
- 不降低安全、隐私、资金、权限和数据约束。
- 不把流程复杂度转嫁给低风险任务。

## 策略级别

| 级别 | 允许动作 | 例子 |
|------|----------|------|
| Auto-allowed | 不改变语义的文档和模板澄清 | 修正错字、补充字段说明 |
| Propose-only | 可能影响执行行为的建议 | 新 Gate、新 Prompt 约束、新矩阵字段 |
| Approval-required | 改变工作流版本或评分规则 | 修改门禁阈值、调整指标解释 |
| Forbidden | 降低质量、安全或追溯要求 | 删除失败测试、放宽 P0 AC、跳过 Metrics Review |

默认策略应保守。宁可让改进进入 Backlog，也不要让 RSI 直接改写治理规则。

## 角色边界

| 角色 | 职责 |
|------|------|
| Code Agent | 按 Task 和 Prompt 实现，不修改工作流规则 |
| Review Agent | 找缺陷和风险，不替代批准者 |
| Improvement Agent | 基于证据提出工作流补丁 |
| Workflow Owner | 批准、拒绝或回滚工作流变更 |
| Verifier | 证明补丁在历史样例和当前任务上有效 |

角色分离是 Controlled RSI 的安全边界。没有边界的自改进会把错误放大。

## 最小可行 RSI

每次中等以上交付后回答五个问题：

1. 哪个问题是在实现后才发现的？
2. 哪个模板、Prompt、Gate 或 Matrix 字段本该提前暴露它？
3. 是否有历史案例可以验证补丁有效？
4. 补丁会不会降低现有质量或安全标准？
5. 下一个任务如何度量这个补丁是否有效？

只有这五个问题都有证据支撑时，才进入工作流补丁流程。
