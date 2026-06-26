# Goal 驱动交付体系

> **没有 Goal 的代码是无源代码；没有 Matrix 的需求容易丢失；没有 Test 的实现无法证明完成；没有 Metrics 的上线无法证明有价值。**

本文档集定义了一套完整的 **Goal 驱动交付体系**，用于确保每一行代码都能追溯到一个可验证的业务目标。

权威边界入口见 [00-authority-map.md](00-authority-map.md)。本文档是索引和概览；状态枚举、Gate、ID、Registry、Matrix、Evidence、配置与运行态边界均以权威映射指向的 SSOT 为准。

## 新 Agent 执行入口

首次执行 Goal Delivery OS 的 Agent MUST 按以下顺序建立上下文：

1. 先读 [00-authority-map.md](00-authority-map.md)，确认 SSOT、投影和运行态边界。
2. 再读本 README 的“工作流全景”和“可执行入口”，确认主流程与本地命令。
3. 需要实际推进任务时读 [25-execution-guide.md](25-execution-guide.md)，按执行检查单进入 `preflight`、`validate`、`gate`、`release` 或 `ci`。
4. 需要修改工作流资产时读 [21-controlled-rsi.md](21-controlled-rsi.md)，确认是否属于自动允许、提案、审批或禁止范围。
5. 触碰 Constitution、CI、agent 配置、schema 投影、Release Gate、Rollback、Incident 或 P0/P1 验收语义时，MUST 生成 Change Request，不得直接放宽规则。

Agent 执行时 MUST 保持 Matrix 为横切追溯制品；MUST 使用 Evidence 证明 Done；MUST 通过 Gate 决定是否阻断；MUST 将无法验证的判断标记为 Hypothesis。

## 核心公式

> **Goal = 目标动作 + 结果对象 + 衡量指标 + 目标值 + 截止时间**

满足 SMART 原则：Specific、Measurable、Achievable、Relevant、Time-bound。

## 工作流全景

