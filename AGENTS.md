# 仓库指南

## 最高指令源

当本文件与 `CONSTITUTION.md` 冲突时，以 `CONSTITUTION.md` 为准。`CONSTITUTION.md` 是系统级最高治理文件（§0-§19），定义了分支纪律、设计原则、模块边界、交付管线和受控递归改进。本文件是代理编排与管线操作的参考文档。

## 项目结构与模块组织

本仓库是 `ZoneCNH/ZoneCNH` 个人主页与架构索引，不是应用模块。根目录应保持精简，并以文档为主：

- `README.md` 展示公开简介、技术栈、分层架构摘要和核心项目链接。
- `ARCHITECTURE.md` 是架构图、依赖拓扑、模块状态表和建议实现顺序的权威文档。
- `kernel`、`market-data`、`factor-engine`、`x.go` 等模块位于独立 GitHub 仓库；不要把它们的源码树加入本仓库。
- 模块代码的本地工作目录统一为 `/home/{module}`，其中 `{module}` 与 GitHub 仓库名一致；本仓库只引用这些路径，不复制或收纳模块源码。

## 构建、测试与开发命令

本仓库仅包含文档，没有本地构建系统。提交前使用轻量检查：

- `rg "market-data|risk-engine" README.md ARCHITECTURE.md` 查找受影响的架构引用。
- `git diff --check` 检查尾随空格和补丁格式问题。
- `git status --short` 确认只修改了预期文档文件。
- `git log -5 --pretty=format:%s` 查看最近提交标题风格。

如本地已有 Markdown linter，可对 `README.md`、`ARCHITECTURE.md` 和 `AGENTS.md` 运行检查；不要仅为 lint 引入包管理器或新依赖。

## 编写风格与命名规范

所有回复和文档默认使用中文。Markdown 应使用清晰标题、紧凑表格和短说明。保留英文模块名与技术名词，例如 `domain-market`、`order-engine`，项目名统一使用 kebab-case。域标签保持一致：基座、数据域、分析域、决策域、执行域、入口、横切。

编辑表格时，除非能同时提升 `README.md` 和 `ARCHITECTURE.md` 的可读性，否则保持列顺序稳定。

## 测试规范

测试即文档校验。确认架构变更在两个根文档中保持一致，链接指向正确的 `https://github.com/ZoneCNH/...` 仓库，状态或版本更新不与依赖图冲突。

大规模表格修改后，使用 `git diff -- README.md ARCHITECTURE.md` 对比前后内容。

## 提交与合并请求规范

近期提交使用简洁的约定式标题，尤其是 `docs: ...`。沿用该模式，例如 `docs: 更新宏观数据提供者状态`。每个提交只聚焦一个文档主题。

合并请求应说明架构或状态变化，列出受影响文件，并标注状态发生变化的关联模块仓库。仅当 GitHub 主页渲染布局变化时附截图。

## 安全与配置提示

不要提交凭证、交易所 API key、账户 ID、私有端点或实盘交易配置。本仓库只应包含公开架构说明和项目元数据。

## 分支纪律

> 详见 `CONSTITUTION.md` 第零条。本节约定优先于以下所有管线规则。

- **禁止**在 `main` 分支上直接编辑文件或提交变更。
- **所有分支必须从 `main` HEAD 创建**。创建前必须先 `git fetch origin && git rebase origin/main` 确保本地 main 为最新。禁止从其他 feature branch 或旧 commit 拉取新分支。
- 所有开发工作必须通过 `git worktree` 或 feature branch 进行。
- 工作完成后通过 PR 或 merge 合入 main，随后清理 worktree。

Agent 创建分支前的检查清单：

1. 确认当前不在 main 分支
2. 执行 `git fetch origin && git rebase origin/main`
3. 确认 main HEAD 与 `origin/main` 一致
4. 从 main HEAD 创建新分支或 worktree
5. 记录创建来源 commit SHA

## Spec 开发管线

Spec 编写完成后，不是直接写代码，而是按管线推进：Spec → Review → Approve → Matrix → Tasks → Plan → Prompt → Code → 验收 → Ship。详见 `docs/governance/DEVELOPMENT-WORKFLOW.md`。

### Agents — Spec → Code 管线

本仓库配置了四源代理/评分体系（Claude Code + Codex + Copilot CLI + rules），功能角色相同，配置格式不同：

| 平台        | 配置目录           | 模型                       | 格式                 |
| ----------- | ------------------ | -------------------------- | -------------------- |
| Claude Code | `.claude/agents/`  | Sonnet / Opus              | Markdown frontmatter |
| Codex       | `.codex/agents/`   | GPT-5.5 + reasoning effort | TOML                 |
| Copilot CLI | `.copilot/agents/` | Copilot/Claude 模型        | Markdown prompt      |

运行时状态目录按平台隔离：Claude 使用 `.omc/state/pipeline/`，Codex 使用 `.omx/state/pipeline/`，Copilot 使用 `.copilot/state/pipeline/`。

