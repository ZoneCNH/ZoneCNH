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
