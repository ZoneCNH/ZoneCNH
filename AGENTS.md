# 仓库指南

> **工作流快速导航**：`docs/workflow/README.md` — 双管线统一入口、阶段对应表、四源评分速览、快速通道。

## 最高指令源

当本文件与 `CONSTITUTION.md` 冲突时，以 `CONSTITUTION.md` 为准。`CONSTITUTION.md` 是系统级最高治理文件（§0-§19），定义了分支纪律、设计原则、模块边界、交付管线和受控递归改进。本文件是代理编排与管线操作的参考文档。

## 项目结构与模块组织

本仓库是 `ZoneCNH/ZoneCNH` 个人主页与架构索引，不是应用模块。根目录应保持精简，并以文档为主：

- `README.md` 展示公开简介、技术栈、分层架构摘要和核心项目链接。
- `ARCHITECTURE.md` 是向后兼容重定向存根；架构内容已拆分迁移至 `docs/architecture/`（01-overview / 02-domain-layers / 03-boundaries / 04-principles / 05-foundation / 06-dataflow / 07-three-engines / 08-contracts / adr）。
- `kernel`、`market_data`、`factor_engine`、`x.go` 等模块位于独立 GitHub 仓库；不要把它们的源码树加入本仓库。
- 模块代码的本地工作目录统一为 `/home/{module}`，其中 `{module}` 与 GitHub 仓库名一致；本仓库只引用这些路径，不复制或收纳模块源码。
- `module/registry.yaml` 是模块身份与治理状态的统一注册表 SSOT（单一权威源），覆盖全域模块；与 `module/FOUNDATION-DEPS.yaml`（依赖矩阵 SSOT）和 `.foundationx/status/index.json`（成熟度事实 SSOT）三权分立，引用而非重复。治理规则见 `docs/governance/MODULE-GOVERNANCE.md`。
- 本仓库的 feature worktree 统一放在 `/home/{module}/.worktree/workspaces/<branch-name>`，其中 `{module}` 是仓库目录名，`<branch-name>` 按 Git 分支名原样落盘（仅去掉 `refs/heads/` 前缀，`feat/...` 会自然形成嵌套目录）；纯文档仓库的仓库根 checkout 只在 feature branch 承载时可视为例外，不算新增 worktree。禁止再把新 worktree 放在仓库根外的零散目录。

## 制品归属（Spec 制品 vs 运行时文档）

各类制品有明确的仓归属，避免 spec 制品错放到 runtime 仓。runtime 仓通过自身 `boundary-gates.sh` §15 gate 机器强制；主仓通过下表约定与 `ADR-TEMPLATE.md` 归属字段约束。

| 制品类型 | 归属仓 | 路径 |
| -------- | ------ | ---- |
| ADR（架构决策记录） | ZoneCNH 主仓 | `module/{模块}/ADR-NNN-*.md`（模块专属）或 `module/ADR-NNN-*.md`（跨模块治理类） |
| SPEC / TRACEABILITY / goal.md | ZoneCNH 主仓 | `module/{模块}/` |
| FEATURES / ACCEPTANCE / IMPLEMENTATION-PLAN / CHANGELOG / RULES / STANDARD | ZoneCNH 主仓 | `module/{模块}/` |
| README / BOUNDARY-GATES / AGENTS | 各 runtime 仓 | 仓根 |
| 代码 / 测试 | 各 runtime 仓 | `internal/` `cmd/` `pkg/` 等 |

**规则**：runtime 仓的 `module/` 目录只承载运行时文档与代码，不得承载 ADR/SPEC 等任何 spec 制品。binance runtime 仓的 `scripts/boundary-gates.sh` §15 gate 扫描 `module/` 下禁止文件名（`ADR-*.md`、`SPEC*.md`、`TRACEABILITY.md`、`goal.md`、`FEATURES.md`、`ACCEPTANCE.md` 等），命中即 CI FAIL。

## 构建、测试与开发命令

本仓库仅包含文档，没有本地构建系统。提交前使用轻量检查：

- `rg "market_data|riskx" README.md docs/architecture/01-overview.md docs/architecture/05-foundation.md` 查找受影响的架构引用。
- `git diff --check` 检查尾随空格和补丁格式问题。
- `git status --short` 确认只修改了预期文档文件。
- `git log -5 --pretty=format:%s` 查看最近提交标题风格。

如本地已有 Markdown linter，可对 `README.md`、`docs/architecture/` 下文档和 `AGENTS.md` 运行检查；不要仅为 lint 引入包管理器或新依赖。

## 编写风格与命名规范

