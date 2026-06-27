# ZoneCNH 工作流统一入口

> 最后更新：2026-06-27

---

## 快速导航

| 我要…… | 走这条管线 | 起点 |
|--------|-----------|------|
| 为新模块写需求规格 | **Spec→Code** | `module/{module}/spec/SPEC.md` |
| 把规格变成代码 | **Spec→Code** S6 | `module/{module}/tasks/` |
| 从业务目标出发建模块 | **Goal→Retro** | `module/{module}/goal/goal.md` |
| 检查当前模块在哪个阶段 | [阶段对应表](#三阶段对应表) | `.omc/state/pipeline/{module}/` |
| 了解评分和门禁规则 | [四源评分](#四四源评分) | `STRUCTURAL-SCORING.md` |
| 小型模块快速上手 | [快速通道](#五快速通道) | §快速通道 |
| 查看模块健康度 | [仪表盘](DASHBOARD.md) | `scripts/pipeline-dashboard.py` |

---

## 一、两条管线

ZoneCNH 有两条独立但互补的交付管线：

| | 管线 A：Spec→Code | 管线 B：Goal→Retro |
|---|---|---|
| **入口** | Spec 编写 | Goal 定义 |
| **阶段数** | 6（S1-S6） | 11（G0-G11） |
| **产物** | SPEC.md → Code | Goal → Spec → Design → … → Retro |
| **门禁** | 四源评分 ≥98 | G0-G11 Gate |
| **适用** | 模块已有明确需求 | 从零开始建模块 |
| **SSOT** | `DEVELOPMENT-WORKFLOW.md` | `docs/goal/03-pipeline.md` |

**关系**：管线 A 是管线 B 的子集。S1-S6 ≈ G2-G8。Matrix（追溯矩阵）是横切制品，贯穿两条管线。

---

## 二、何时用哪条

```
新模块？ ──是──→ 走管线 B（Goal→Retro）：先定义 Goal，再走 Spec→Code→Release
  │
  否
  │
已有 Spec？ ──是──→ 走管线 A（Spec→Code）：直接从 Spec 推进到 Code
  │
  否
  │
已有 Goal？ ──是──→ 走管线 B G2→：从 Spec 阶段继续
  │
  否
  │
小型模块？ ──是──→ 走快速通道（跳过 Design，单源评分，门禁 90）
```

---

## 三、阶段对应表

| 管线 B Gate | 管线 A 阶段 | 核心产物 | 执行 Agent | 评分 Rubric |
|------------|------------|---------|-----------|------------|
| G0 Context | — | 上下文恢复 | `goal-context-recovery` | — |
| G1 Goal | — | `goal/goal.md` | `goal-spec` | — |
| G2 Spec | **S1-Spec** | `spec/SPEC.md` | `spec` | `RUBRIC-spec.md` |
| G3 Design | — | `design/DESIGN.md` + ADR | `goal-architect` | `RUBRIC-design.md` |
| G4 Plan | **S4-Plan** | `plan/PLAN.md` | `task-planner` | `RUBRIC-plan.md` |
| G5 Task/Matrix | **S2-Matrix** + **S3-Tasks** | `TRACEABILITY.md` + `TASK-*.md` | `matrix` / `task-split` | `RUBRIC-matrix.md` / `RUBRIC-tasks.md` |
| G6 Implementation | **S6-Code** | 源码 + 测试 | `task-executor` | `RUBRIC-code.md` |
| G7 Test | — | 测试结果 | — | `RUBRIC-test.md` |
| G8 Evidence | — | Evidence Bundle | `goal-evidence` | — |
| G9 Review | — | Review 结论 | `goal-reviewer` | `RUBRIC-review.md` |
| G10 Release | — | Release Manifest | — | `RUBRIC-release.md` |
| G11 Retrospective | — | 复盘报告 | — | `RUBRIC-retrospective.md` |

> **S5-Prompt** 是管线 A 特有阶段（为 AI 编码生成 Context Packet），在管线 B 中作为 G6 Implementation 的前置准备，不独立对应 Gate。

---

## 四、四源评分

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
| Claude | `.claude/agents/` | Sonnet/Opus | 28 |
| Codex | `.codex/agents/` | GPT-5.5 | 20 |
| Copilot | `.copilot/agents/` | Copilot/Claude | 19 |
| Rules | `scripts/rule-scorer.py` | 纯 Python | 1（6 阶段） |

详见 `docs/governance/STRUCTURAL-SCORING.md` 和 `docs/governance/scoring/ARBITER-PROTOCOL.md`。

---

## 五、快速通道

小型模块（≤3 公开方法、无内部依赖、纯 library）可使用快速通道：

- **跳过**：Design 阶段（G3）
- **评分**：单源（rules only）
- **门禁**：≥90（正常 ≥98）
- **标记**：`SPEC.md` 元数据 `Fast-Track: true`

详见 `docs/governance/DEVELOPMENT-WORKFLOW.md` §快速通道。

---

## 六、文档索引

### 管线定义

| 文档 | 用途 |
|------|------|
| `docs/governance/DEVELOPMENT-WORKFLOW.md` | Spec→Code 管线 SSOT（含分支纪律、快速通道） |
| `docs/goal/03-pipeline.md` | Goal→Retro 管线 + 四轴状态模型 |
| `docs/goal/04-gates.md` | G0-G11 Gate 体系详解 |
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
