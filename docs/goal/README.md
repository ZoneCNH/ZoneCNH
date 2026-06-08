# Goal 驱动交付体系

> **没有 Goal 的代码是无源代码；没有 Matrix 的需求容易丢失；没有 Test 的实现无法证明完成；没有 Metrics 的上线无法证明有价值。**

本文档集定义了一套完整的 **Goal 驱动交付体系**，用于确保每一行代码都能追溯到一个可验证的业务目标。

## 核心公式

> **Goal = 目标动作 + 结果对象 + 衡量指标 + 目标值 + 截止时间**

满足 SMART 原则：Specific、Measurable、Achievable、Relevant、Time-bound。

## 工作流全景

> 完整管线（11 层）和状态机定义见 [03-pipeline.md](03-pipeline.md)。

最小闭环（简化版）：

```text
Goal 定义结果 → Spec 定义需求 → Tasks 拆解执行 → Prompt 驱动生成 → Code 完成交付 → Test 验证
```

每一层都必须回答一个问题：

| 层级   | 核心问题                   | 输出物     |
| ------ | -------------------------- | ---------- |
| Goal   | 为什么做？做到什么算成功？ | 目标定义   |
| Spec   | 具体要做什么？边界是什么？ | 需求规格   |
| Tasks  | 需要拆成哪些可执行任务？   | 任务清单   |
| Prompt | 如何让 AI/工程师准确执行？ | 指令模板   |
| Code   | 最终实现是否满足验收？     | 代码与测试 |
| Test   | 实现是否正确？             | 测试结果   |

Matrix（追溯矩阵）是横切制品，贯穿所有阶段，不是独立的管线层。详见 [05-layer-standards.md §4.3](05-layer-standards.md#43-matrix-标准)。

## 文档索引

| 文件                                                   | 内容                                                                         |
| ------------------------------------------------------ | ---------------------------------------------------------------------------- |
| [00-glossary.md](00-glossary.md)                       | 术语表：Goal 驱动交付体系核心术语定义                                        |
| [00-quickstart.md](00-quickstart.md)                   | 快速开始：5 分钟理解体系、端到端案例、模式选择决策树、常见问题               |
| [01-methodology.md](01-methodology.md)                 | 核心方法论：工作流原理、输入输出、闭环逻辑                                   |
| [02-goal-standard.md](02-goal-standard.md)             | Goal 标准：结构、模板、评分、Lint 规则                                       |
| [03-pipeline.md](03-pipeline.md)                       | 统一管线与状态机：完整管线、12 态状态机、完整链路示例                         |
| [04-gates.md](04-gates.md)                             | Gate 体系：G0-G11 定义、类型、结构、结果                                     |
| [05-layer-standards.md](05-layer-standards.md)         | 各层标准：Spec / Design / Matrix / Tasks / Plan / Prompt / Code / Test      |
| [06-dod.md](06-dod.md)                                 | 分层 DoD：Task / Issue / Goal / Release / Retrospective 完成标准            |
| [07-id-system.md](07-id-system.md)                     | ID 系统：格式、规则、旧格式兼容                                              |
| [08-quality-gates.md](08-quality-gates.md)             | 质量门禁：DoR/DoD、评分体系、孤儿检查                                        |
| [09-templates.md](09-templates.md)                     | 模板库：端到端模板、YAML 化、JSON 化、仓库目录结构                           |
| [10-lint-rules.md](10-lint-rules.md)                   | 自动化检查：Goal / Spec / Matrix / Prompt / Code Lint 规则                   |
| [11-ai-collaboration.md](11-ai-collaboration.md)       | AI 协作：PromptOps、Context Package、Prompt Chain、Code Boundary             |
| [12-operations.md](12-operations.md)                   | 运营管理：变更管理、版本管理、角色分工、RACI、标准操作流程、制品版本管理     |
| [13-runtime-engine.md](13-runtime-engine.md)           | 运行引擎：执行模式、对象模型、优先级评分、Evidence、失败预算、人工审批、变更传播 |
| [14-agent-protocols.md](14-agent-protocols.md)         | Agent 协议：Agent Team、Worktree 隔离、Context Recovery                        |
| [15-registry.md](15-registry.md)                       | Registry 系统：Goal / Task / Issue / Release / Risk / Decision 7 个子系统     |
| [16-ci-cd.md](16-ci-cd.md)                             | CI/CD 与工程实践：CI Gates、执行阶段、反模式、x.go 规则、Facts/Assumptions/Unknowns |
| [17-risk-and-decisions.md](17-risk-and-decisions.md)   | 风险、决策与发布：Risk Register、ADR、Release Manifest、落地计划              |
| [18-maturity.md](18-maturity.md)                       | 成熟度模型：L0-L5 升级路径、体系度量、故障排查、非代码场景适配                |
| [19-self-improving.md](19-self-improving.md)           | Self-improving 复利机制：Patch 系统、多团队协作、体系演进记录                |
| [tools/](tools/README.md)                              | 可执行工具：Gate 检查、Matrix 生成、Evidence 收集、Lint 脚本                  |
| [20-metrics-evidence.md](20-metrics-evidence.md)       | 指标与证据闭环：Metrics Review、Validation Gate、Gap Report、Evidence Graph |
| [21-controlled-rsi.md](21-controlled-rsi.md)           | 受控递归改进：Controlled RSI、改进循环、不变量、策略边界                    |
| [22-delivery-os.md](22-delivery-os.md)                 | Delivery OS：五个运行时、Workflow-as-Code、Compiler、控制平面               |
| [23-workflow-governance-checks.md](23-workflow-governance-checks.md) | 工作流治理检查：Drift Checks、Test Deletion Guard、Workflow Test Pyramid、Release Simulation |

## 复杂度分级

| 复杂度 | 特征                 | 推荐流程                                   |
| ------ | -------------------- | ------------------------------------------ |
| XS     | 小修复，低风险       | Goal + Task + Test                         |
| S      | 小功能，影响单模块   | Goal + Spec + Task + Code                  |
| M      | 中型功能，影响多模块 | Goal + Spec + Matrix + Tasks + Plan + Code |
| L      | 大功能，跨团队       | 全流程                                     |
| XL     | 架构级变化，高风险   | 全流程 + RFC + 风险评审 + 灰度计划         |

## 最小闭环

```text
Goal → Spec → Task → Test → Code
```

> 这是简化版，完整管线定义见 [03-pipeline.md](03-pipeline.md)。

## 增强闭环

```text
Goal → Spec → Matrix → Tasks → Plan → Prompt → Code → Test → Matrix Update
```

> Matrix 是横切制品，详见 [05-layer-standards.md §4.3](05-layer-standards.md#43-matrix-标准)。

## 最理想闭环

```text
Goal → Spec → Design → Plan → Tasks → Prompt → Code → Test → Review → Release → Retrospective → Metric Validation → Controlled RSI → Workflow Governance
```

> 完整 11 层管线定义见 [03-pipeline.md](03-pipeline.md)。

Code 完成并不是终点，真正的终点是：**上线后指标证明 Goal 被达成。**

高级形态下，这条链路会收敛为 Delivery OS：用 Matrix 作为控制平面，用 Evidence Graph 证明交付，用 Metrics Validation Gate 验证目标，用 Controlled RSI 持续修正工作流本身，并用 Workflow Governance 防止流程改进失控。