> 完整管线（11 层）和四轴状态模型定义见 [03-pipeline.md#完整管线](03-pipeline.md#1-完整管线)、[四轴状态模型](03-pipeline.md#2-四轴状态模型)。

唯一主流程（完整 11 层）：

```text
Goal 定义结果 → Spec 定义需求 → Design 定义方案 → Plan 定义顺序 → Tasks 拆解执行 → Prompt 驱动执行 → Code 完成交付 → Test 验证实现 → Review 审查闭环 → Release 发布 → Retrospective 复盘改进
```

各层核心问题和输出物见 [03-pipeline.md §1 完整管线](03-pipeline.md#1-完整管线)。

Matrix（追溯矩阵）是横切追溯制品，贯穿主流程但不作为主流程阶段，也不写入主流程箭头。它在 Spec 后可初始化，并随 Design、Plan、Tasks、Prompt、Code、Test、Evidence 更新。详见 [05-layer-standards.md §9](05-layer-standards.md#9-matrix-横切标准)。

## 可执行入口

`docs/goal` 的默认本地工作流入口是：

```bash
bash docs/goal/tools/goal-workflow.sh preflight
bash docs/goal/tools/goal-workflow.sh validate
bash docs/goal/tools/goal-workflow.sh gate
bash docs/goal/tools/goal-workflow.sh release
bash docs/goal/tools/goal-workflow.sh ci
```

执行口径：

- `preflight`：工具编译、Shell 语法、规则漂移和文档 lint。
- `validate`：`preflight` + strict 控制面验证 + Matrix check-only，是 PR 前默认检查。
- `gate`：`validate` + Gate 制品就绪检查，适用于已有 `.config/goal` 运行制品的仓库。
- `release`：发布前硬门禁，串联 Gate 检查与 Goal Release Gate；失败时不得 tag、部署或宣称 Release 通过。
- `ci`：CI 聚合入口，运行 `validate`、工具链自测，并在运行制品完整时自动执行 Gate 检查。

底层脚本仍保留为调试入口；日常执行优先使用 `goal-workflow.sh`，避免不同文档、CI 与人工命令产生漂移。

## 统一配置中心

`.config/goal/` 是 Goal 控制面的可提交配置、schema 与审计快照目录；本地运行态、锁、缓存、local 覆盖和日志不作为权威制品，应写入 `.config/goal/runtime/`、`.omx/state/` 或对应 ignored 目录。

```text
.config/goal/
├── README.md                    # 目录索引
├── schema/
│   └── rules.yaml               # docs/goal/ 权威规则的机器可读投影
├── registry/                    # Registry 子系统（6 个文件）
│   ├── goals.yaml              # Goal Registry
│   ├── tasks.yaml              # Task Registry
│   ├── issues.yaml             # Issue Registry
│   ├── releases.yaml           # Release Registry
│   ├── risks.yaml              # Risk Registry
│   └── decisions.yaml          # Decision Registry
├── matrix/
│   └── matrix.yaml             # Traceability Matrix
├── gates/
│   └── state.yaml              # Gate 状态（G0-G11）
├── pipeline/
│   └── state.yaml              # Pipeline 状态机
├── evidence/
│   └── EVID-*.md               # Evidence 文件
├── prompts/
│   └── TASK-*/                 # Prompt 版本
│       ├── v1.md
│       └── prompt-meta.yaml
└── runtime/                    # 本地运行态，忽略提交
```

**Agent 职责分工**：

| Agent               | 维护文件                                 | 职责                                       |
| ------------------- | ---------------------------------------- | ------------------------------------------ |
| goal-spec           | `registry/*.yaml`, `pipeline/state.yaml` | Goal/Task/Issue/Release/Risk/Decision 注册 |
| goal-matrix         | `matrix/matrix.yaml`                     | 追溯矩阵生成与维护                         |
| goal-reviewer       | `gates/state.yaml`                       | Gate 状态检查与记录                        |
| goal-prompt-builder | `prompts/TASK-*/`                        | Context Package 构建与版本管理             |
| goal-evidence       | `evidence/EVID-*.md`                     | 证据收集与验证                             |

## 与 docs/spec、module/ 和 docs/governance/ 的同步边界

Goal 体系定义目标交付规则、状态机、Gate、Registry 和证据闭环；`docs/spec/` 定义由 Goal 体系需求派生的产品级或工具级规格；`module/` 定义模块规格制品；`docs/governance/` 定义 Spec → Code 流程、模板、门禁与评分规则。四者分工如下：

| 范围                                                                 | 权威位置                                                                        | 同步规则                                                                                                                                                                                     |
| -------------------------------------------------------------------- | ------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Goal 方法、Gate、Registry、Evidence                                  | `docs/goal/` + `.config/goal/`                                                  | 描述目标、状态、门禁和运行证据，不复制模块完整规格                                                                                                                                           |
| 产品/工具级 Spec                                                     | `docs/spec/`                                                                    | 由 `docs/goal/` 的 Goal、Spec、Gate、Matrix、Evidence、Registry、Lint 等需求派生；不作为模块事实源，不新增 Goal 体系语义                                                                     |
| 模块 Feature Spec、Traceability、Task、Prompt 输入与模块级 Goal 文档 | `module/` | 全版本化结构：`v{ver}/` 下自包含管线快照（goal/spec/design/plan/tasks/prompt/evidence）；跨版本层：matrix/gate/schema；根：README.md CHANGELOG.md；Code 在 `/home/{module}` |
| Spec → Code 模板、生命周期、门禁、评分与仲裁规则                     | `docs/governance/`                                                              | 作为流程与治理规则事实源，被模块制品、agent 和 CI 引用                                                                                                                                       |
| 根目录索引与三平台 agent 入口                                        | `README.md`、`ARCHITECTURE.md`、`STATUS.md`、`.claude/`、`.codex/`、`.copilot/` | 只同步入口、路径和门禁口径，不成为新的 SSOT                                                                                                                                                  |

迁移后不得恢复旧 `specs/` 目录；若 Goal 文档、agent 配置或 CI 脚本需要引用模块规格制品，应指向 `module/` 或 `docs/governance/`；若引用 Goal 体系自身工具或控制面规格，应指向 `docs/spec/`，且必须声明 Source Goal / Source Requirement 与对应 `docs/goal/` 权威来源。

模块采用全版本化结构：`v{版本}/` 下自包含管线快照（goal/spec/design/plan/tasks/prompt/evidence），每个版本目录即该版本交付全貌；跨版本层 `matrix/gate/schema` 存于模块根；根文件 `README.md` `CHANGELOG.md`。`.config/goal/` 为跨模块控制面 SSOT。

模块实现代码不属于 `module/{module}/`；本地实现、测试和源码修改统一在 `/home/{module}` 对应 GitHub 仓库中完成，`module/{module}/` 只同步规格、任务、计划、Prompt 和证据引用。

## 文档索引

| 文件                                                                           | 内容                                                                                                        |
| ------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------- |
| [00-authority-map.md](00-authority-map.md)                                     | 权威边界：SSOT、投影、配置控制面与本地运行态边界                                                            |
| [GLOSSARY.md](GLOSSARY.md)                                                     | 术语表：Goal 驱动交付体系核心术语定义                                                                       |
| [00-quickstart.md](00-quickstart.md)                                           | 快速开始：5 分钟理解体系、端到端案例、模式选择决策树、常见问题                                              |
| [01-methodology.md](01-methodology.md)                                         | 核心方法论：工作流原理、输入输出、闭环逻辑                                                                  |
| [02-goal-standard.md](02-goal-standard.md)                                     | Goal 标准：结构、模板、评分、Lint 规则                                                                      |
| [03-pipeline.md](03-pipeline.md)                                               | 统一管线与状态机：完整管线、13 个正常阶段状态、8 个异常/控制状态、完整链路示例                              |
| [04-gates.md](04-gates.md)                                                     | Gate 体系：G0-G11 定义、类型、结构、结果                                                                    |
| [05-layer-standards.md](05-layer-standards.md)                                 | 主流程层级与 Matrix 横切标准：Spec / Design / Plan / Tasks / Prompt / Code / Test                           |
| [06-dod.md](06-dod.md)                                                         | 分层 DoR/DoD：Goal / Spec / Design / Plan / Tasks / Prompt / Code / Test / Review / Release / Retrospective |
| [07-id-system.md](07-id-system.md)                                             | ID 系统：格式、规则、旧格式兼容                                                                             |
| [08-quality-gates.md](08-quality-gates.md)                                     | 质量门禁：DoR/DoD、评分体系、孤儿检查                                                                       |
| [09-templates.md](09-templates.md)                                             | 模板库：端到端模板、YAML 化、JSON 化、仓库目录结构                                                          |
| [10-lint-rules.md](10-lint-rules.md)                                           | 自动化检查：Goal / Spec / Matrix / Prompt / Code Lint 规则                                                  |
| [11-ai-collaboration.md](11-ai-collaboration.md)                               | AI 协作：PromptOps、Context Package、Prompt Chain、Code Boundary                                            |
| [12-operations.md](12-operations.md)                                           | 运营管理：变更管理、版本管理、角色分工、RACI、标准操作流程、制品版本管理                                    |
| [13-runtime-engine.md](13-runtime-engine.md)                                   | 运行引擎：执行模式、对象模型、优先级评分、Evidence、失败预算、人工审批、变更传播                            |
| [14-agent-protocols.md](14-agent-protocols.md)                                 | Agent 协议：Agent Team、Worktree 隔离、Context Recovery                                                     |
| [15-registry.md](15-registry.md)                                               | Registry 系统：Goal / Task / Issue / Release / Risk / Decision 6 个业务 Registry 文件及横切运行制品         |
| [16-ci-cd.md](16-ci-cd.md)                                                     | CI/CD 与工程实践：CI Checks、执行阶段、反模式、x.go 规则、Facts/Assumptions/Unknowns                        |
| [17-risk-and-decisions.md](17-risk-and-decisions.md)                           | 风险、决策与发布：Risk Register、ADR、Release Manifest、落地计划                                            |
| [18-maturity.md](18-maturity.md)                                               | 成熟度模型：L0-L5 升级路径、体系度量、故障排查、非代码场景适配                                              |
| [19-self-improving.md](19-self-improving.md)                                   | Self-improving 复利机制：Patch 系统、多团队协作、体系演进记录                                               |
| [tools/](tools/README.md)                                                      | 工具脚本：统一工作流入口、Gate 制品就绪检查、Matrix 生成、Evidence 收集、Lint 与漂移检查                    |
| [20-metrics-evidence.md](20-metrics-evidence.md)                               | 指标与证据闭环：Metrics Review、Validation Check、Gap Report、Evidence Graph                                |
| [21-controlled-rsi.md](21-controlled-rsi.md)                                   | 受控递归改进：Controlled RSI、改进循环、不变量、策略边界                                                    |
| [22-delivery-os.md](22-delivery-os.md)                                         | Delivery OS：五个运行时、Workflow-as-Code、Compiler、控制平面                                               |
| [23-workflow-governance-checks.md](23-workflow-governance-checks.md)           | 工作流治理检查：Drift Checks、Test Deletion Guard、Workflow Test Pyramid、Release Simulation                |
| [24-standard-unification-analysis.md](24-standard-unification-analysis.md)     | 标准统一深度分析：ID、schema、状态、Matrix、Evidence、Gate 与工具一致性                                     |
| [25-execution-guide.md](25-execution-guide.md)                                 | 执行指南：Agent 读序、命令入口、阻断规则、Change Request 与停止条件                                         |
| [26-rsi-full-standard.md](26-rsi-full-standard.md)                             | RSI 完整标准索引（拆分版见 rsi-standard/ 子目录，30 章节）                                                  |
| [agent-cross-platform-compatibility.md](agent-cross-platform-compatibility.md) | 三平台 Agent 兼容性报告                                                                                     |
| [deploy/README.md](deploy/README.md)                                           | 单仓库最小部署包：5 分钟采纳、3 级指南、CI 模板                                                             |
| [deploy/roadmap.md](deploy/roadmap.md)                                         | Delivery OS 5 Phase 落地路线图                                                                              |
| [rsi-standard/](rsi-standard/)                                                 | RSI 完整标准（30 章节，RSI-SG-001）                                                                         |
| [schema/](schema/)                                                             | 8 个 YAML Schema（4 数据 + 4 契约）                                                                         |
| [change-requests/](change-requests/)                                           | 受保护资产或跨控制面漂移的提案记录；不是当前强规则源                                                        |

## 复杂度分级

| 复杂度 | 特征                 | 推荐流程                                                                      |
| ------ | -------------------- | ----------------------------------------------------------------------------- |
| XS     | 小修复，低风险       | Goal + Plan + Tasks + Code + Test                                             |
| S      | 小功能，影响单模块   | Goal + Spec + Design + Plan + Tasks + Code + Test                             |
| M      | 中型功能，影响多模块 | Goal + Spec + Design + Plan + Tasks + Prompt + Code + Test（Matrix 横切维护） |
| L      | 大功能，跨团队       | 全流程                                                                        |
| XL     | 架构级变化，高风险   | 全流程 + RFC + 风险评审 + 灰度计划                                            |

## 最小闭环

```text
Goal → Plan → Tasks → Code → Test → Review
```

> 这是低风险裁剪版，只能省略部分层级，不能改变主流程相对顺序。完整管线定义见 [03-pipeline.md#完整管线](03-pipeline.md#1-完整管线)。

## 增强闭环

```text
Goal → Spec → Design → Plan → Tasks → Prompt → Code → Test → Review → Release → Retrospective
```

> Matrix 在 Spec 后初始化，并在 Plan、Tasks、Prompt、Code、Test、Evidence 变化时横切更新；Matrix 不作为主流程阶段。详见 [05-layer-standards.md §9](05-layer-standards.md#9-matrix-横切标准)。

## 最理想闭环

在增强闭环的 11 层主流程基础上，叠加三层治理增强，形成完整 Delivery OS：

```text
Goal → Spec → Design → Plan → Tasks → Prompt → Code → Test → Review → Release → Retrospective
                                                                                      ↓
                                                               Metric Validation ← 指标验证目标
                                                               Controlled RSI ← 持续修正工作流
                                                               Workflow Governance ← 防止改进失控
```

> 完整 11 层管线定义见 [03-pipeline.md#完整管线](03-pipeline.md#1-完整管线)。Metric Validation、Controlled RSI、Workflow Governance 是 Retrospective 之后的治理增强，不属于主流程阶段。

Code 完成并不是终点，真正的终点是：**上线后指标证明 Goal 被达成。**

高级形态下，这条链路会收敛为 Delivery OS：用 Matrix 作为控制平面，用 Evidence Graph 证明交付，用 Metrics Validation Check 验证目标，用 Controlled RSI 持续修正工作流本身，并用 Workflow Governance 防止流程改进失控。
