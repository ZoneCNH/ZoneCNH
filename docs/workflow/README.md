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

## 五、Sol/Luna 通用任务编排入口

[FRAME, HIGH] 这是位于 Spec→Code 之上的通用任务编排层：它只负责把可安全拆分的任务路由给 Luna、收集证据并处理失败升级，不替代 Spec→Code 的四源评分、`pipeline-arbiter` 或既有 Gate，也不改动 21=21=21 的 agent 镜像。

[FRAME, HIGH] 保护区外的硬入口是 `scripts/sol_luna_orchestrator.py`。入口在每次运行前 probe `gpt-5.6-sol`、`gpt-5.6-luna` 与 `xhigh`，并在每次模型调用中显式传参和记录日志；不得以 collaboration 子线程名称推断模型身份。

| 条件 | 路由 | 结果 |
|------|------|------|
| 少于 3 个互斥写范围，或存在并发安全风险 | Sol 直接处理 | 保留单一写者与普通验证 |
| 至少 3 个互斥写范围 | 外层编排器启动 3–5 个 Luna | 每个 Luna 只写自己的范围并返回证据 |
| cheap gate 通过 | 继续下一步 | 不回 Sol |
| 明确失败 | 先路由 Luna 修复 | 修复后重跑 gate |
| `evidence missing` / `evidence conflict` / `scope overlap` / `retry exhausted` | 回 Sol | Sol 决定补证据、消歧、重划范围或停止 |

[FRAME, HIGH] `run` 的调用契约是：必须提供 workspace 内真实的 `--spec-ref`、对应 canonical `--matrix-ref`、一个或多个确实存在于该 Matrix 的 `--matrix-edge`（例如 `M-001`、`M-003`）以及至少一个非空全局 `--check`。编排器把规范化后的引用写入 Sol plan、每个 Luna task/repair、integration repair 和 Sol escalation Prompt；任何缺失、空值、越界、Matrix 不匹配或 edge 不存在都 fail closed。

[FRAME, HIGH] scope 只能是明确的工作区相对路径。§14.1 完整保护集包括 `docs/governance/scoring/RUBRIC-*.md`、`docs/governance/STRUCTURAL-SCORING.md`、`docs/governance/scoring/ARBITER-PROTOCOL.md`、`.claude/agents/`、`.codex/agents/`、`.copilot/agents/`、`.claude/commands/spec-code-pipeline.md`、`.codex/skills/spec-code-pipeline/`、`.copilot/commands/spec-code-pipeline.md`、`.omc/state/outer-metrics/`、`.omx/state/outer-metrics/`、`.copilot/state/outer-metrics/` 和 `CONSTITUTION.md`；`.git` 及其子路径也不可声明。保护路径本身、`.`、其祖先目录、通配符/glob 或其他能够覆盖保护集的宽 scope 一律拒绝；`option=value` 中的绝对路径右值也按绝对路径拒绝。

[FRAME, HIGH] 全局 check 必须是允许的 argv；pytest 插件/override、Go exec/tool、Node loader/setup 等危险执行 flag 不得通过校验。所有 cheap checks 都在 `prlimit + bwrap` 无网络、clean-env、空根沙箱中执行：当前 worktree、`.git` 与 common-dir 均只读，只有有界 tmpfs 可写，宿主 home/其他 workspace/`/opt` secret/`/run` socket 不可见；沙箱或资源限制器不可用即 fail closed。模型调用前后检测新增 ignored 文件，仅豁免当前 run 自有证据目录；executor baseline ignored、其他 ignored 变化或检测异常均停止 gate。

[FRAME, HIGH] Luna 的 `changed_files` 声明必须和机械 diff 一致；冲突回 Sol。Sol 只接收失败/冲突摘要，通过任务仅传 ID、changed files 和 patch SHA-256 receipt；summary 汇总 Sol/Luna/总 token 与未知 token 调用。当前版本没有跨 run resume，上一 run 的通过 patch 不会自动复用。

最小探测命令：

```bash
codex --version
codex exec --help | rg -- '--model|reasoning|config'
python3 scripts/sol_luna_orchestrator.py --help
python3 scripts/sol_luna_orchestrator.py probe
```

[FRAME, HIGH] 入口不存在或模型 probe 失败时，只能报告“未证实 Luna”，不能声称已完成 Luna 编排。

[FRAME, HIGH] 自动执行示例：

```bash
python3 scripts/sol_luna_orchestrator.py run \
  --workspace "$PWD" \
  --workers 3 \
  --request-file /path/to/request.md \
  --spec-ref docs/governance/improvements/20260710-sol_luna_orchestration/SPEC.md \
  --matrix-ref docs/governance/improvements/20260710-sol_luna_orchestration/matrix/TRACEABILITY.md \
  --matrix-edge M-001 \
  --matrix-edge M-003 \
  --check '["python3", "-m", "pytest", "-q"]'
```

[FRAME, HIGH] 每个 task 先在独立 detached worktree 运行机械检查；全部 task patch 再进入独立 integration worktree。integration repair 每轮 checks 后重新读取 status、diff 与 scope，再决定是否捕获 combined patch。只有全局检查和重新抓取的 scope 都通过时，父 worktree 才一次性应用 combined patch；明确失败先由 Luna 重试，证据缺失、冲突、范围重叠或重试耗尽才升级 Sol。

---

## 六、文档索引

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
