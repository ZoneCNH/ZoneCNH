# ZoneCNH 工作流统一入口

> 最后更新：2026-07-03（P2.1 双管线收敛为单管线）

---

## 快速导航

| 我要…… | 走这条路径 | 起点 |
|--------|-----------|------|
| 为新模块写需求规格 | Goal→Retro 全流程 | `module/{module}/goal/goal.md` |
| 把规格变成代码 | Goal→Retro G2→G6 | `module/{module}/spec/SPEC.md` |
| 检查当前模块在哪个阶段 | [阶段总览](#二阶段总览) | `.omc/state/pipeline/{module}/` |
| 了解评分和门禁规则 | [四源评分](#三四源评分) | `STRUCTURAL-SCORING.md` |
| 小型模块快速上手 | [快速通道](#四快速通道) | §快速通道 |
| 查看模块健康度 | [仪表盘](DASHBOARD.md) | `scripts/pipeline-dashboard.py` |

---

## 一、统一管线

ZoneCNH 使用 **Goal→Retro** 作为唯一交付管线（G0-G11）。Spec→Code（S1-S6）是 G2-G6 的快速通道子集，适用于已有明确需求的模块。

```
G0 Context → G1 Goal → G2 Spec → G3 Design → G4 Plan → G5 Task/Matrix
    → G6 Implementation → G7 Test → G8 Evidence → G9 Review
    → G10 Release → G11 Retrospective
```

**快速通道（Spec→Code）**：当模块已有明确需求时，可从 G2 Spec 直接进入，跳过 G0-G1。S1-S6 映射到 G2-G6，门禁降为 ≥90（单源评分）。

| 属性 | 全流程（G0-G11） | 快速通道（S1-S6 ≈ G2-G6） |
|-----|-----------------|--------------------------|
| **入口** | G0 Context | G2 Spec |
| **阶段数** | 11 | 6 |
| **产物** | Goal → Spec → Design → … → Retro | SPEC.md → Code |
| **门禁** | G0-G11 Gate | 四源评分 ≥90（单源） |
| **适用** | 从零开始建模块 | 模块已有明确需求 |
| **SSOT** | `docs/goal/03-pipeline.md` | `docs/governance/DEVELOPMENT-WORKFLOW.md` §快速通道 |

---

## 二、阶段总览

| Gate | 阶段名 | 核心产物 | 执行 Agent | 评分 Rubric |
|------|--------|---------|-----------|------------|
| G0 | Context | 上下文恢复 | `goal-context-recovery` | — |
| G1 | Goal | `goal/goal.md` | `goal-spec` | — |
| G2 | Spec | `spec/SPEC.md` | `goal-spec` | `RUBRIC-spec.md` |
| G3 | Design | `design/DESIGN.md` + ADR | `goal-architect` | `RUBRIC-design.md` |
| G4 | Plan | `plan/PLAN.md` | `goal-planner` | `RUBRIC-plan.md` |
| G5 | Task/Matrix | `TRACEABILITY.md` + `TASK-*.md` | `goal-planner` / `goal-matrix` | `RUBRIC-matrix.md` / `RUBRIC-tasks.md` |
| G6 | Implementation | 源码 + 测试 | `task-executor` | `RUBRIC-code.md` |
| G7 | Test | 测试结果 | — | `RUBRIC-test.md` |
| G8 | Evidence | Evidence Bundle | `goal-evidence` | — |
| G9 | Review | Review 结论 | `goal-reviewer` | `RUBRIC-review.md` |
| G10 | Release | Release Manifest | — | `RUBRIC-release.md` |
| G11 | Retrospective | 复盘报告 | — | `RUBRIC-retrospective.md` |

> **S5-Prompt**（Context Packet 生成）是 G6 的前置准备，不独立对应 Gate。
> Matrix（追溯矩阵）是横切制品，贯穿所有阶段。

---

## 三、四源评分

每个阶段必须通过四源并行评分门禁：

```text
executor → [Claude scorer | Codex scorer | Copilot scorer | Rules scorer]
        → pipeline-arbiter
        → composite_score = min(四源分数) ≥ 98
        → pass → 下一阶段
        → fail → 自动修复（同阶段≤3次，全链路≤18次）
```

| 源 | 平台 | 模型 | Agent 数 |
|---|------|------|---------|
| Claude | `.claude/agents/` | Sonnet/Opus | 21 |
| Codex | `.codex/agents/` | GPT-5.5 | 21 |
| Copilot | `.copilot/agents/` | Copilot/Claude | 21 |
| Rules | `scripts/rule-scorer.py` | 纯 Python | 1（6 阶段） |

> 三平台 agent 镜像对齐（21=21=21，零漂移），由 `scripts/sync-agents.py` 检测。

详见 `docs/governance/STRUCTURAL-SCORING.md` 和 `docs/governance/scoring/ARBITER-PROTOCOL.md`。

---

## 四、快速通道

小型模块（≤3 公开方法、无内部依赖、纯 library）可使用快速通道：

- **跳过**：G0-G1（Context/Goal）+ G3（Design）
- **评分**：单源（rules only）
- **门禁**：≥90（正常 ≥98）
- **标记**：`SPEC.md` 元数据 `Fast-Track: true`

详见 `docs/governance/DEVELOPMENT-WORKFLOW.md` §快速通道。

---

## 五、文档索引

### 管线定义

| 文档 | 用途 |
|------|------|
| `docs/goal/03-pipeline.md` | Goal→Retro 管线 SSOT（G0-G11 全流程） |
| `docs/goal/04-gates.md` | G0-G11 Gate 体系详解 |
| `docs/governance/DEVELOPMENT-WORKFLOW.md` | 快速通道（Spec→Code）操作手册 |
| `docs/governance/STRUCTURAL-SCORING.md` | 四源评分方法论 |
| `docs/governance/scoring/ARBITER-PROTOCOL.md` | 仲裁算法与门禁规则 |

### Agent 配置

| 文档 | 用途 |
|------|------|
| `AGENTS.md` | Agent 矩阵总表 + 平台概览 |
| `.claude/AGENTS.md` | —（参见 `AGENTS.md`） |
| `.codex/AGENTS.md` | Codex Agent 清单（执行/评分/仲裁） |
| `.copilot/AGENTS.md` | Copilot Agent 清单（执行/评分/Goal） |

### 模块制品

| 文档 | 用途 |
|------|------|
| `module/README.md` | 模块规格库索引 |
| `module/{module}/spec/SPEC.md` | 模块可执行规格（23 节） |
| `module/{module}/matrix/TRACEABILITY.md` | 需求追溯矩阵 |

### 治理权威

| 文档 | 用途 |
|------|------|
| `CONSTITUTION.md` | 最高治理权威（§0-§20） |
| `docs/governance/MODULE-GOVERNANCE.md` | 模块治理八域总纲 |
| `report/goal/2026-06-27-workflow-deep-analysis.md` | 工作流深度分析报告（全量） |