所有回复和文档默认使用中文。Markdown 应使用清晰标题、紧凑表格和短说明。保留英文模块名与技术名词，例如 `domain_market`、`orderx`，项目名统一使用 **snake_case**（禁止 kebab-case）。域标签保持一致：基座、数据域、分析域、决策域、执行域、入口、横切。

## 专家沟通与真实性规则

> **权威来源：** [`docs/constitution/20-epistemic-standards.md`](docs/constitution/20-epistemic-standards.md)（宪法 §20）。
> 本节为摘要，与宪法冲突时以 §20 为准。

用于需要判断、审查、分析、争论或高准确性的答复。准确性优先于认可；先给最强反论证或关键异议，再给结论。没有新证据时，不因用户推回就让步。

- 每个事实性声明必须标注证据标签：`[KNOWN]` 训练事实；`[COMPUTED]` 由当前上下文、命令或计算得出；`[INFERRED]` 推断；`[COMMON]` 标准领域知识；`[FRAME]` 符号系统内部陈述，连贯不等于真实；`[GUESS]` 无依据猜测。标签作用于声明，不作用于疾病、法规、引用或命名实体本身。
- 置信度必须显式写出：`HIGH` ≥80%、`MED` 50-80%、`LOW` 20-50%、`VERY LOW` <20%、`UNKNOWN`。`[FRAME]` 的现实世界外推和 `[GUESS]` 的置信度上限为 `LOW`。
- 不知道时，第一行必须写：`我不知道。` 不得埋藏不确定性，不得编造。
- 禁止 `FRAME -> REALITY` 偷换：占星术、类型学等符号框架不得翻译成医学、法律、金融或其他现实世界声明；如必须翻译，必须显式标注这是翻译，结论保留在源框架内。
- 触发反奉承红旗时，删除不配权威的具体细节，改标 `[GUESS]`，或直接写 `我不知道。` 红旗包括：异常优雅、一种模式解释一切、被推回后无新证据就同意、用具体细节制造不该有的权威感。
- 事后分析必须问：这个框架在不知道结果前会预测这个吗？如果不会，标注 `[INFERRED, post-hoc]`；它只能适应结果，不能当作预测证据。
- 绝不编造引用。若为保持一致性而改变立场，必须公开说明修改了什么立场。
- 回复末尾必须附加 `[RULES I BROKE]：...`，说明违反了哪些规则、发生位置和原因；无违反时写 `无`。

**仓库命名强制规则**：所有 ZoneCNH 仓库使用 snake_case（下划线），禁止 kebab-case（连字符）、PascalCase、camelCase。例外：`x.go`、`binance.rs`。

**Go 编码规范**：所有 Go 模块代码须遵循 [`docs/standards/go-coding-standards.md`](docs/standards/go-coding-standards.md)，涵盖格式化、命名、错误处理、并发、接口设计、测试等 13 个维度。文档中"FoundationX 强制"条款来自 `CONSTITUTION.md`，优先级最高。

编辑表格时，除非能同时提升 `README.md` 和 `docs/architecture/` 文档的可读性，否则保持列顺序稳定。

## 测试规范

测试即文档校验。确认架构变更在两个根文档中保持一致，链接指向正确的 `https://github.com/ZoneCNH/...` 仓库，状态或版本更新不与依赖图冲突。

跨仓库、跨文档同步状态时，必须先区分“事实字段”和“投影字段”：release tag、CI run、覆盖率、发布日期等只能来自权威仓库或 GitHub Release；阶段投影、factory 版本、治理状态等不得因 release tag 变化而顺手改写。修改前后必须用 grep 或结构化检查确认旧事实无残留、新事实只出现在语义正确的位置；字段含义不确定时保守不改并在结果中说明。

大规模表格修改后，使用 `git diff -- README.md docs/architecture/` 对比前后内容。

## 提交与合并请求规范

近期提交使用简洁的约定式标题，尤其是 `docs: ...`。沿用该模式，例如 `docs: 更新宏观数据提供者状态`。每个提交只聚焦一个文档主题。

合并请求应说明架构或状态变化，列出受影响文件，并标注状态发生变化的关联模块仓库。仅当 GitHub 主页渲染布局变化时附截图。

## 安全与配置提示

不要提交凭证、交易所 API key、账户 ID、私有端点或实盘交易配置。本仓库只应包含公开架构说明和项目元数据。

## 分支纪律

