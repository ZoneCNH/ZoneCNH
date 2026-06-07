# 仓库指南

## 项目结构与模块组织

本仓库是 `ZoneCNH/ZoneCNH` 个人主页与架构索引，不是应用模块。根目录应保持精简，并以文档为主：

- `README.md` 展示公开简介、技术栈、分层架构摘要和核心项目链接。
- `ARCHITECTURE.md` 是架构图、依赖拓扑、模块状态表和建议实现顺序的权威文档。
- `kernel`、`market-data`、`factor-engine`、`x.go` 等模块位于独立 GitHub 仓库；不要把它们的源码树加入本仓库。

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

## Spec 开发管线

Spec 编写完成后，不是直接写代码，而是按管线推进：Spec → Review → Approve → Matrix → Tasks → Plan → Prompt → Code → 验收 → Ship。详见 `specs/DEVELOPMENT-WORKFLOW.md`。

### Agents — Spec → Code 管线

本仓库配置了双平台代理（Claude Code + Codex），功能角色相同，配置格式不同：

| 平台 | 配置目录 | 模型 | 格式 |
|------|----------|------|------|
| Claude Code | `.claude/agents/` | Sonnet / Opus | Markdown frontmatter |
| Codex | `.codex/agents/` | GPT-5.5 + reasoning effort | TOML |

| Agent | 步骤 | 用途 | 可改文件 | 可写代码 | Claude 模型 | Codex reasoning |
|-------|------|------|----------|----------|-------------|-----------------|
| `spec` | Spec | 编写或修订项目 spec，补齐 23 节结构与追溯链 | Spec 文档 | 否 | Opus | high |
| `spec-review` | Review | 对抗性审查 spec，给出 Go/No-Go 判断 | 无 | 否 | Opus | high |
| `matrix` | Matrix | 生成或校验需求追溯矩阵，闭合 FR/BR/AC/TC 链条 | Traceability 文档 | 否 | Sonnet | high |
| `task-split` | Tasks | 将 Approved Spec 和 Matrix 拆成可执行 Task Spec | Task / Matrix 文档 | 否 | Sonnet | high |
| `task-planner` | Plan | 生成实现顺序、依赖、验证命令和风险计划 | Plan 文档 | 否 | Opus | high |
| `prompt-builder` | Prompt | 为单个 Task 生成 Context Packet 与开发 Prompt | Prompt 文档 | 否 | Sonnet | medium |
| `task-executor` | Code | 按单个 Task 和 Prompt 编写代码与测试，验证后回填证据 | Task 指定源码/测试 | 是 | Sonnet | high |
| `code-reviewer` | Review | 代码审查 | 无 | 否 | — | — |
| `tdd-guide` | Test | 测试驱动开发 | 测试 / 必要实现 | 是 | — | — |

管线流程：

```text
spec → spec-review → matrix → task-split → task-planner → prompt-builder → task-executor
```

### OMC Pipeline Skill

已配置 OMC 技能 `<runtime>/skills/pipeline/SKILL.md`，支持一键触发完整管线：

| 触发方式 | 说明 |
|----------|------|
| `pipeline {module}` | 从头启动完整管线 |
| `pipeline {module} --from spec-review` | 从某个阶段恢复 |
| `pipeline {module} --stage matrix` | 只执行单个阶段 |
| `开发管线 {module}` | 中文触发 |

管线状态记录在 `<runtime>/state/pipeline/{module}.json`。

### 关键文档

| 文档 | 用途 |
|------|------|
| `specs/README.md` | 规格库索引 |
| `specs/DEVELOPMENT-WORKFLOW.md` | Spec → Ship 完整管线 |
| `specs/SPEC-TEMPLATE.md` | 23 节 spec 模板 |
| `specs/TASK-TEMPLATE.md` | Task spec 模板 |
| `specs/LIFECYCLE.md` | Spec 状态流转规则 |
| `specs/TRACEABILITY.md` | 需求追踪矩阵规范 |
| `specs/DEFINITION-OF-READY.md` | 进入开发的前置条件 |
| `specs/DEFINITION-OF-DONE.md` | 完成验收条件 |
| `CONSTITUTION.md` | 最高治理权威（13 条） |
