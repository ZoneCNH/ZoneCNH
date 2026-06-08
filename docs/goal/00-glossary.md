# 术语表

本文档定义 Goal 驱动交付体系中的核心术语。

| 术语 | 定义 | 权威定义位置 |
|------|------|-------------|
| Goal | 可验证的业务目标，包含目标动作、结果对象、衡量指标、目标值和截止时间 | [02-goal-standard.md](02-goal-standard.md) |
| Spec | 需求规格，定义具体要做什么、边界是什么 | [05-layer-standards.md §4.1](05-layer-standards.md#41-spec-标准) |
| Design | 设计方案，回答怎么拆、怎么隔离 | [05-layer-standards.md §4.2](05-layer-standards.md#42-design-标准) |
| Matrix | 追溯矩阵，将 Goal/Spec/AC/Task/Test/Evidence 串联为可追溯映射 | [05-layer-standards.md §4.3](05-layer-standards.md#43-matrix-标准) |
| Task | 可执行的原子任务，有明确输入、输出和完成标准 | [05-layer-standards.md §4.4](05-layer-standards.md#44-tasks-标准) |
| Plan | 执行计划，定义任务执行顺序、阶段和验证点 | [05-layer-standards.md §4.5](05-layer-standards.md#45-plan-标准) |
| Prompt | 驱动 AI/工程师执行的指令模板 | [05-layer-standards.md §4.6](05-layer-standards.md#46-prompt-标准) |
| Gate | 质量门禁，阻止问题流到下一层 | [04-gates.md](04-gates.md) |
| Evidence | 交付证据，证明任务已完成且满足验收标准 | [13-runtime-engine.md §4](13-runtime-engine.md#4-evidence-协议) |
| Registry | 注册表，保存长期共享状态 | [15-registry.md](15-registry.md) |
| Patch | 改进项，分为 Prompt Patch、Harness Patch、Rule Patch | [19-self-improving.md §1](19-self-improving.md#1-self-improving-机制) |
| Harness | 测试/验证工具链，包括 Gate、CI 检查、Lint 脚本 | [10-lint-rules.md](10-lint-rules.md) |
| DoR | Definition of Ready，进入某阶段前必须满足的条件 | [08-quality-gates.md §2](08-quality-gates.md#2-definition-of-ready--definition-of-done) |
| DoD | Definition of Done，完成某阶段时必须满足的条件 | [06-dod.md](06-dod.md) |
| RSI | Recursive Self-Improvement，受控递归改进机制 | [21-controlled-rsi.md](21-controlled-rsi.md) |
| ADR | Architecture Decision Record，架构决策记录 | [17-risk-and-decisions.md §2](17-risk-and-decisions.md#2-decision-logadr) |
| AC | Acceptance Criteria，验收标准，定义需求何时算完成 | [05-layer-standards.md §4.1](05-layer-standards.md#41-spec-标准) |
| RFC | Request for Comments，征求意见稿，用于技术方案评审 | [11-ai-collaboration.md](11-ai-collaboration.md) |
| RACI | Responsible/Accountable/Consulted/Informed，责任分配矩阵 | [06-dod.md](06-dod.md) |
| CWV | Core Web Vitals，核心网页指标（LCP/FID/CLS） | [20-metrics-evidence.md](20-metrics-evidence.md) |
| Non-goal | 明确声明不做的事情，防范围蔓延 | [02-goal-standard.md §4](02-goal-standard.md#4-non-goal) |
| Retrospective | 复盘，Goal 完成后的回顾总结 | [06-dod.md](06-dod.md) |
| Prompt Patch | 针对 Prompt 层的改进补丁 | [19-self-improving.md §1](19-self-improving.md#1-self-improving-机制) |
| Harness Patch | 针对测试/验证工具链的改进补丁 | [19-self-improving.md §1](19-self-improving.md#1-self-improving-机制) |
| Rule Patch | 针对规则/规范的改进补丁 | [19-self-improving.md §1](19-self-improving.md#1-self-improving-机制) |
| SSOT | Single Source of Truth，单一事实来源，每项内容只有一个权威定义 | 本文档 |
| Goal Owner | Goal 的负责人，对 Goal 的完成负最终责任 | [02-goal-standard.md](02-goal-standard.md) |
| Orphan Check | 孤儿检查，验证 Matrix 中无遗漏的追溯链 | [08-quality-gates.md](08-quality-gates.md) |
| Evidence Graph | 证据图，将 Evidence 节点连接为有向无环图，记录"为什么可以相信这次交付" | [20-metrics-evidence.md §Evidence Graph](20-metrics-evidence.md#evidence-graph) |
| Workflow-as-Code | 将交付流程定义为可执行代码，像代码一样版本化、检查和测试 | [22-delivery-os.md §Workflow-as-Code](22-delivery-os.md#workflow-as-code) |
| Workflow Compiler | 将 Goal/Spec/Matrix 编译为可验证执行包（任务、Prompt、Gate 要求）的引擎 | [22-delivery-os.md §Workflow Compiler](22-delivery-os.md#workflow-compiler) |
| Prompt Compiler | 将控制面转换为执行约束的编译器，不只是拼接上下文 | [22-delivery-os.md §Prompt Compiler](22-delivery-os.md#prompt-compiler) |
| Controlled RSI | 受控递归自我改进，通过 Patch 系统改进模板、Prompt、Gate、检查清单等工程资产 | [21-controlled-rsi.md](21-controlled-rsi.md) |
| Drift Check | 漂移检查，检测实现偏离 Spec 的情况，输出结构化报告 | [23-workflow-governance-checks.md §Drift Checks](23-workflow-governance-checks.md#drift-checks) |
| Validation Gate | 验证门禁，在 Pipeline 关键节点验证制品质量（Achieved / Partially Achieved / Not Achieved） | [20-metrics-evidence.md §Metrics Validation Gate](20-metrics-evidence.md#metrics-validation-gate) |
| Gap Report | 差距报告，指标未达成时保留原 Goal 和成功标准，新增差距分析和 follow-up 任务 | [20-metrics-evidence.md §Metrics Gap Report](20-metrics-evidence.md#metrics-gap-report) |
| Change Level (CL0-CL5) | 变更影响级别，评估变更影响范围和审批要求（CL0 文档修正 到 CL5 数据模型变更） | [13-runtime-engine.md](13-runtime-engine.md) |
| Release Manifest | 发布清单，记录版本包含的所有变更、关联 PR、测试结果和风险评估 | [17-risk-and-decisions.md §Release Manifest](17-risk-and-decisions.md#3-release-manifest) |
| Risk Register | 风险登记册，记录和跟踪项目风险，包含风险描述、概率、影响和缓解措施 | [17-risk-and-decisions.md §Risk Register](17-risk-and-decisions.md#1-risk-register) |
| Pipeline State Machine | 管线状态机，定义 12 种正常状态和 8 种异常状态，驱动整个交付流程 | [03-pipeline.md §状态机](03-pipeline.md#2-状态机) |
| Gate Review | 门禁审查，在 Gate 节点进行的质量检查，包含通过/拒绝/条件通过三种结果 | [04-gates.md](04-gates.md) |
| SMART | Specific/Measurable/Achievable/Relevant/Time-bound，目标制定的五项原则 | [02-goal-standard.md §SMART 原则](02-goal-standard.md#2-smart-原则) |
| Spec Compiler | 将 Spec 编译为 Task 列表的工具，解析需求规格并生成可执行的原子任务 | [22-delivery-os.md](22-delivery-os.md) |
| Context Recovery | 上下文恢复，在会话中断后恢复工作状态，包括 Git 状态、进度追踪和决策历史 | [14-agent-protocols.md §Context Recovery](14-agent-protocols.md#3-context-recovery) |
| Worktree Isolation | 工作树隔离，使用 git worktree 隔离并行任务，避免分支切换的开销和冲突 | [14-agent-protocols.md](14-agent-protocols.md) |