> **SSOT**: `CONSTITUTION.md` §0（优先级最高）。详细操作步骤见 `docs/governance/DEVELOPMENT-WORKFLOW.md` §分支创建纪律。
>
> 核心规则：禁止 main 直接编辑 → 从 main HEAD 创建 worktree/branch → PR 合入 → 清理。

## Spec 开发管线

Spec 编写完成后，不是直接写代码，而是按管线推进：Spec → Review → Approve → Matrix → Tasks → Plan → Prompt → Code → 验收 → Ship。详见 `docs/governance/DEVELOPMENT-WORKFLOW.md`。

### Agents — Spec → Code 管线

本仓库配置了四源代理/评分体系（Claude Code + Codex + Copilot CLI + rules），功能角色相同，配置格式不同：

| 平台        | 配置目录           | 模型                       | 格式                 | Agent 数 |
| ----------- | ------------------ | -------------------------- | -------------------- | -------- |
| Claude Code | `.claude/agents/`  | Sonnet / Opus              | Markdown frontmatter | 27       |
| Codex       | `.codex/agents/`   | GPT-5.5 + reasoning effort | TOML                 | 27       |
| Copilot CLI | `.copilot/agents/` | Copilot/Claude 模型        | Markdown prompt      | 27       |

三平台 agent 镜像对齐，由 scripts/sync-agents.py 在 goal-workflow.sh preflight 阶段自动检测漂移。

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

管线的完整流程、门禁算法、失败路由、有界递归规则等详见 **`docs/governance/DEVELOPMENT-WORKFLOW.md`**（管线定义 SSOT）。评分方法论见 `docs/governance/STRUCTURAL-SCORING.md`，仲裁协议见 `docs/governance/scoring/ARBITER-PROTOCOL.md`。

### 快速通道（小型模块）

小型模块（单一接口 ≤3 方法、无运行时依赖、纯 library）可申请快速通道，详见 `docs/governance/DEVELOPMENT-WORKFLOW.md` §快速通道。

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

该入口与上述管线的门禁规则相同（详见 `docs/governance/DEVELOPMENT-WORKFLOW.md`）。

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
| `CONSTITUTION.md`                         | 最高治理权威（§0-§19，向后兼容存根；完整条款见 `docs/constitution/`） |
| `docs/constitution/`                      | 宪法章节视图（按条款拆分，含导航链接；[README](docs/constitution/README.md)） |
| `module/FOUNDATION-DEPS.yaml`             | Foundation 依赖矩阵（机器可读，规定允许/禁止的依赖边与特殊约束） |
| `module/registry.yaml`                   | 统一模块注册表（身份+治理状态 SSOT：lifecycle/owner/domain/arch_type） |
| `docs/governance/MODULE-GOVERNANCE.md`   | 模块治理总纲 — 八域总览、三 SSOT 边界、效力层级 |
| `docs/governance/module-governance/`     | 模块治理八专题（注册/生命周期/负责人/发布/健康度/准入/退役/业务域依赖）+ ADR 模板 |

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

#### Goal Agent 与 Governance Agent 路由规则

| 职能       | Goal agent（module/{m}/ 制品） | Governance agent（docs/ 制品）             | 路由规则                                                      |
| -------- | ----------------------------- | ------------------------------------------- | ------------------------------------------------------------- |
| Spec 编写 | goal-spec                     | spec, spec-author                           | 模块 spec 用 goal-spec；跨模块/工具级 spec 用 spec-author      |
| Spec 审查 | goal-reviewer                 | spec-review, spec-structural-score          | Goal Gate 审查用 goal-reviewer；四源评分用 *-structural-score |
| Design   | goal-architect                | —                                           | 统一用 goal-architect                                         |
| Plan/Tasks | goal-planner                | task-planner, task-split                    | 模块计划用 goal-planner；governance 管线用 task-planner       |
| Matrix   | goal-matrix                   | matrix, matrix-structural-score             | 模块追溯用 goal-matrix；评分用 matrix-structural-score       |
| Prompt   | goal-prompt-builder           | prompt-builder, prompt-structural-score     | 模块 prompt 用 goal-prompt-builder；评分用 prompt-structural-score |
| Code     | —                             | task-executor, code-structural-score        | 代码实现统一用 governance 的 task-executor                     |
| Evidence | goal-evidence                 | —                                           | 统一用 goal-evidence                                          |
| Governance | goal-governance             | pipeline-arbiter, meta-arbiter              | 一致性审计用 goal-governance；评分仲裁用 arbiter              |

路由规则说明：当 Goal 管线与 governance 管线同时适用时，Goal Gate 为权威裁决（见 `docs/goal/00-authority-map.md` §双管线优先级）。Goal agent 负责制品创建与 Gate 审查；governance agent 负责四源评分与仲裁。

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