| Agent                | 流水线阶段  | 用途                                                                                                    | 可改文件           | 可写代码 | Claude 模型 | Codex reasoning |
| -------------------- | ----------- | ------------------------------------------------------------------------------------------------------- | ------------------ | -------- | ----------- | --------------- |
| `spec`               | S1-Spec     | 编写或修订项目 spec，补齐 23 节结构与追溯链                                                             | Spec 文档          | 否       | Opus        | high            |
| `spec-review`        | S1-Review   | 对抗性审查 spec，作为结构评分证据与参考                                                                 | 无                 | 否       | Opus        | high            |
| `matrix`             | S2-Matrix   | 生成或校验需求追溯矩阵，闭合 FR/BR/AC/TC 链条                                                           | Traceability 文档  | 否       | Sonnet      | high            |
| `task-split`         | S3-Tasks    | 将 Approved Spec 和 Matrix 拆成可执行 Task Spec                                                         | Task / Matrix 文档 | 否       | Sonnet      | high            |
| `task-planner`       | S4-Plan     | 生成实现顺序、依赖、验证命令和风险计划                                                                  | Plan 文档          | 否       | Opus        | high            |
| `prompt-builder`     | S5-Prompt   | 为单个 Task 生成 Context Packet 与开发 Prompt                                                           | Prompt 文档        | 否       | Sonnet      | medium          |
| `task-executor`      | S6-Code     | 按单个 Task 和 Prompt 编写代码与测试，验证后回填证据                                                    | Task 指定源码/测试 | 是       | Sonnet      | high            |
| `*-structural-score` | S1-S6 Score | 每阶段结构性问题分析，Claude / Codex / Copilot + rules 四源输出评分、红线和扣分账本                     | 无                 | 否       | Opus        | high            |
| `pipeline-arbiter`   | S1-S6 Gate  | 汇总四源评分（`claude/codex/copilot/rules`），计算 `composite_score = min(...)`，判定是否达到 98 分门禁 | Verdict / Attempts | 否       | Opus        | high            |
| `code-reviewer`      | —           | 代码审查                                                                                                | 无                 | 否       | —           | —               |
| `tdd-guide`          | —           | 测试驱动开发                                                                                            | 测试 / 必要实现    | 是       | —           | —               |

管线流程：

```text
每阶段通用门禁：

executor → [claude scorer | codex scorer | copilot scorer | rules scorer]（agent team 并行）
        → pipeline-arbiter（composite_score = min(claude.score, codex.score, copilot.score, rules.score)；composite_score >= 98 且无红线、无 LLM 低置信度、无异常 LLM 分差或 rules 异构分歧）
        → 下一阶段

规范阶段顺序：

Spec → Matrix → Tasks → Plan → Prompt → Code
```

每个阶段都必须做结构性问题分析和四源评分。任一评分源低于 98、触发红线、任一 LLM 低置信度、三 LLM 分差超过阈值或 rules 与 LLM 中位数异构分歧过大，均不得进入下一阶段。Spec 阶段由 `pipeline-arbiter` 在 pass 后自动翻转 `Status: Approved`；`spec-review` 仅作为对抗性参考证据，不构成独立门禁。评分方法论详见 `docs/governance/STRUCTURAL-SCORING.md`，仲裁协议详见 `docs/governance/scoring/ARBITER-PROTOCOL.md`。

管线支持有界递归自改进：同阶段最多 3 次自动修复，失败后回退上游；全链路默认最多 18 次 gate fail，耗尽后写出 `pipeline_blocked` 与 `PIPELINE-RETROSPECTIVE.md`，不得无限重写 Spec。工作流、rubric、agent、arbiter 等受保护文件的改进必须作为 `docs/governance/improvements/{YYYYMMDD}-{slug}/SPEC.md` 进入同一条 98 分管线，并遵守 `CONSTITUTION.md` 第十四条。

### OMX Pipeline Skill

已配置 OMX 技能 `<runtime>/skills/pipeline/SKILL.md`，支持一键触发完整管线：

| 触发方式                                         | 说明             |
| ------------------------------------------------ | ---------------- |
| `pipeline {module}`                              | 从头启动完整管线 |
| `pipeline {module} --from spec-structural-score` | 从某个阶段恢复   |
| `pipeline {module} --stage matrix`               | 只执行单个阶段   |
| `开发管线 {module}`                              | 中文触发         |

管线状态记录在 `<runtime>/state/pipeline/{module}.json`。

### Spec → Code Workflow Skill

本仓库新增项目内端到端工作流入口，用于把单个模块从规格推进到一个可验证的编码任务：

```text
Spec → Matrix → Tasks → Plan → Prompt → Code
```

| 平台        | 触发方式                               | 定义文件                                    |
| ----------- | -------------------------------------- | ------------------------------------------- |
| Codex       | `$spec-code-pipeline {module}`         | `.codex/skills/spec-code-pipeline/SKILL.md` |
| Claude Code | `/project:spec-code-pipeline {module}` | `.claude/commands/spec-code-pipeline.md`    |
| Copilot CLI | `/project:spec-code-pipeline {module}` | `.copilot/commands/spec-code-pipeline.md`   |

