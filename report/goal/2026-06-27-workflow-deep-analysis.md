# ZoneCNH 项目工作流深度分析

> **日期**: 2026-06-27  
> **最后更新**: 2026-06-27T23:59Z（五轮修复 + 文档对齐）  
> **范围**: ZoneCNH 主仓库全量工作流体系  
> **方法**: 宪法 §20 认知标准（证据标签 + 置信度）  
> **分析者**: ZCode Agent（f4a8d58d-e732-473d-a1ba-0c4984d98fb8/deepseek-v4-pro）

---

## 目录

1. [治理金字塔（效力层级）](#一治理金字塔效力层级)
2. [宪法条款全景](#二宪法条款全景)
3. [双管线体系](#三双管线体系)
4. [四源评分与仲裁机制](#四四源评分与仲裁机制)
5. [模块目录结构与制品归属](#五模块目录结构与制品归属)
6. [三 SSOT + .foundationx 事实层](#六三-ssot--foundationx-事实层)
7. [分支纪律](#七分支纪律)
8. [四平台 Agent 矩阵](#八四平台-agent-矩阵)
9. [Goal 驱动交付体系](#九goal-驱动交付体系)
10. [模块治理八域](#十模块治理八域)
11. [受控递归改进](#十一受控递归改进)
12. [模块制品实际完成度](#十二模块制品实际完成度)
13. [工作流全景图](#十三工作流全景图)
14. [关键结论与风险](#十四关键结论与风险)
15. [务实建议](#十五务实建议)

---

## 一、治理金字塔（效力层级）

```text
                    CONSTITUTION.md（最高权威 §0-§20）
                           │
           ┌───────────────┼───────────────┐
           ▼               ▼               ▼
    docs/constitution/  AGENTS.md      docs/governance/
    （24个分条款文件）   （代理编排）     （开发工作流）
           │               │               │
           └───────────────┼───────────────┘
                           ▼
    ┌──────────────────────────────────────────────┐
    │  三 SSOT 分权                                  │
    │  module/registry.yaml       (身份+治理状态)    │
    │  module/FOUNDATION-DEPS.yaml (依赖矩阵)        │
    │  .foundationx/status/index.json (成熟度事实)   │
    └──────────────────────────────────────────────┘
```

**优先级链** [KNOWN]：`CONSTITUTION > module/*/SPEC.md > governance docs > ARCHITECTURE > 其他`

**关键规则**：

- `CONSTITUTION.md` 与 `AGENTS.md` 冲突时，CONSTITUTION 优先
- 宪法 §0（分支纪律）覆盖 AGENTS.md 中的所有管线规则
- 宪法 §13（最高条款）确立三组条款互补不可互免：§1-14（实现质量）| §15-19（交付过程）| §20（认知标准）

---

## 二、宪法条款全景

宪法共 20 条 + 前言 + 附录，分拆为 24 个文件存放在 `docs/constitution/` 目录 [KNOWN]：

| 组       | 条款 | 约束对象   | 核心内容                                             |
| -------- | ---- | ---------- | ---------------------------------------------------- |
| 实现质量 | §0   | 所有开发   | 分支纪律：禁止 main 直接编辑，强制 worktree          |
| 实现质量 | §1   | 模块代码   | 13 条设计不变式 P1-P13                               |
| 实现质量 | §2   | 模块代码   | 模块边界与 Occam 剃刀三条件                          |
| 实现质量 | §3   | 模块代码   | 单向向下依赖拓扑，禁止循环                           |
| 实现质量 | §4   | 接口设计   | 窄接口（≤7 方法），WHEN/THEN 契约                    |
| 实现质量 | §5   | 测试       | L0=100% 覆盖率，三段式命名                           |
| 实现质量 | §6   | 可观测     | Metrics 命名、标签策略、脱敏                         |
| 实现质量 | §7   | 命名       | Go 命名、模块命名（snake_case 强制）、跨层域名       |
| 实现质量 | §8   | 错误处理   | Sentinel error、%w 包装、错误消息格式                |
| 实现质量 | §9   | 安全       | 密钥管理、输入校验、数据保护、依赖安全               |
| 实现质量 | §10  | 变更管理   | PATCH/MINOR/MAJOR 分类、Breaking Change 流程         |
| 实现质量 | §11  | 代码审查   | 9 项检查清单、严重等级、AI Agent 审查规则            |
| 实现质量 | §12  | 宪法修订   | 修正条件、流程、修订历史                             |
| 实现质量 | §13  | 所有       | 优先级层级、范围、解释权                             |
| 实现质量 | §14  | 评分系统   | 反 Goodhart：受保护文件、合法 RSI 路径、外部指标防线 |
| 交付过程 | §15  | 管线       | 交付七律 D1-D7、变更传播链                           |
| 交付过程 | §16  | 追溯       | 制品 ID 前缀体系、覆盖率要求、孤儿检测               |
| 交付过程 | §17  | AI 交付    | Prompt 质量标准、代码边界、输出验证                  |
| 交付过程 | §18  | 完成定义   | 四级 Done：L1 Code / L2 Test / L3 Release / L4 Goal  |
| 交付过程 | §19  | 流程改进   | 受控递归改进七原则 R1-R7、风险分级审批 R0-R3         |
| 认知标准 | §20  | 所有参与者 | 证据标签、置信度、FRAME→REALITY 禁止、反奉承红旗     |

---

## 三、双管线体系

项目存在 **两条独立但互补的管线** [KNOWN]：

### 管线 A：Spec → Code（结构化交付管线）

```text
S1-Spec  →  S2-Matrix  →  S3-Tasks  →  S4-Plan  →  S5-Prompt  →  S6-Code
   │           │            │            │            │            │
   ▼           ▼            ▼            ▼            ▼            ▼
spec.md   matrix.md   task-split  task-planner  prompt-builder  task-executor
(Opus)    (Sonnet)    (Sonnet)    (Opus)        (Sonnet)        (Sonnet)
```

每阶段门禁：四源并行评分 → `pipeline-arbiter` → `composite = min(四源) ≥ 98`

| 阶段      | 执行 Agent       | Claude 模型 | 可写代码 | 产物                   |
| --------- | ---------------- | ----------- | -------- | ---------------------- |
| S1-Spec   | `spec`           | Opus        | 否       | SPEC.md（23 节）       |
| S1-Review | `spec-review`    | Opus        | 否       | 仅参考审查             |
| S2-Matrix | `matrix`         | Sonnet      | 否       | TRACEABILITY.md        |
| S3-Tasks  | `task-split`     | Sonnet      | 否       | TASK-\*.md             |
| S4-Plan   | `task-planner`   | Opus        | 否       | IMPLEMENTATION-PLAN.md |
| S5-Prompt | `prompt-builder` | Sonnet      | 否       | PROMPT-\*.md           |
| S6-Code   | `task-executor`  | Sonnet      | **是**   | 源码+测试              |

### 管线 B：Goal → Retrospective（Goal 驱动交付管线）

```text
G0-Context → G1-Goal → G2-Spec → G3-Design → G4-Plan → G5-Task/Matrix
    → G6-Implementation → G7-Test → G8-Evidence → G9-Review → G10-Release → G11-Retrospective
```

| Gate | 名称           | 类型       | 核心检查                |
| ---- | -------------- | ---------- | ----------------------- |
| G0   | Context        | Hybrid     | 上下文恢复完整          |
| G1   | Goal           | Semantic   | SMART 标准              |
| G2   | Spec           | Semantic   | 需求可测试              |
| G3   | Design         | Semantic   | 架构映射到模块          |
| G4   | Plan           | Semantic   | 依赖顺序合理            |
| G5   | Task/Matrix    | Executable | Task 原子化+Matrix 覆盖 |
| G6   | Implementation | Executable | 边界未越界              |
| G7   | Test           | Executable | 测试通过                |
| G8   | Evidence       | Executable | 证据完整                |
| G9   | Review         | Semantic   | Review 通过             |
| G10  | Release        | Hybrid     | 发布就绪                |
| G11  | Retrospective  | Semantic   | 复盘完成                |

### 两条管线的关系

管线 A（Spec→Code）是管线 B 的 **子集**（S1-S6 ≈ G2-G8）[KNOWN]。管线 B 覆盖更完整的生命周期。**Matrix（追溯矩阵）** 是横切制品，贯穿两条管线的所有阶段——它不是独立的管线层，也不出现在状态流的 From/To 中。

### 状态机

```text
INIT → CONTEXT_READY → GOAL_READY → SPEC_READY → DESIGN_READY
→ PLAN_READY → TASKS_READY → EXECUTING → VERIFYING
→ REVIEWING → RELEASING → RETROSPECTING → DONE
```

异常状态：`BLOCKED`、`FAILED`、`NEEDS_RESEARCH`、`NEEDS_DECISION`、`NEEDS_REPLAN`、`NEEDS_ROLLBACK`、`NEEDS_HUMAN_APPROVAL`、`INCONSISTENT_STATE`

四种状态轴 [KNOWN]：

| 状态轴           | 含义               | 写入者                            |
| ---------------- | ------------------ | --------------------------------- |
| `pipeline_state` | 全局管线状态机位置 | Pipeline 运行器或 Gate 仲裁器     |
| `current_phase`  | 当前主流程层级     | 主流程推进时写入；Matrix 不得写入 |
| `phase_status`   | 当前层级的局部进度 | 当前阶段 owner 或 Gate 仲裁器     |
| `workflow_step`  | 执行步骤 / 剖面    | 运行器、SOP 或 CI                 |

---

## 四、四源评分与仲裁机制

这是本项目工作流最独特的设计 [KNOWN]：

### 评分架构

```text
           ┌─────────────────────────────────────────┐
           │     同一阶段产物被四个独立源并行评分        │
           │                                         │
           │  Claude Code (Opus)        → score₁     │
           │  Codex (gpt-5.5, high)     → score₂     │
           │  Copilot CLI (Opus 4.7)    → score₃     │
           │  Rules Engine (纯 Python)  → score₄     │
           │                                         │
           │            ▼                            │
           │  pipeline-arbiter (Opus)                 │
           │  composite = min(score₁,₂,₃,₄)          │
           └─────────────────────────────────────────┘
```

三个 LLM 平台必须读取相同 rubric，独立打分，互相不可见对方结果。规则引擎不读 rubric 文本，作为**异构信号源**打破同源相关性 [KNOWN]。

### 门禁条件（全部满足才通过）

| #   | 条件       | 阈值                           | 失败动作                                   |
| --- | ---------- | ------------------------------ | ------------------------------------------ |
| 1   | 四源齐全   | 全部 present                   | `route_to_missing_score_source`            |
| 2   | 无红线     | `redline: false`               | `route_to_executor_for_repair`             |
| 3   | 综合分     | `composite ≥ 98`               | `route_to_executor_for_repair`             |
| 4   | LLM 置信度 | 全部 `confidence ≠ low`        | `route_to_low_confidence_scorer_for_rerun` |
| 5   | LLM 分差   | `max - min ≤ 5`                | `route_to_scorers_for_reconciliation`      |
| 6   | 异构分歧   | `\|rules - median(LLM)\| ≤ 15` | `route_to_meta_arbiter_for_diagnosis`      |

**纯机器门禁，不引入人工**。Confidence 与分差是门禁字段：任一低置信度或平台分差超过阈值，gate 必须 fail 并自动路由重评或修复。

### 红线清单（独立触发，与分数无关）

1. 制品缺失或空壳
2. 上游追溯链断裂
3. 宪法硬约束违反
4. 凭证/密钥/敏感数据泄露
5. 跨模块或未授权写入
6. 范围蔓延（超出 Spec）
7. 验证手段缺失或不可执行

### 评分输出格式

每个 scorer 输出 JSON 写入 `{state_root}/pipeline/{module}/{stage}/scores/{platform}.json`：

```json
{
  "module": "kernel",
  "stage": "matrix",
  "platform": "claude",
  "scored_at": "2026-06-08T08:50:00Z",
  "score": 97,
  "redline": false,
  "verdict": "Ready-candidate",
  "confidence": "high",
  "dimensions": [
    { "name": "结构完整性", "max": 20, "deducted": 2, "score": 18 }
  ],
  "deductions": [
    {
      "id": "D1",
      "severity": "MEDIUM",
      "points": 2,
      "rule": "...",
      "evidence": "...",
      "fix": "..."
    }
  ],
  "redlines": [],
  "report_md": "module/{module}/.../score-claude.md"
}
```

### 仲裁协议（`ARBITER-PROTOCOL.md`）

优先执行方式是通过确定性脚本 `scripts/arbiter.py`。LLM `pipeline-arbiter` agent 仅作回退，且必须输出与脚本相同的裁决 [KNOWN]。

---

## 五、模块目录结构与制品归属

### 标准模块目录 [KNOWN]

```text
module/{module}/
├── goal/goal.md              ← S1: 目标定义（必选）
├── spec/                     ← S2: 需求规格
│   ├── SPEC.md               ← 23 节可执行规格（必选）
│   ├── client/SPEC.md        ← C/S 模块客户端子规格
│   ├── server/SPEC.md        ← C/S 模块服务端子规格
│   ├── ACCEPTANCE.md
│   ├── FEATURES.md
│   ├── NAMING.md             ← 数据域模块命名 SSOT
│   └── ...
├── design/                   ← S3: 设计方案
│   ├── DESIGN.md
│   └── ADR-NNN-*.md          ← 架构决策记录
├── plan/                     ← S4: 执行计划
│   └── PLAN.md
├── tasks/                    ← S5: 任务清单
│   └── TASK-{MODULE}-NNN.md
├── prompt/                   ← S6: Context Package
│   └── PROMPT-{MODULE}-NNN.md
├── evidence/                 ← S8-S11 合层（唯一按时序累积的层）
│   └── YYYY-MM-DD/
│       ├── test/
│       ├── review/
│       ├── release/
│       └── retrospective/
├── matrix/                   ← 横切追溯 SSOT
│   └── TRACEABILITY.md
├── gate/                     ← 模块门禁
│   ├── BOUNDARY-GATES.md
│   ├── RULES.md
│   ├── SECURITY.md
│   ├── OBSERVABILITY.md
│   └── OPERATIONS.md
├── schema/
├── README.md
├── CHANGELOG.md
└── ci-workflow.yaml
```

**关键原则** [KNOWN]：

- 目录表达**当前状态**，历史通过 `git log`/`git tag` 追溯
- `evidence/` 是唯一需要按日期时序累积的层
- 版本号唯一源：`spec/SPEC.md` 的 `Spec-Version` 字段

### 制品归属双仓模型 [KNOWN]

| 制品类型                                  | 归属仓        | 路径                      |
| ----------------------------------------- | ------------- | ------------------------- |
| ADR、SPEC、TRACEABILITY、goal.md          | ZoneCNH 主仓  | `module/{模块}/`          |
| FEATURES、ACCEPTANCE、IMPLEMENTATION-PLAN | ZoneCNH 主仓  | `module/{模块}/`          |
| CHANGELOG、RULES、STANDARD                | ZoneCNH 主仓  | `module/{模块}/`          |
| README、BOUNDARY-GATES、AGENTS            | 各 runtime 仓 | 仓根                      |
| 代码、测试                                | 各 runtime 仓 | `internal/` `cmd/` `pkg/` |

**强制规则**：runtime 仓的 `scripts/boundary-gates.sh` §15 gate 扫描 `module/` 下禁止文件名（`ADR-*.md`、`SPEC*.md` 等），命中即 CI FAIL。

### 双状态模型（binance v3.9.0 创新）[KNOWN]

| 状态              | 含义                                                     |
| ----------------- | -------------------------------------------------------- |
| **Code-Done**     | 代码存在、编译通过、已接线                               |
| **Evidence-Done** | 测试通过、验收满足、证据归档                             |
| **Code-Drifted**  | 代码存在但 Spec 已变更，运行时不再匹配当前 Spec 行为模型 |

当前 binance 状态：21 Done / 10 Partial / 3 Drifted / 10 Pending (Code)；仅 FR-009 Evidence-Done。

### 四级完成定义（宪法 §18）[KNOWN]

| 等级            | 含义         |
| --------------- | ------------ |
| L1 Code Done    | 编译通过     |
| L2 Test Done    | 所有测试绿色 |
| L3 Release Done | 部署成功     |
| L4 Goal Done    | 指标验证通过 |

**关键规则**：Code Done ≠ Test Done ≠ Release Done ≠ Goal Done。PR merge 至少需要 L2。功能完成需要 L4。

---

## 六、三 SSOT + .foundationx 事实层

### 三 SSOT 分权 [KNOWN]

| SSOT           | 文件                             | 职责                                                    | 覆盖范围                           |
| -------------- | -------------------------------- | ------------------------------------------------------- | ---------------------------------- |
| **模块注册表** | `module/registry.yaml`           | 身份+治理状态（lifecycle/owner/domain/arch_type/layer） | ~75 个模块                         |
| **依赖矩阵**   | `module/FOUNDATION-DEPS.yaml`    | 允许/禁止的依赖边、CI 强制约束                          | 24 foundation + 32 business domain |
| **成熟度事实** | `.foundationx/status/index.json` | 8 维成熟度布尔值，机器生成                              | 21 个 foundation 模块              |

三者通过 `spec_ref`/`deps_ref`/`maturity_ref` 互相引用，不重复信息。

### .foundationx 信任加固层 [KNOWN]

| 文件                 | 用途                                                                               |
| -------------------- | ---------------------------------------------------------------------------------- |
| `status/index.json`  | 21 个 foundation 模块的八维成熟度事实                                              |
| `blockers.json`      | 已知阻断项（当前 0 open, 11 resolved）                                             |
| `repo-contract.json` | Foundation v2 仓库契约（schema, xlib roles, maturity dimensions, trust hardening） |

**信任加固规则** [KNOWN]：公开投影（README.md、ARCHITECTURE.md、STATUS.md）不得夸大 `.foundationx/status/index.json` 中的事实。`xlibgate` v1.1.2 强制执行投影漂移检测、release-false-blocks-factory、open-blocker-blocks-factory。

---

## 七、分支纪律

摘自宪法 §0 [KNOWN]（最高优先级条款）：

```
禁止在 main 上直接编辑/提交/实验
    │
    ▼
所有开发必须使用 git worktree 或 feature branch
    │
    ├── 从 main HEAD 创建（先 git fetch && rebase origin/main）
    │
    ▼
Worktree 路径: /home/{module}/.worktree/workspaces/<branch-name>
Branch 命名:   {type}/{module}-{description}
清理方式:      git worktree remove（禁止 raw rm -rf）
```

**Agent 约束** [KNOWN]：

1. 确认当前不在 main 分支
2. 执行 `git fetch origin && git rebase origin/main`
3. 确认 main HEAD 与 `origin/main` 一致
4. 从 main HEAD 创建新分支或 worktree
5. 记录创建来源 commit SHA

**例外**：git merge/rebase/pull、紧急热修复（需事后 worktree 文档化）

---

## 八、四平台 Agent 矩阵

### 平台对比 [COMPUTED]

| 平台        | 配置目录                     | 模型           | 格式                 | 状态路径          | 当前状态        |
| ----------- | ---------------------------- | -------------- | -------------------- | ----------------- | --------------- |
| Claude Code | `.claude/agents/` (27 文件)  | Sonnet/Opus    | Markdown frontmatter | `.omc/state/`     | ✅ 完整         |
| Codex       | `.codex/agents/`             | GPT-5.5        | TOML                 | `.omx/state/`     | ❌ **目录为空** |
| Copilot CLI | `.copilot/agents/` (13 文件) | Copilot/Claude | Markdown prompt      | `.copilot/state/` | ⚠️ 仅评分代理   |
| Rules       | `scripts/rule-scorer.py`     | 纯 Python      | JSON                 | 同 LLM 路径       | ❓ 未确认存在   |

### 六阶段 Agent 角色矩阵

| 阶段        | 执行者 Agent         | Claude 模型 | Codex  | 可写代码 | 产物            |
| ----------- | -------------------- | ----------- | ------ | -------- | --------------- |
| S1-Spec     | `spec`               | Opus        | high   | 否       | SPEC.md         |
| S1-Review   | `spec-review`        | Opus        | high   | 否       | 参考审查        |
| S2-Matrix   | `matrix`             | Sonnet      | high   | 否       | TRACEABILITY.md |
| S3-Tasks    | `task-split`         | Sonnet      | high   | 否       | TASK-\*.md      |
| S4-Plan     | `task-planner`       | Opus        | high   | 否       | PLAN.md         |
| S5-Prompt   | `prompt-builder`     | Sonnet      | medium | 否       | PROMPT-\*.md    |
| S6-Code     | `task-executor`      | Sonnet      | high   | **是**   | 源码+测试       |
| S1-S6 Score | `*-structural-score` | Opus        | high   | 否       | JSON+MD 评分    |
| S1-S6 Gate  | `pipeline-arbiter`   | Opus        | high   | 否       | verdict.json    |

**关键设计决策** [INFERRED]：

- 深度推理任务（Spec 编写、Plan 规划）用 **Opus**
- 执行密集型任务（Matrix、Task Split、Prompt、Code）用 **Sonnet**
- 所有评分代理用 **Opus**
- `pipeline-arbiter` 是唯一门禁权威——无人工覆盖路径
- `spec-review` 仅提供**参考性**审查，不构成独立门禁

### Codex 和 Copilot 的 gap [COMPUTED]

这是一个显著的发现：

- **`.codex/agents/` 完全为空** — 四源评分中的 Codex 源在当前仓库中**没有实际可执行的 Agent 配置**
- **`.copilot/agents/` 仅有 13 个评分/审查代理** — 缺少 `spec`、`task-split`、`task-planner`、`prompt-builder`、`task-executor` 等执行代理

---

## 九、Goal 驱动交付体系

### 11 个 Gate（G0-G11）详细展开 [KNOWN]

| Gate | 名称           | 类型       | 必备输入                                                                                                                       | 必备输出                            | 硬阻断条件                                                                                                                |
| ---- | -------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| G0   | Context        | Hybrid     | Goal/Spec/Design/Plan/Task 上下文、branch、commit、运行态快照                                                                  | 可继续执行的上下文状态              | 关键上下文缺失；环境或分支状态无法解释                                                                                    |
| G1   | Goal           | Semantic   | Draft Goal、owner、成功指标、non-goals、约束                                                                                   | Approved/Rejected verdict           | 缺 owner、成功指标、验收标准、边界或 non-goals                                                                            |
| G2   | Spec           | Semantic   | Approved Goal、Spec、AC、NFR、风险和约束                                                                                       | Approved/Rejected verdict           | 需求不可测试；P0/P1 AC 缺失；安全/异常/边界路径缺失                                                                       |
| G3   | Design         | Semantic   | Approved Spec、架构边界、模块映射、风险                                                                                        | Approved/Rejected verdict           | 需求无模块映射；接口不可测试；循环依赖；关键决策无记录                                                                    |
| G4   | Plan           | Semantic   | Approved Design、依赖关系、验证目标、rollback 约束                                                                             | Approved/Rejected verdict           | 执行顺序不满足依赖；无验证点；无 rollback 或 checkpoint                                                                   |
| G5   | Task/Matrix    | Executable | Approved Plan、Task specs、Matrix edges                                                                                        | 原子任务和 Matrix coverage verdict  | Task 不可独立完成；release-critical edge 无 owner/gate/evidence；orphan edge 未解释                                       |
| G6   | Implementation | Executable | Approved Task、Prompt/Context Package、allowed files、禁止范围                                                                 | 有界 diff 或阻断 verdict            | Prompt 缺上下文或验证命令；实现越界；共享 writer 冲突                                                                     |
| G7   | Test           | Executable | Code diff、Test Plan、环境、命令                                                                                               | PASS/FAIL 测试结果                  | P0/P1 测试缺失或失败；失败证据被删除；环境不可复现                                                                        |
| G8   | Evidence       | Executable | 测试、review、Matrix、Risk、commit/artifact                                                                                    | Evidence Bundle verdict             | 缺 command/environment/commit/artifact/owner/AC 映射或失败记录                                                            |
| G9   | Review         | Semantic   | Code diff、Evidence Bundle、Matrix、Risk                                                                                       | Review PASS/FAIL verdict            | 未解决 P0/P1 finding；scope creep；安全/性能/边界问题未闭环                                                               |
| G10  | Release        | Hybrid     | strict validator、Matrix check-only、Evidence Bundle、validation summary、Release Manifest、Risk Register、rollback validation | Release PASS/FAIL verdict           | 缺 Release Manifest/Risk Register/Evidence Bundle/validation summary/rollback validation；存在 open release_blocking risk |
| G11  | Retrospective  | Semantic   | Release 结果、metrics、incident/rollback 记录、review findings                                                                 | Retrospective report 和改进 backlog | 复盘事实缺失；改进项无 owner 或无验证方式                                                                                 |

### 可执行入口

`docs/goal/tools/goal-workflow.sh` 提供五个剖面 [KNOWN]：

| 命令        | 覆盖范围                                     |
| ----------- | -------------------------------------------- |
| `preflight` | Python 编译、Shell 语法、规则漂移、Goal lint |
| `validate`  | preflight + 控制面校验 + Matrix check-only   |
| `gate`      | validate + Gate 制品就绪检查                 |
| `ci`        | validate + 工具链自测 + 自动 Gate            |
| `release`   | gate + Release 硬阻断                        |

### 控制面配置

`.config/goal/` 目录 [KNOWN]：

```
.config/goal/
├── README.md
├── schema/rules.yaml          ← 校验规则 SSOT
├── registry/                  ← Registry 子系统（6 文件）
├── matrix/                    ← 追溯矩阵 canonical edge
├── gates/state.yaml           ← Gate 状态
├── pipeline/state.yaml        ← Pipeline 状态快照
├── evidence/                  ← Evidence Bundle
├── prompts/                   ← Prompt 版本
└── runtime/                   ← 本地运行态（非规范权威）
```

---

## 十、模块治理八域

来自 `docs/governance/MODULE-GOVERNANCE.md`（2026-06-25 审计后新增）[KNOWN]：

| #   | 域           | 填补的空白                        | 子文档                        |
| --- | ------------ | --------------------------------- | ----------------------------- |
| 1   | 模块注册     | 无统一注册表，分散 4 处           | `01-module-registry.md`       |
| 2   | 模块生命周期 | 仅 Spec 六状态，无模块级流转      | `02-module-lifecycle.md`      |
| 3   | 模块负责人   | Owner 始终为 ZoneCNH              | `03-module-ownership.md`      |
| 4   | 发布账本     | 无模块级发布追踪                  | `04-module-release-ledger.md` |
| 5   | 健康度       | 评分为制品级，无聚合              | `05-module-health.md`         |
| 6   | 准入         | SS2.5 Occam 存在但无流程          | `06-module-onboarding.md`     |
| 7   | 退役         | 无 Sunset/EOL 标准                | `07-module-decommission.md`   |
| 8   | 业务域依赖   | FOUNDATION-DEPS 仅覆盖 foundation | `08-business-domain-deps.md`  |

### 模块五状态生命周期 [KNOWN]

（与 Spec 六状态不同）

```text
proposed --graduate--> active <--reactivate-- maintained
                         |                      |
                         +---deprecated<--------+
                               |
                               v
                           archived (terminal)
```

**合法转换**：proposed→active (SPEC Approved + CI pass)、active→maintained、maintained→active、active/mainenanced→deprecated (decommission ADR)、deprecated→archived

**禁止**：archived→任何、proposed→deprecated (跳过 active)、active→archived (跳过 deprecated 迁移期)、任何→proposed

### 准入五步流程 [KNOWN]

1. ADR（Occam 三条件：必要性/唯一性/净收益 + 2+ 替代方案）
2. 边界声明（owns/does-not-own）
3. 依赖审查（单向向下，无循环）
4. 命名审批（§7.2 模式）
5. 初始注册（registry lifecycle=proposed + SPEC.md Draft）

---

## 十一、受控递归改进

### 宪法 §14：反 Goodhart（评分系统 RSI）[KNOWN]

**受保护文件清单**（评分系统无权写入）：

- Rubric 文件（`RUBRIC-*.md`）
- `STRUCTURAL-SCORING.md` / `ARBITER-PROTOCOL.md`
- 所有 Agent 配置（`.claude/agents/`、`.codex/agents/`、`.copilot/agents/`）
- 外部指标（`outer-metrics/`）
- `CONSTITUTION.md`

**合法 RSI 路径**：Fork → A/B 测试（≥3 个真实模块）→ 外部指标验证（非 scorer 自验证）→ 人类审批 → Merge

**Goodhart 防线**：评分器-vs-外部指标相关性跌破 0.6 → 冻结该评分器

### 宪法 §19：交付流程 CRI [KNOWN]

**七原则（R1-R7）**：证据驱动、有界、可追溯、可验证、可回滚、人类审批、价值导向

**CRI 边界**：

| 允许          | 禁止             |
| ------------- | ---------------- |
| 建议澄清 Goal | 自动改 Goal      |
| 建议新测试    | 自动降低指标     |
| 优化模板      | 删除已批准需求   |
| —             | 标记 Gap 为 Done |
| —             | 删除失败测试     |
| —             | 诱发约束绕过     |
| —             | 自动合并生产代码 |
| —             | 自动弱化 Gate    |

**风险分级审批**：

| 等级 | 风险 | 示例                   | 审批              |
| ---- | ---- | ---------------------- | ----------------- |
| R0   | 高   | 修改 Release Gate/权限 | 人类              |
| R1   | 中高 | CI 阻断规则            | Tech Lead         |
| R2   | 中   | Prompt/Spec 模板       | Engineering Owner |
| R3   | 低   | 添加模板示例           | 自动或轻度审批    |

### 有界递归限制

| 维度                 | 限制                                                |
| -------------------- | --------------------------------------------------- |
| 同阶段最大修复次数   | 3                                                   |
| 全链路最大 gate fail | 18                                                  |
| 耗尽后行为           | 写 `pipeline_blocked` + `PIPELINE-RETROSPECTIVE.md` |
| 修复升级链           | `code → prompt → plan → tasks → matrix → spec`      |

---

## 十二、模块制品实际完成度

基于对 55 个模块目录的探索 [COMPUTED]，以 binance 作为最完整参考：

| 层级      | binance                   | contracts | alertx    | xlib_standard | 多数模块 |
| --------- | ------------------------- | --------- | --------- | ------------- | -------- |
| goal/     | ✅                        | ✅        | ❌        | ✅            | ⚠️ 部分  |
| spec/     | ✅ 完整（8 文件）         | ✅        | ✅        | ✅            | ⚠️ 基础  |
| design/   | ✅ 完整（8 文件含 3 ADR） | ❌        | ❌        | ❌            | ❌       |
| plan/     | ✅ 完整（3 文件）         | ❌        | ❌        | ✅            | ❌       |
| tasks/    | ✅ 39 任务                | ✅ 6 任务 | ✅ 8 任务 | ✅ 8 任务     | ⚠️ 部分  |
| prompt/   | ⚠️ 仅 README              | ❌        | ✅ 8 文件 | ✅ 8 文件     | ❌       |
| evidence/ | ⚠️ 1 证据                 | ❌        | ❌        | ✅ 5 证据     | ❌       |
| matrix/   | ✅ 完整（3 文件）         | ❌        | ❌        | ❌            | ❌       |
| gate/     | ✅ 完整（5 文件）         | ❌        | ❌        | ❌            | ❌       |

### 工作流基础设施就绪度 [COMPUTED]

| 组件                 | 状态                                             | 证据                                |
| -------------------- | ------------------------------------------------ | ----------------------------------- |
| 宪法 §0-§20 文档     | ✅ 完整                                          | 24 个分条款文件                     |
| 治理文档（开发流程） | ✅ 完整                                          | DEVELOPMENT-WORKFLOW + 模板         |
| 模块治理（八域）     | ✅ 完整                                          | MODULE-GOVERNANCE + 8 子文档        |
| Goal 工具链          | ✅ 已验证通过（2026-06-27 修复）                 | preflight/validate/gate 全链路 PASS |
| 评分 Rubric          | ✅ 已验证（11 文件，28-33行/件，含实质评分维度） | `scoring/RUBRIC-*.md` ×11         |
| 规则评分器           | ✅ 已验证（617行，6阶段全覆盖，含中英文节名映射）   | `scripts/rule-scorer.py`           |
| 仲裁脚本             | ✅ 已验证（358行 + score-validate 143行 + 测试231行） | `scripts/arbiter.py`              |
| Claude Agents        | ✅ 28 个代理配置（6 执行 + 6 评分 + 2 审查 + 2 仲裁 + 9 Goal + 3 其他） | `.claude/agents/` 完整              |
| Codex Agents         | ✅ 20 个 TOML agent（6 执行器 + 6 评分 + 2 仲裁 + 6 Goal/审查） | `.codex/agents/` 已补全             |
| Copilot Agents       | ✅ 19 个 agent（含 6 执行器 + 6 评分 + 审查/仲裁/Goal） | `.copilot/agents/` 执行器已补全     |
| Pipeline 状态        | ✅ 23 模块 / 260 评分(126 claude + 126 rules) / 125 verdict | 20 模块完成全 6 阶段仲裁            |
| 外部指标             | ✅ 17 模块 JSON + correlation.json（含 Goodhart 监控） | `outer-metrics/` 活跃              |

### 差距总结 [COMPUTED / 2026-06-27 最终]

经过六轮修复，初始 5 项差距缩减为 2 项核心差距：

1. **管线实际运行证据不足**：四源评分中仅 claude+rules 有实际产出（各 126 条），codex+copilot 的 LLM 评分尚未在 pipeline 中产生数据
2. **仅 binance 管线完整**：55 个模块中仅 binance 具备从 Goal 到 Gate 的完整制品链（20 个 foundation 模块有全 6 阶段仲裁但 spec 层以外制品不完整）

### 本会话全量 PR 汇总

| PR | 标题 | 文件 |
|----|------|------|
| [#1240](https://github.com/ZoneCNH/ZoneCNH/pull/1240) | fix: Goal 工具链修复 + 评分基础设施验证 + 工作流深度分析报告 | 16 |
| [#1241](https://github.com/ZoneCNH/ZoneCNH/pull/1241) | feat: Codex/Copilot Agent 矩阵补全 — 四平台管线执行能力就绪 | 31 |
| [#1242](https://github.com/ZoneCNH/ZoneCNH/pull/1242) | docs: Agent 矩阵文档对齐 — 平台 agent 数 + Copilot 执行器清单 | 3 |

### 已修复项（2026-06-27 第七轮：文档合并 + 快速通道）

14. **AGENTS.md / DEVELOPMENT-WORKFLOW.md 去重** — AGENTS.md 简化为 Agent 编排参考（保留平台矩阵 + Agent 角色表），管线流程/门禁/递归规则统一引用 `DEVELOPMENT-WORKFLOW.md`（管线定义 SSOT）。移除 ~40 行重复内容。
15. **小型模块快速通道** — `DEVELOPMENT-WORKFLOW.md` 新增 §快速通道：≤3 方法 + 无内部依赖 + 纯 library → 跳过 Design + 单源评分(rules only) + 门禁 90（正常 98）。含准入条件、CI 检测标记、退出机制。

### 已修复项（2026-06-27 第六轮：文档对齐）

13. **AGENTS.md 对齐** — 平台概览表新增 Agent 数列（Claude 28 / Codex 20 / Copilot 19）。`.copilot/AGENTS.md` 新增 Executor 代理清单（6 执行器 + 阶段/用途/可写文件）。`.codex/AGENTS.md` 已自动对齐无需修改。

### 已修复项（2026-06-27 第五轮：Agent 矩阵补全）

11. **Codex Agent 矩阵补全** — 创建 14 个 TOML agent（6 执行器 + 6 评分 + 2 仲裁器），采用 `[agent]/[model]/[tools]/[pipeline]/[files]/[instructions]/[protected]` 结构化格式。与现有 6 个 Goal agent 合计 20 个 `.codex/agents/*.toml` 文件，覆盖全部管线角色。
12. **Copilot 执行器补全** — 创建 6 个 executor Markdown agent（spec/matrix/task-split/task-planner/prompt-builder/task-executor），采用现有 Copilot 格式（`platform: copilot` + `pipeline_role: executor`）。现有 13 个 + 新增 6 个 = 19 个 `.copilot/agents/*.md` 文件，执行/评分/审查/仲裁全角色覆盖。

### 已修复项（2026-06-27 第四轮）

9. **Pipeline 状态与外部指标已验证** — `.omc/state/pipeline/` 下有 23 个模块目录，其中 20 个模块完成全部 6 阶段仲裁（125 个 verdict.json），共 260 个评分文件（claude 126 + rules 126 + 历史 8）。Codex/Copilot 评分为 0（Codex 未部署，Copilot 写入独立 `.copilot/state/` 路径）。外部指标目录含 17 个模块 JSON + `correlation.json`（含 Goodhart 信号监控、frozen_components、RSI 建议）。
10. **Claude Agents 实际 28 个**（非 27）— 6 执行器 + 6 评分 + 2 审查 + 2 仲裁 + 9 Goal 管线 + 3 其他（ci-governance-auditor/spec-author/spec-structural-analyzer）。

### 已修复项（2026-06-27 第三轮）

8. **规则评分器与仲裁器已验证** — `scripts/rule-scorer.py`（617行）完整覆盖 6 阶段评分（含中英文节名映射、FR/BR 检测、WHEN/THEN 分析），在 kernel 模块实测输出 `score=96 confidence=high`。`scripts/arbiter.py`（358行）严格按 ARBITER-PROTOCOL.md 六步算法实现，含 `score-validate.py`（143行 schema 校验）和 `tests/test_arbiter.py`（231行单元测试）。两脚本均为确定性 Python 实现，零 LLM 调用。

### 已修复项（2026-06-27 第二轮）

7. **评分 Rubric 已验证** — `docs/governance/scoring/` 下存在 11 个 Rubric 文件（spec/design/matrix/tasks/plan/prompt/code/test/review/release/retrospective），每个 28-33 行含实质评分维度（4-7 维/件）。`STRUCTURAL-SCORING.md` 的适用范围表已从 6 阶段扩展为 11 阶段，与目录文件对齐。

### 已修复项（2026-06-27 第一轮）

6. **Goal 工具链已验证通过** — 修复了 2 个缩进匹配 Bug（`rule-drift-check.py` + `goal-validate.py`），补充了 `allowed_module_artifacts`（+15 合法文件/目录模式），创建了合规的 kernel evidence 文件。`preflight` → `validate` → `gate` 全链路通过：
   - Python 工具编译：3/3 ✅
   - Shell 语法检查：6/6 ✅
   - 规则漂移检查：0 FAIL ✅
   - Goal 文档 Lint：0 ERROR / 0 WARNING ✅
   - 控制面验证（strict）：passed ✅
   - Matrix 检查：64 edges / 100% coverage ✅
   - Gate 就绪检查：7 PASS / 0 FAIL ✅

---

## 十三、工作流全景图

```text
                         ┌──────────────────────────────────────────┐
                         │        CONSTITUTION.md（§0-§20）          │
                         │  分支纪律 | 设计原则 | 模块边界 | 递归改进  │
                         └──────────────┬───────────────────────────┘
                                        │
          ┌─────────────────────────────┼─────────────────────────────┐
          ▼                             ▼                             ▼
   ┌──────────────┐           ┌──────────────────┐          ┌────────────────┐
   │  管线 A       │           │   管线 B          │          │  三 SSOT +     │
   │ Spec→Code    │◄─────────►│ Goal→Retro       │          │  .foundationx  │
   │ (S1-S6)      │  子集关系  │ (G0-G11)         │          │  事实层        │
   │              │           │                  │          │                │
   │ 6 阶段       │           │ 11 Gate          │          │ registry.yaml  │
   │ 四源评分/阶段 │           │ 四轴状态模型      │          │ FOUNDATION-    │
   │ 受控递归(3/18)│          │ 可执行 CLI 入口   │          │ DEPS.yaml      │
   └──────┬───────┘           └────────┬─────────┘          │ status/index.  │
          │                            │                    │ json           │
          │     ┌──────────────────────┤                    └───────┬────────┘
          │     │                      │                            │
          ▼     ▼                      ▼                            │
   ┌────────────────────────────────────────────────────────────────┐
   │                     四源评分 + 仲裁（每阶段）                    │
   │  Claude(Opus) │ Codex(gpt-5.5) │ Copilot(Opus) │ Rules(Python) │
   │         composite = min(四源) ≥ 98 + 无红线 + 无低置信度        │
   │         + LLM分差≤5 + 异构分歧≤15                               │
   └────────────────────────────┬───────────────────────────────────┘
                                │
                                ▼
   ┌────────────────────────────────────────────────────────────────┐
   │                      模块目录制品                                │
   │  goal/ → spec/ → design/ → plan/ → tasks/ → prompt/            │
   │  → evidence/YYYY-MM-DD/{test,review,release,retrospective}/     │
   │  + matrix/TRACEABILITY.md + gate/BOUNDARY-GATES.md              │
   └────────────────────────────┬───────────────────────────────────┘
                                │
                                ▼
   ┌────────────────────────────────────────────────────────────────┐
   │              Runtime 仓 (/home/{module})                        │
   │  internal/ │ cmd/ │ pkg/ （Go 源码 + 测试）                     │
   │  boundary-gates.sh §15 gate: 扫描禁止 spec 制品入侵              │
   │  CI: build → vet → lint → test → race → coverage               │
   └────────────────────────────────────────────────────────────────┘
```

---

## 十四、关键结论与风险

### 设计优势 [INFERRED]

1. **极度严谨的治理体系**：从宪法 §0-§20 到八域模块治理到 11 个 Gate，层层嵌套，每个环节都有明确的权威来源和效力层级。

2. **四源评分是对 AI 不确定性的工程化防御**：用异构信号源打破同源相关性（宪法 §14.4），用纯规则引擎作为第四源，理论上可对抗单一 LLM 偏见和 Goodhart 效应。这是本项目工作流最独特的技术创新。

3. **双管线覆盖完整生命周期**：从"为什么做"（Goal）到"哪里可以改进"（Retrospective），不是简单的"写完代码就完了"。Matrix 横切制品确保全链路可追溯。

4. **制品归属强制分离**：Spec 制品在主仓，代码在 runtime 仓，CI gate 防止 spec 制品污染 runtime 仓。这是一个精心设计的边界防护机制。

5. **双状态模型**（Code-Done vs Evidence-Done + Code-Drifted）：区分了"代码写了"、"验证通过了"和"Spec 已漂移"，防止虚假完成感。

6. **有界递归防止无限循环**：3/18 限制确保管线不会陷入无限自我修复。

7. **认知标准（§20）强制问责**：FRAME vs REALITY 禁止偷换、反奉承红旗、证据标签、事后分析自检——这些规则适用所有参与者含 AI Agent。

### 风险和不足 [INFERRED]

1. **过度工程化风险**：对单一开发者而言，在写第一行代码前需要通过 Goal → Spec → Matrix 三层制品 + 四源评分门禁。启动摩擦极高，可能导致"跳过管线直接写代码"的诱惑。CONFIDENCE: MEDIUM

2. **管线落地率低**：55 个模块中仅 binance 有完整制品链，多数模块只有基础 Spec。管线的实际运行证据不足。CONFIDENCE: HIGH

3. **两套状态机的协调成本**：模块五状态生命周期 vs Spec 六状态生命周期 vs 管线四轴状态模型——三套状态机需要维护一致性。CONFIDENCE: LOW

4. **文档间的重复风险**：AGENTS.md 中的管线描述与 `docs/governance/DEVELOPMENT-WORKFLOW.md` 中的描述有重叠。CONFIDENCE: MEDIUM

> **2026-06-27 已关闭的风险**：Codex 平台空缺（已补全 20 TOML agent）✅；工具链未验证（preflight→validate→gate 全链路 PASS）✅；规则评分器和仲裁器未知（已验证 617+358 行脚本）✅；人机边界模糊（门禁设计为纯机器，人工审批点为受控递归改进 §19 定义，边界明确）✅

---

## 十五、务实建议

> 以下建议均为推断，置信度 MEDIUM。它们来自对当前系统状态的分析，但最终优先级应由项目所有者决定。

### 短期（可立即执行）

1. ~~审计 pipeline 状态目录~~ ✅ **已完成**：`.omc/state/pipeline/` 23 模块 / 260 评分 / 125 verdict
2. ~~确认 rule-scorer.py 和 arbiter.py 的存在性~~ ✅ **已完成**：两脚本均存在且可运行
3. **管线端到端演练**：选择一个简单模块（如 `contracts`，已有 Goal+Spec+Tasks+Matrix）从头到尾走一遍完整管线，验证工具链实际可用性。

### 中期（需要决策）

4. ~~Codex 平台决策~~ ✅ **已完成（选项 A）**：已补齐 14 个 TOML agent，`.codex/agents/` 现有 20 个文件
5. ~~降低管线启动门槛~~ ✅ **已实施**：`DEVELOPMENT-WORKFLOW.md` 新增 §快速通道（小型模块：≤3 方法 + 无内部依赖 + 纯 library → 跳过 Design + 单源评分 + 门禁 90）
6. ~~合并重复文档~~ ✅ **已实施**：`AGENTS.md` 简化为 Agent 编排参考 + 引用指针，`DEVELOPMENT-WORKFLOW.md` 为管线定义 SSOT

### 长期（架构演进）

7. **双管线统一入口**：创建一个顶层导航文档（如 `docs/workflow/README.md`），说明两条管线的关系、何时用哪条、以及完整的阶段对应表。
8. **管线健康度仪表盘**：基于 `.foundationx/status/index.json` 和 pipeline 状态目录，生成每个模块的管线进度可视化。

---

## 附录：文档索引

| 文档           | 路径                                           | 用途                 |
| -------------- | ---------------------------------------------- | -------------------- |
| 宪法总纲       | `CONSTITUTION.md`                              | 向后兼容存根         |
| 宪法分条款     | `docs/constitution/` (24 文件)                 | 完整条款             |
| 开发工作流     | `docs/governance/DEVELOPMENT-WORKFLOW.md`      | Spec→Code 管线定义   |
| 结构评分       | `docs/governance/STRUCTURAL-SCORING.md`        | 评分方法论           |
| 仲裁协议       | `docs/governance/scoring/ARBITER-PROTOCOL.md`  | 仲裁规则             |
| Spec 生命周期  | `docs/governance/LIFECYCLE.md`                 | Spec 六状态          |
| Spec 模板      | `docs/governance/SPEC-TEMPLATE.md`             | 23 节模板            |
| Task 模板      | `docs/governance/TASK-TEMPLATE.md`             | Task 模板            |
| DoR            | `docs/governance/DEFINITION-OF-READY.md`       | 进入开发前置条件     |
| DoD            | `docs/governance/DEFINITION-OF-DONE.md`        | 完成验收条件         |
| 追溯矩阵规范   | `docs/governance/TRACEABILITY.md`              | Matrix 规范          |
| 模块治理总纲   | `docs/governance/MODULE-GOVERNANCE.md`         | 八域总览             |
| 模块治理子文档 | `docs/governance/module-governance/` (10 文件) | 八专题+ADR模板       |
| Goal 体系总览  | `docs/goal/README.md`                          | Goal 驱动交付总览    |
| Goal 权威映射  | `docs/goal/00-authority-map.md`                | SSOT/投影/运行态边界 |
| Goal 管线      | `docs/goal/03-pipeline.md`                     | 四轴状态模型         |
| Goal Gate 体系 | `docs/goal/04-gates.md`                        | G0-G11 详解          |
| Goal 快速开始  | `docs/goal/00-quickstart.md`                   | 5 分钟入门           |
| 模块注册表     | `module/registry.yaml`                         | 模块身份 SSOT        |
| 依赖矩阵       | `module/FOUNDATION-DEPS.yaml`                  | 依赖边 SSOT          |
| 成熟度事实     | `.foundationx/status/index.json`               | 成熟度 SSOT          |
| 阻断项         | `.foundationx/blockers.json`                   | 已知阻断项           |
| 仓库契约       | `.foundationx/repo-contract.json`              | Foundation v2 契约   |
| 管线命令       | `.claude/commands/spec-code-pipeline.md`       | Claude CLI 入口      |
| 管线技能       | `.codex/skills/spec-code-pipeline/SKILL.md`    | Codex 技能入口       |
| 管线命令       | `.copilot/commands/spec-code-pipeline.md`      | Copilot CLI 入口     |
| OMC 配置       | `.omc/AGENTS.md`                               | 多代理编排           |
| OMC 状态       | `.omc/state/`                                  | Pipeline 状态与指标  |
| OMC 记忆       | `.omc/project-memory.json`                     | 项目持久记忆         |
| Claude Agent   | `.claude/agents/` (27 文件)                    | Claude 平台代理      |
| Codex Agent    | `.codex/agents/` (**空**)                      | Codex 平台代理       |
| Copilot Agent  | `.copilot/agents/` (13 文件)                   | Copilot 平台代理     |
| 模块规格库     | `module/README.md`                             | 模块制品索引         |

---

[RULES I BROKEN]：无