### 模块目录结构规则

模块规格制品按 Goal 驱动交付体系的管线层级组织为目录化结构：

```text
module/{module}/
├── goal/goal.md        ← S1  Goal：目标定义
├── spec/               ← S2  Spec：需求规格（SPEC.md 等）
│   ├── client/         ←     子模块 spec
│   └── server/
├── design/             ← S3  Design：设计方案
├── plan/               ← S4  Plan：执行计划
├── tasks/              ← S5  Tasks：任务清单
├── prompt/             ← S6  Prompt：Context Package
├── evidence/           ← S8-S11 合层，按日期归档
│   └── YYYY-MM-DD/
│       ├── test/  review/  release/  retrospective/
├── matrix/             ← 模块追溯 SSOT
├── gate/               ← 模块门禁 SSOT
├── schema/             ← 模块 schema
├── README.md
├── CHANGELOG.md
└── ci-workflow.yaml
```

> 管线：goal → spec → design → plan → tasks → prompt → (Code: /home/{module}) → test → review → release → retrospective
> 目录表达**当前状态**。历史通过 `git log` / `git tag` 追溯。
> 版本号唯一源：`spec/SPEC.md` 的 `Spec-Version` 字段。
> `evidence/` 按日期归档——这是唯一需要时序累积的层。

- 模块级 Goal 文档位于 `module/{module}/goal/goal.md`。
- 各层可含子模块子目录（如 `client/`、`server/`），子模块复用相同目录结构。
- `.config/goal/` 仍为 Registry、Matrix canonical edge、Gate 状态、Evidence Bundle 和 Pipeline 状态的跨模块控制面 SSOT；模块级 `matrix/`、`evidence/`、`registry/` 为模块本地投影，不得与 `.config/goal/` 控制面冲突。

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

<!-- BEGIN BEADS CODEX SETUP: generated by bd setup codex -->
## Beads Issue Tracker

Use Beads (`bd`) for durable task tracking in repositories that include it. Use the `beads` skill at `.agents/skills/beads/SKILL.md` (project install) or `~/.agents/skills/beads/SKILL.md` (global install) for Beads workflow guidance, then use the `bd` CLI for issue operations.

### Quick Reference

```bash
bd ready                # Find available work
bd show <id>            # View issue details
bd update <id> --claim  # Claim work
bd close <id>           # Complete work
bd prime                # Refresh Beads context
```

### Rules

- Use `bd` for all task tracking; do not create markdown TODO lists.
- Run `bd prime` when Beads context is missing or stale. Codex 0.129.0+ can load Beads context automatically through native hooks; use `/hooks` to inspect or toggle them.
- Keep persistent project memory in Beads via `bd remember`; do not create ad hoc memory files.

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.
<!-- END BEADS CODEX SETUP -->

<!-- BEGIN BEADS REPO OVERRIDE — 本仓库覆盖声明（非 bd 生成，勿自动覆盖） -->
## Beads 与本仓库治理的优先级（覆盖 beads prime 注入）

`bd prime` / codex hook 注入的 beads 指令含通用规则，部分与本仓库定位冲突，以下条款**覆盖** beads 注入内容：

1. **本仓库是 Markdown 文档枢纽，非代码仓**。beads 的 "do not create markdown TODO lists" 不适用——本仓库的 `module/*/SPEC.md`、`TRACEABILITY.md`、`docs/goal/` 等 markdown 制品是核心交付物，继续按 `CONSTITUTION.md` 维护。
2. **OMC TaskCreate/TaskUpdate 仍可使用**。beads 的 "Prohibited: Do NOT use TodoWrite, TaskCreate" 仅指代 beads 自己的任务追踪场景；OMC 编排、Team 协调、进度跟踪继续用 Task 工具，二者不互斥。
3. **MEMORY.md / `.omc/` / notepad 体系保留**。beads 的 "do not create ad hoc memory files" 不适用——本仓库用 OMC notepad/project-memory/wiki 做跨会话记忆，beads 的 `bd remember` 是补充而非替代。
4. **stealth 模式**：beads 数据不进 git（`.beads/` 本地），不参与本仓库的 PR/commit 流程；issue 追踪是本地辅助，不影响 `CONSTITUTION.md` §0 分支纪律与数量验证门禁。
5. **冲突时优先级**：`CONSTITUTION.md` > 本仓库 `CLAUDE.md`/`AGENTS.md` 治理条款 > beads prime 注入。
<!-- END BEADS REPO OVERRIDE -->