该入口要求每个阶段都通过四源评分门禁：`composite_score = min(claude, codex, copilot, rules) >= 98` 且无红线、无 LLM 低置信度、LLM 分差与 rules 异构分歧在阈值内。Spec 的 `Status: Approved` 由 arbiter pass 后自动翻转；`spec-review` 仅作为额外对抗性证据，不构成独立门禁。

### 关键文档

| 文档                                      | 用途                                                             |
| ----------------------------------------- | ---------------------------------------------------------------- |
| `module/README.md`                        | 规格库索引                                                       |
| `docs/governance/DEVELOPMENT-WORKFLOW.md` | Spec → Ship 完整管线                                             |
| `docs/governance/SPEC-TEMPLATE.md`        | 23 节 spec 模板                                                  |
| `docs/governance/TASK-TEMPLATE.md`        | Task spec 模板                                                   |
| `docs/governance/LIFECYCLE.md`            | Spec 状态流转规则                                                |
| `docs/governance/TRACEABILITY.md`         | 需求追踪矩阵规范；具体矩阵位于 `module/{module}/TRACEABILITY.md` |
| `docs/governance/DEFINITION-OF-READY.md`  | 进入开发的前置条件                                               |
| `docs/governance/DEFINITION-OF-DONE.md`   | 完成验收条件                                                     |
| `CONSTITUTION.md`                         | 最高治理权威（§0-§19，含分支纪律、设计原则、交付管线、CRI）      |
| `module/FOUNDATION-DEPS.yaml`             | Foundation 依赖矩阵（机器可读，规定允许/禁止的依赖边与特殊约束）  |

## Goal 驱动交付体系

Goal 驱动交付体系确保每一行代码都能追溯到一个可验证的业务目标。详见 `docs/goal/` 目录。

### Agents — Goal 管线

| Agent                 | 职责                       | 维护文件                                                           | 模型   |
| --------------------- | -------------------------- | ------------------------------------------------------------------ | ------ |
| `goal-spec`           | Goal/Spec/Design/Plan 编写 | `.config/goal/registry/*.yaml`, `.config/goal/pipeline/state.yaml` | Opus   |
| `goal-reviewer`       | 对抗性审查                 | `.config/goal/gates/state.yaml`                                    | Opus   |
| `goal-matrix`         | 追溯矩阵管理               | `.config/goal/matrix/matrix.yaml`                                  | Sonnet |
| `goal-prompt-builder` | Context Package 构建       | `.config/goal/prompts/TASK-*/`                                     | Sonnet |
| `goal-evidence`       | 证据收集与验证             | `.config/goal/evidence/EVID-*.md`                                  | Sonnet |

### 统一配置中心

`.config/goal/` 是 Goal 体系的控制面配置、schema 与可审查快照目录。权威边界见 `docs/goal/00-authority-map.md`。本地临时运行态进入 `.config/goal/runtime/` 或 `.omx/state/`。

```text
.config/goal/
├── README.md          # 目录索引
├── schema/            # 从 SSOT 镜像出的校验规则
│   └── rules.yaml
├── registry/          # Registry 子系统（6 个文件）
├── matrix/            # 追溯矩阵
├── gates/             # Gate 状态（G0-G11）
├── pipeline/          # Pipeline 状态快照
├── evidence/          # Evidence 文件
├── prompts/           # Prompt 版本
└── runtime/           # 本地运行态与恢复缓存（不作为规范权威）
```

### Goal 管线流程

```text
Goal → Spec → Design → Plan → Tasks → Prompt → Code → Test → Review → Release → Retrospective
```

Matrix 是横切追溯制品，贯穿所有阶段但不作为主流程阶段。

### 模块级 Goal 文档命名规则

- 模块级 Goal 文档固定为 `module/{module}/goal.md`。
- 禁止新建 `module/{module}/goal/` 目录、`module/{module}/goal/1.md` 或 `goal/*.md` 多文件槽位；未来如需多版本 Goal，必须先更新 `docs/goal/00-authority-map.md`、`.config/goal/schema/rules.yaml` 和 `module/README.md`。

### 关键文档

| 文档                            | 用途                                   |
| ------------------------------- | -------------------------------------- |
| `docs/goal/00-authority-map.md` | 权威映射：SSOT、投影、配置与运行态边界 |
| `docs/goal/README.md`           | Goal 体系总览                          |
| `docs/goal/00-quickstart.md`    | 5 分钟快速开始                         |
| `docs/goal/03-pipeline.md`      | 管线与状态机                           |
| `docs/goal/04-gates.md`         | Gate 体系（G0-G11）                    |
| `docs/goal/15-registry.md`      | Registry 系统                          |
| `.config/goal/README.md`        | 配置中心索引                           |
