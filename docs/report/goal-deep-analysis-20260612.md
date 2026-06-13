# docs/goal/ 深度分析报告

> 生成日期：2026-06-12
> 分析范围：`docs/goal/` 全目录（34 个文档 + 4 个 YAML Schema + 11 个可执行工具脚本）
> 分析方法：只读审查，未修改任何制品

---

## 一、整体架构概览

`docs/goal/` 是一套 **Goal 驱动交付体系（Goal Delivery OS）** 的完整方法论规范，共 34 个文件（30 个 .md + 4 个 YAML Schema），配有 11 个可执行工具脚本。

### 核心公式

```
Goal = 目标动作 + 结果对象 + 衡量指标 + 目标值 + 截止时间
```

满足 SMART 原则：Specific、Measurable、Achievable、Relevant、Time-bound。

### 文件组织结构

```text
docs/goal/
├── 00-02  入口与基础    (quickstart, authority-map, methodology, goal-standard)
├── 03-05  管线与标准    (pipeline, gates, layer-standards)
├── 06-08  质量体系      (dod, id-system, quality-gates)
├── 09-11  模板与工具    (templates, lint-rules, ai-collaboration)
├── 12-16  运营与执行    (operations, runtime-engine, agent-protocols, registry, ci-cd)
├── 17-19  风险与演进    (risk-and-decisions, maturity, self-improving)
├── 20-23  治理闭环      (metrics-evidence, controlled-rsi, delivery-os, workflow-governance)
├── 24-26  分析与标准    (standard-unification-analysis, execution-guide, rsi-full-standard)
├── agent-cross-platform-compatibility.md
├── README.md / GLOSSARY.md / CHANGELOG.md
├── schema/   (4 个 YAML Schema)
├── tools/    (11 个可执行脚本)
└── change-requests/ (CR 提案记录)
```

### 文件规模统计

| 类别           | 数量  | 说明                                                               |
| -------------- | ----- | ------------------------------------------------------------------ |
| 核心方法论文档 | 26 个 | 00-26 号编号文件                                                   |
| 入口与索引     | 4 个  | README / GLOSSARY / CHANGELOG / authority-map                      |
| 分析报告       | 2 个  | standard-unification-analysis / agent-cross-platform-compatibility |
| YAML Schema    | 4 个  | goal / matrix / evidence / state-dictionary                        |
| 工具脚本       | 11 个 | Bash + Python 3                                                    |
| 变更请求       | 1 个  | CR-20260610-goal-protected-assets-sync.md                          |

---

## 二、11 层主流程管线

```
Goal → Spec → Design → Plan → Tasks → Prompt → Code → Test → Review → Release → Retrospective
```

每一层回答一个核心问题：

| 层级          | 核心问题                   | 输出物           | 关联 Gate | 阻断条件                                         |
| ------------- | -------------------------- | ---------------- | --------- | ------------------------------------------------ |
| Goal          | 为什么做？做到什么算成功？ | 目标定义         | G1        | 缺 owner、指标、验收标准或 non-goals             |
| Spec          | 具体要做什么？边界是什么？ | 需求规格         | G2        | 需求不可测试、P0/P1 AC 缺失                      |
| Design        | 怎么做？架构怎么拆？       | 设计方案 + ADR   | G3        | 需求无模块映射、循环依赖                         |
| Plan          | 任务按什么顺序执行？       | 执行计划         | G4        | 依赖顺序不合理、无验证点                         |
| Tasks         | 拆成哪些可执行任务？       | 任务清单 + DoD   | G5        | 不可独立验证、Matrix 孤儿                        |
| Prompt        | 如何让 AI 准确执行？       | Context Package  | G6        | 缺上下文或约束、实现越界                         |
| Code          | 最终实现是否满足验收？     | 代码 + 测试      | G6/G7     | 实现越界、测试失败                               |
| Test          | 实现是否正确？             | 测试报告         | G7/G8     | P0/P1 测试缺失、环境不可复现                     |
| Review        | 是否满足 Goal/Spec？       | 审查结论         | G9        | 未解决 P0/P1 finding、scope creep                |
| Release       | 是否可上线？               | Release Manifest | G10       | 缺 Manifest/Rollback、存在 release_blocking 风险 |
| Retrospective | 哪里可以改进？             | 复盘 + Patch     | G11       | 复盘未完成                                       |

**Matrix（追溯矩阵）** 是横切追溯制品，贯穿所有阶段但不在主流程中占位。在 Spec 后初始化，随 Design、Plan、Tasks、Prompt、Code、Test、Evidence 持续更新。

### 复杂度分级

| 复杂度 | 特征                 | 推荐流程                           |
| ------ | -------------------- | ---------------------------------- |
| XS     | 小修复，低风险       | Goal + Plan + Tasks + Code + Test  |
| S      | 小功能，影响单模块   | + Spec + Design                    |
| M      | 中型功能，影响多模块 | + Prompt + Matrix 横切             |
| L      | 大功能，跨团队       | 全流程                             |
| XL     | 架构级变化，高风险   | 全流程 + RFC + 风险评审 + 灰度计划 |

### 变更影响级别（CL0-CL5）

| 级别 | 说明              | 模式     | 强制 Gate              |
| ---- | ----------------- | -------- | ---------------------- |
| CL0  | 文档修正          | Lite     | G8, G9                 |
| CL1  | 局部实现修复      | Lite     | G5, G7, G8, G9         |
| CL2  | 模块行为变化      | Standard | 全 G0-G11              |
| CL3  | 公共接口变化      | Full     | + ADR + Human Approval |
| CL4  | 架构边界变化      | Full     | + Rollback Protocol    |
| CL5  | 数据模型/存储变更 | Full     | + Migration + Rollback |

---

## 三、Gate 体系（G0-G11）

12 个 Gate 构成完整的质量门禁链，分为三种类型：

| Gate | 名称                | 类型       | 阻断 | 关键检查                                   |
| ---- | ------------------- | ---------- | ---- | ------------------------------------------ |
| G0   | Context Gate        | Hybrid     | ✅    | 上下文恢复完整性、branch/commit/文档已加载 |
| G1   | Goal Gate           | Semantic   | ✅    | SMART 标准、owner、指标、non-goals         |
| G2   | Spec Gate           | Semantic   | ✅    | 需求可测试性、正常/异常/边界覆盖           |
| G3   | Design Gate         | Semantic   | ✅    | 模块映射、接口清晰、无循环依赖             |
| G4   | Plan Gate           | Semantic   | ✅    | 依赖顺序、验证点、回滚方案                 |
| G5   | Task / Matrix Gate  | Executable | ✅    | 原子性 + DoD + Matrix 覆盖无孤儿           |
| G6   | Implementation Gate | Executable | ✅    | **不允许 PASS_WITH_RISK**                  |
| G7   | Test Gate           | Executable | ✅    | 全部通过 + ≥80% 覆盖率                     |
| G8   | Evidence Gate       | Executable | ✅    | 证据完整、每项 AC 有对应证据               |
| G9   | Review Gate         | Semantic   | ✅    | 满足 Task/Spec/安全/性能要求               |
| G10  | Release Gate        | Hybrid     | ✅    | **不允许 PASS_WITH_RISK**                  |
| G11  | Retrospective Gate  | Semantic   | ❌    | 复盘完成、改进项已记录（非阻断）           |

### Gate 执行矩阵（最小可执行口径）

每个 Gate 有 6 个必备要素：

```yaml
gate_id:
  name: # Gate 名称
  type: # semantic | executable | hybrid
  blocking: # true | false
  scope: # 适用范围
  inputs: # 必备输入
  checks: # 检查项
  pass_criteria: # 通过标准
  fail_criteria: # 失败标准
  outputs: # 必备输出
  owner: # 负责人
```

### Gate 结果

4 个裁决值：`PASS` / `PASS_WITH_RISK` / `FAIL` / `BLOCKED`

- `NOT_STARTED` 和 `IN_PROGRESS` 只属于生命周期快照，不能作为 Gate 裁决
- `WAIVED` 是豁免策略记录，不是 Gate 结果值

### PASS_WITH_RISK 策略

| Gate  | 允许   | PASS 阈值 | 最低分 | 备注                        |
| ----- | ------ | --------- | ------ | --------------------------- |
| G0-G5 | ✅      | 90        | 80-85  | 需记录风险元数据            |
| G6    | **❌**  | 90        | —      | 实现 Gate 不允许风险通过    |
| G7-G9 | ✅      | 90        | 85     | 需记录风险元数据            |
| G10   | **❌**  | 90        | —      | Release Gate 不允许风险通过 |
| G11   | ✅      | 80        | 70     | 复盘 Gate（非阻断）         |

---

## 四、四轴状态模型

分离了 4 条独立的状态轴，消除"一个 status 字段多语义"的历史问题：

| 状态轴           | 含义                        | 合法值来源                                                                | 写入者                      |
| ---------------- | --------------------------- | ------------------------------------------------------------------------- | --------------------------- |
| `pipeline_state` | 全局管线状态机位置          | `03-pipeline.md` §2.1, §2.2                                               | Pipeline 运行器/Gate 仲裁器 |
| `current_phase`  | 当前主流程层级              | GOAL/SPEC/DESIGN/PLAN/TASKS/PROMPT/CODE/TEST/REVIEW/RELEASE/RETROSPECTIVE | 主流程推进时写入            |
| `phase_status`   | 当前层局部进度              | NOT_STARTED/READY/IN_PROGRESS/IN_REVIEW/DONE/BLOCKED/SKIPPED/STALE        | 阶段 owner 或 Gate 仲裁器   |
| `workflow_step`  | SOP/Runtime/CI 执行步骤投影 | `.config/goal/schema/rules.yaml` 投影                                     | 运行器/SOP/CI               |

### 正常状态流（13 个）

```text
INIT → CONTEXT_READY → GOAL_READY → SPEC_READY → DESIGN_READY
→ PLAN_READY → TASKS_READY → EXECUTING → VERIFYING
→ REVIEWING → RELEASING → RETROSPECTING → DONE
```

### 异常状态（8 个）

```text
BLOCKED             — 依赖缺失 / 权限缺失
FAILED              — 执行失败
NEEDS_RESEARCH      — 未知项阻塞决策
NEEDS_DECISION      — 多方案且影响 CL3+
NEEDS_REPLAN        — Spec/Design 变更影响 Plan
NEEDS_ROLLBACK      — Release Gate FAIL 后回滚
NEEDS_HUMAN_APPROVAL — CL3+ 变更需人工确认
INCONSISTENT_STATE  — Registry/Artifact/CI 冲突
```

### 回退规则

| From      | To                             | 条件                        |
| --------- | ------------------------------ | --------------------------- |
| VERIFYING | EXECUTING                      | Test Gate FAIL              |
| REVIEWING | EXECUTING                      | Review FAIL: implementation |
| REVIEWING | DESIGN_READY                   | Review FAIL: design         |
| RELEASING | NEEDS_ROLLBACK                 | Release Gate FAIL           |
| ANY       | BLOCKED                        | 依赖/权限缺失               |
| ANY       | NEEDS_RESEARCH/DECISION/REPLAN | 对应条件触发                |
| ANY       | INCONSISTENT_STATE             | Registry/Artifact/CI 冲突   |

---

## 五、Matrix 横切追溯

Matrix 是整个体系的核心控制平面，使用 **canonical edge model**（不使用旧 row model）。

### Canonical Edge 字段

| 字段                    | 说明                                                                  |
| ----------------------- | --------------------------------------------------------------------- |
| edge_id                 | 唯一边 ID，如 `EDGE-GOAL-20260610-001-AC01-TEST01`                    |
| source_type / source_id | 来源节点类型与 ID                                                     |
| target_type / target_id | 目标节点类型与 ID                                                     |
| relation                | canonical relation vocabulary（8 个枚举）                             |
| status                  | Unmapped/Mapped/Linked/Verified/Dropped/Blocked/Changed/Drifted/Stale |
| evidence_id             | release-critical edge 必填                                            |
| risk_id                 | High/Critical 或 release_blocking 风险必填                            |
| drop_reason             | Dropped 时必填                                                        |
| updated_at              | 最近更新日期                                                          |

### Canonical Relation Vocabulary（8 个）

| relation         | 含义                                      |
| ---------------- | ----------------------------------------- |
| `decomposes_to`  | 上游目标或需求分解为下游制品              |
| `contains`       | 上游制品包含下游制品                      |
| `accepted_by`    | 需求或结果由验收标准确认                  |
| `planned_by`     | 需求或任务由计划安排                      |
| `implemented_by` | 需求、任务或 Prompt 由代码实现            |
| `prompted_by`    | 执行由 Prompt 或 Context Package 驱动     |
| `verified_by`    | 需求、任务、代码由测试/审查证明           |
| `evidenced_by`   | Gate/Release/Risk 由 Evidence Bundle 证明 |

**严禁**将 `implements`、`verifies`、`blocks`、`releases` 等非标准词汇写入控制面。

### Matrix 合格标准

1. 每个 Goal 至少有一条到 Spec 或明确 Non-goal/Dropped 决策的 edge
2. 每个 Spec Requirement 至少有一条到 Task/Test/Decision 的 edge
3. 每个 P0/P1 AC 必须同时有 Test edge 与 Evidence edge
4. 每个 release-critical edge 必须有 status 和 evidence_id
5. 任何 Dropped edge 必须有 drop_reason 和审批记录
6. 不允许存在无来源 Task、无来源 Code、无证据 Done

### Matrix 状态流

```text
Unmapped → Mapped → Linked → Verified
                         ↘ Dropped（必须有 drop_reason）

Blocked/Changed/Drifted/Stale → Linked → Verified/Dropped
```

---

## 六、Agent 生态系统

### 核心 5 Agent（三平台同步）

| Agent               | 职责                    | Claude (.md) | Copilot (.md) | Codex (.toml) |
| ------------------- | ----------------------- | ------------ | ------------- | ------------- |
| goal-spec           | Goal/Spec/Registry 管理 | ✅ 348行      | ✅ 48行        | ✅ 39行        |
| goal-matrix         | 追溯矩阵生成维护        | ✅ 253行      | ✅ 49行        | ✅ 41行        |
| goal-reviewer       | Gate 状态审查           | ✅ 284行      | ✅ 55行        | ✅ 47行        |
| goal-prompt-builder | Context Package 构建    | ✅ 451行      | ✅ 48行        | ✅ 40行        |
| goal-evidence       | 证据收集验证            | ✅ 430行      | ✅ 66行        | ✅ 57行        |

### 辅助 5 Agent（仅 Claude Code）

| Agent                 | 职责                      |
| --------------------- | ------------------------- |
| goal-architect        | 架构边界、Design、ADR     |
| goal-context-recovery | 会话中断后恢复工作状态    |
| goal-governance       | SSOT 一致性审计、漂移检测 |
| goal-lint             | 制品 Lint 自动验证        |
| goal-planner          | 任务拆分与执行计划        |

### Agent 执行不变量

- **单 Task 单 Writer**：同一时间只能有一个 writer 修改可交付文件
- **Worktree 隔离**：并行任务必须使用 worktree 或等价机制
- **Reviewer/Writer 分离**：至少区分 writer、reviewer、verifier
- **禁止绕过 Gate**：Gate FAIL/BLOCKED 时只能修复/补证据/重计划/发起 CR
- **Hypothesis 标记**：不可确认内容必须标记，不得放入 Release Manifest
- **漂移即 CR**：Agent/CI/schema 投影/Constitution 与 docs/goal/ 漂移时 MUST 生成 Change Request

---

## 七、Schema 与工具生态

### 4 个 YAML Schema（Phase 1 权威化）

| Schema                  | 核心内容                                           | 解决问题            |
| ----------------------- | -------------------------------------------------- | ------------------- |
| `goal.schema.yaml`      | 18 字段 + 三源映射表（standard/template/registry） | Goal 字段命名不一致 |
| `matrix.schema.yaml`    | 14 canonical 字段 + 8 relation + 9 状态枚举        | Matrix 字段漂移     |
| `evidence.schema.yaml`  | Evidence 文件 11 必填 + Bundle 17 必填             | Evidence 字段漂移   |
| `state-dictionary.yaml` | 5 类状态统一枚举                                   | 5 种命名风格混用    |

### 状态字典 5 类归并

| Category          | 用途             | 命名约定    | 示例                             |
| ----------------- | ---------------- | ----------- | -------------------------------- |
| lifecycle_status  | 对象生命周期     | Title Case  | `Draft`, `Active`, `Achieved`    |
| runtime_phase     | 运行时阶段       | UPPER_SNAKE | `INIT`, `SPEC_READY`, `DONE`     |
| gate_result       | Gate 裁决        | UPPER       | `PASS`, `FAIL`, `BLOCKED`        |
| metric_conclusion | 指标验证结论     | snake_case  | `achieved`, `partially_achieved` |
| matrix_status     | Matrix Edge 状态 | Title Case  | `Verified`, `Dropped`, `Stale`   |

### 11 个可执行工具

| 工具                    | 语言   | 功能                                                     |
| ----------------------- | ------ | -------------------------------------------------------- |
| `goal-workflow.sh`      | Bash   | **统一入口**：preflight / validate / gate / ci / release |
| `goal-delivery.sh`      | Bash   | 端到端编排：11 层制品创建 + Gate 检查 + auto/change 命令 |
| `goal-validate.py`      | Python | 控制面一致性验证（audit / strict 双模式）                |
| `matrix-gen.py`         | Python | Matrix 生成与 check-only                                 |
| `gate-check.sh`         | Bash   | Gate 制品就绪检查（Matrix 覆盖率 / Evidence / 孤儿检查） |
| `evidence-collect.sh`   | Bash   | Evidence 自动收集（Git diff + 测试结果）                 |
| `lint-goal.sh`          | Bash   | Goal / Spec / Matrix / Prompt Lint 规则检查              |
| `rule-drift-check.py`   | Python | 规则漂移扫描（旧路径 / 旧状态 / 旧 ID）                  |
| `self-test.sh`          | Bash   | 工具链自测（正例 + 负例 fixture）                        |
| `setup-ci-toolchain.sh` | Bash   | CI Python 环境隔离（venv 或 pip --target fallback）      |
| `goal-release-gate.sh`  | Bash   | 发布硬阻断（strict validator + G10 + Evidence）          |

### 命令剖面

```text
preflight → validate → gate → ci → release
  工具自检    控制面验证  制品就绪  CI聚合   发布硬阻断
```

执行口径：

- `preflight`：Python 编译、Shell 语法、规则漂移、Goal 文档 lint
- `validate`：preflight + strict 控制面验证 + Matrix check-only（PR 默认检查）
- `gate`：validate + Gate 制品就绪检查（有运行制品时）
- `ci`：validate + 工具链自测 + 自动 Gate（CI 聚合入口）
- `release`：gate + Release hard blocker（tag/release 前硬阻断）

---

## 八、治理与受控改进

### Controlled RSI（受控递归改进）

通过 R0-R9 共 10 道控制 Gate 确保自我改进不会降低质量：

| Gate                      | 证明对象           | 阻断条件                                 |
| ------------------------- | ------------------ | ---------------------------------------- |
| R0 Evidence Intake        | 改进有事实来源     | 没有失败证据/评审发现/事故记录           |
| R1 Scope Classification   | 改进对象分类正确   | 把 Goal 语义伪装成模板优化               |
| R2 Protected Asset Check  | 是否触碰受保护资产 | 需改 Constitution/CI/agent 配置但没有 CR |
| R3 Safety Preservation    | 不降低现有约束     | 删除失败测试/降低 Gate/放宽证据要求      |
| R4 Evaluation Replay      | 历史案例可回放     | 改动无法用历史样例验证                   |
| R5 Projection Consistency | 投影与 SSOT 一致   | schema/CI/Agent 配置与 docs/goal/ 漂移   |
| R6 Approval               | 审批状态明确       | Propose-only 项没有 workflow owner 审批  |
| R7 Rollout Scope          | 灰度范围可控       | 无适用范围/回退边界/版本记录             |
| R8 Rollback               | 可回滚             | 无 rollback plan                         |
| R9 Retrospective          | 改进效果可衡量     | 无后续指标/复盘窗口                      |

### 四策略级别

| 级别              | 允许动作                 | 示例                              |
| ----------------- | ------------------------ | --------------------------------- |
| Auto-allowed      | 不改变语义的澄清修复     | 修正错字、补充字段说明            |
| Propose-only      | 可能影响执行行为的建议   | 新 Gate、新 Prompt 约束           |
| Approval-required | 改变工作流版本或评分规则 | 修改门禁阈值                      |
| Forbidden         | 降低质量/安全/追溯要求   | 删除失败测试、跳过 Metrics Review |

### 禁止自动改动清单

- Goal 核心目标、非目标和成功指标
- P0/P1 验收标准
- 安全/隐私/资金/权限/数据保留约束
- 发布 Gate、回滚要求和事故处理要求
- 生产代码和生产配置
- 失败测试、测试标准和证据要求

### 不变量（绝对不变）

- 不修改原始目标来适配实现结果
- 不删除失败证据来获得通过
- 不用新指标替代旧指标（除非 CR 记录映射）
- 不把建议型改进伪装成自动批准
- 不让同一 Agent 同时绕过 builder/reviewer 分离
- 不降低安全、隐私、资金、权限和数据约束

### Change Request 机制

受保护资产修改前 MUST 生成 CR 并标记 Human Approval：

- `CONSTITUTION.md`
- `.github/workflows/`
- `.config/goal/schema/rules.yaml`
- `.claude/agents/` / `.codex/agents/`
- Release Gate、Rollback、Incident、P0/P1 AC
- 安全、隐私、资金、权限、数据保留规则

### 人工审批检查（H-CHK1 ~ H-CHK8）

| 检查项 | 名称                                  | 适用级别     |
| ------ | ------------------------------------- | ------------ |
| H-CHK1 | Spec Freeze Approval                  | CL3+         |
| H-CHK2 | Design Review Approval                | CL3+         |
| H-CHK3 | Public API Change Approval            | CL3+         |
| H-CHK4 | Architecture Boundary Change Approval | CL4+         |
| H-CHK5 | Migration Approval                    | CL5          |
| H-CHK6 | Risk Acceptance Approval              | CL3+         |
| H-CHK7 | Release Approval                      | 所有 Release |
| H-CHK8 | Rollback Approval                     | CL3+         |

---

## 九、跨平台兼容性

### 三平台 Agent 同步状态（2026-06-12 审计）

**核心 5 Agent** 三平台全部同步。辅助 5 Agent 仅 Claude Code 实现——按 `14-agent-protocols.md` 设计此为预期差异，非漂移。

**Codex 端已修复 4 处幻影引用**：

- `02-goal-schema.md` → `02-goal-standard.md`
- `07-human-approval.md` → `06-dod.md`
- `09-tasks-and-prompt.md` → `09-templates.md`（2 处）

**Copilot CLI Smoke**：45/45 PASS，跨路径兼容确认无问题。

### 权威层级声明

三平台 Agent 均以相同顺序声明权威：

1. CONSTITUTION.md
2. docs/goal/00-authority-map.md
3. docs/goal/ 核心文档集
4. .config/goal/schema/rules.yaml

---

## 十、Delivery OS 架构（Vision）

Delivery OS 将 Goal 工作流从文档方法升级为可执行工程系统。当前标记为 **愿景架构（Vision）**，部分能力已通过 Goal Agent 和 `.config/goal/` 目录落地。

### 五个运行时

| Runtime             | 管理对象                         | 关键产物                      |
| ------------------- | -------------------------------- | ----------------------------- |
| Intent Runtime      | 用户目标、业务边界、成功指标     | Goal、Spec、Non-goals         |
| Control Runtime     | 追溯、策略、门禁、变更控制       | Matrix、Policy、Gate、CR      |
| Execution Runtime   | 任务、计划、Prompt、允许修改范围 | Task、Plan、Prompt Pack       |
| Evidence Runtime    | 测试、评审、发布、运行指标       | Test Report、Review、Metrics  |
| Improvement Runtime | 复盘、根因、工作流补丁、评分     | RCA、Backlog、Eval、Scorecard |

### Workflow-as-Code 命令概念

```text
workflow compile         — 从 Goal/Spec/Matrix 编译任务和 Gate 要求
workflow lint            — 检查缺字段、孤儿项、越界文件
workflow test            — 用历史样例回放工作流规则
workflow prompt build    — 生成带上下文、边界和验证命令的 Prompt Pack
workflow review pr       — 检查 PR 是否满足追溯、测试和证据要求
workflow release check   — 验证发布、回滚和指标观测条件
workflow improve analyze — 从失败证据生成改进候选
```

### 治理机制（10 项）

| 机制                          | 目的                     |
| ----------------------------- | ------------------------ |
| Provenance                    | 记录每个证据和决策的来源 |
| Snapshot                      | 固化发布时的全量状态     |
| Immutable Delivery Record     | 防止事后重写交付事实     |
| Pre-mortem                    | 实现前枚举失败路径       |
| Red Team Review               | 安全/隐私/资金对抗性审查 |
| Builder/Reviewer Separation   | 避免同一角色自证正确     |
| Judge Agent                   | 汇总证据并判定 Gate      |
| Model Routing                 | 探索/执行/审查分层       |
| Context Budget                | 控制输入规模             |
| Rollback/Progressive Delivery | 降低发布风险             |

---

## 十一、深度评估

### 核心优势

1. **体系完整性极高**
   从 Goal 定义到 Retrospective 复盘，覆盖软件交付全生命周期，形成可追溯、可验证、可自我改进的工程闭环。26 个规范文件 + 4 个 schema + 11 个工具构成自举体系。

2. **SSOT 权威边界清晰**
   `00-authority-map.md` 明确定义了 21 个主题的权威来源、可投影位置和禁止事项，有效防止文档腐化。配置与运行态边界（docs/goal/、.config/goal/ 与 OMX runtime state directory）划分明确。

3. **Schema 权威化设计优秀**
   4 个 YAML Schema 将人类文档、模板、Registry 三源字段统一为 canonical 字段，`field_mapping` 表清晰标注了标准/模板/Registry 三处的字段名差异。`state-dictionary.yaml` 将历史上混用的 5 种命名风格归并为 4 类状态字段，规定唯一大小写和允许值。

4. **Matrix Edge Model**
   将追溯从传统表格升级为有向图（canonical edge），`relation` 严格枚举 8 个词汇，消除了 `implements`/`verifies`/`blocks`/`mitigates` 等口语化 relation 的歧义。旧表格视图可作为展示存在，但进入控制面前必须投影为 canonical edge。

5. **工具链自洽性高**
   `self-test.sh` 覆盖 7 类正负例 fixture，工具之间互相验证：`goal-validate.py` 校验 Matrix 字段 → `gate-check.sh` 校验 Evidence 完整性 → `rule-drift-check.py` 扫描旧路径 → `lint-goal.sh` 检查文档规则。形成自举验证闭环。

6. **三平台 Agent 同步**
   5 个核心 Agent 在 Claude/Copilot/Codex 三平台保持同步。Codex 端 4 处幻影引用已修复。Copilot CLI 全量 Smoke 45/45 PASS。按 `14-agent-protocols.md` 设计，辅助 Agent 为可选的 Claude 专属能力——此差异符合设计，非漂移。

7. **Controlled RSI 设计成熟**
   10 道 R Gate（R0-R9）确保改进不会降低安全性。4 级策略（Auto-allowed/Propose-only/Approval-required/Forbidden）+ 角色分离（Code Agent/Review Agent/Improvement Agent/Workflow Owner/Verifier）形成多层安全防护。7 条不变量绝对禁止降低质量门槛。

### 待改进点

1. **文档总量偏大**
   30+ 文件对首次使用者有较高的认知负荷。虽有三层阅读路径（30 分钟 / 2 小时 / 4 小时），但 `26-rsi-full-standard.md`（43KB）和 `agent-cross-platform-compatibility.md`（16KB）等文件超出单一规范的合理范围。建议考虑拆分为独立子目录或引入"核心/扩展"分层。

2. **愿景与现实差距**
   `22-delivery-os.md` 和 `23-workflow-governance-checks.md` 标记为 Vision 状态。五个 Runtime、Workflow Compiler、Prompt Compiler 等架构概念尚未完整实现。当前实际可用的工具链集中在 `goal-workflow.sh` 和 `goal-delivery.sh` 两个入口。

3. **ID 系统复杂度**
   7 种 ID 格式（`GOAL-YYYYMMDD-NNN`、`SPEC-domain-vN`、`TASK-GOAL-YYYYMMDD-NNN-NNN`、`PROMPT-TASK-GOAL-YYYYMMDD-NNN-NNN-NNN`、`EVID-TEST-TASK-GOAL-YYYYMMDD-NNN-NNN-NNN-NNN`、`RISK-GOAL-YYYYMMDD-NNN-NNN`、`TEST-TASK-GOAL-YYYYMMDD-NNN-NNN-NNN`）存在深层嵌套依赖。人工手写容易出错，建议增强 `matrix-gen.py` 的 ID 自动生成能力。

4. **跨仓库推广成本**
   体系设计为单仓库（ZoneCNH homepage）自举。~70 个独立仓库的实际采纳需要：各仓库配置 `.config/goal/` 控制面、集成 CI workflow、培训 Agent 使用。建议产出"单仓库最小部署包"降低采纳门槛。

5. **人工审批瓶颈**
   CL3+ 变更必须 Human Approval，H-CHK1~H-CHK8 共 8 类审批场景。在无专职 workflow owner 的团队中可能成为阻塞点。建议为 CL2 级变更提供"Agent 互审替代人工审批"的受控路径。

6. **Lint 自动化率尚有提升空间**
   35 条规则中 27 条已自动化（77%），剩余 5 条为 manual（S-LINT 部分需上下文判断），3 条为 planned。建议优先完成 S-LINT-004~008 的半自动化（规则匹配 + 标记需人工确认），以及 P-LINT 与 Code Lint 的 planned 规则。

### 标准统一度评分

来源：`24-standard-unification-analysis.md`（2026-06-12 修订）

| 维度            | 评分 / 100 | 状态                                      |
| --------------- | ---------- | ----------------------------------------- |
| 状态枚举        | 88         | ✅ — state-dictionary.yaml 已归并 5→4 类   |
| Goal Schema     | 85         | ✅ — goal.schema.yaml + 三源映射表         |
| Matrix Schema   | 85         | ✅ — canonical edge + relation vocabulary  |
| 运行时目录      | 82         | ✅ — .config/goal/ 已收敛                  |
| Gate 编号与权威 | 82         | ✅ — PASS_WITH_RISK 策略已文档化           |
| Evidence Schema | 82         | ✅ — evidence.schema.yaml                  |
| Agent 跨平台    | 80         | ✅ — 核心 5 Agent 三平台同步               |
| Lint 与工具覆盖 | 77         | ⚠️ — 27/35 自动化（77%）                  |
| ID 与版本       | 72         | ⚠️ — vN/vN.N 已分离，但仍复杂             |
| **综合**        | **81**     |                                           |

---

## 十二、文件间引用拓扑

核心依赖图（↓ 表示"权威定义在"）：

```text
CONSTITUTION.md（最高治理 — 冲突时覆盖 docs/goal/）
    ↓
00-authority-map.md（SSOT 边界 + 投影规则 + 21 个主题权威表）
    ↓
┌───────────────────────────────────────────────────────┐
│  03-pipeline.md      ← 管线 + 四轴状态模型 SSOT       │
│  04-gates.md         ← Gate 编号/阻断/结果 SSOT       │
│  05-layer-standards.md ← 各层标准 + Matrix Edge SSOT  │
│  06-dod.md           ← DoR/DoD SSOT                   │
│  07-id-system.md     ← ID 格式 SSOT                   │
│  02-goal-standard.md ← Goal 结构/模板/评分 SSOT       │
└───────────────────────────────────────────────────────┘
    ↓                    ↓                    ↓
┌──────────────┐  ┌──────────────┐  ┌──────────────────┐
│ schema/      │  │ tools/       │  │ README.md        │
│ 4 YAML       │  │ 11 脚本      │  │ GLOSSARY.md      │
│ (机器事实源) │  │ (可执行验证) │  │ CHANGELOG.md     │
└──────────────┘  └──────────────┘  │ 25-exec-guide.md │
    ↓                    ↓          └──────────────────┘
┌───────────────────────────────────────────────────────┐
│ .config/goal/     ← 控制面运行制品                    │
│ .claude/agents/   ← Claude Agent 投影                 │
│ .codex/agents/    ← Codex Agent 投影                  │
│ .copilot/agents/  ← Copilot Agent 投影                │
│ .github/workflows/ ← CI/CD 执行面                     │
└───────────────────────────────────────────────────────┘
```

---

## 十三、最小可执行修复建议

基于当前统一度 81/100，建议优先处理以下高收益事项：

| 优先级 | 事项                                                 | 预期收益               | 工作量 |
| ------ | ---------------------------------------------------- | ---------------------- | ------ |
| P0     | S-LINT-004~008 半自动化（规则匹配 + 标记需人工确认） | Lint 自动化率 77%→91%  | 中     |
| P0     | 产出"单仓库最小部署包"降低采纳门槛                   | 降低 ~70 仓库推广成本  | 中     |
| P1     | 为 CL2 变更提供"Agent 互审"受控路径                  | 缓解人工审批瓶颈       | 小     |
| P1     | 增强 matrix-gen.py 的 ID 自动生成                    | 降低 ID 手写出错率     | 中     |
| P1     | 拆分 `26-rsi-full-standard.md` 为独立子目录          | 降低首次阅读负荷       | 小     |
| P2     | Vision 文档（22/23）的逐步落地路线图                 | 弥合愿景与现实差距     | 大     |
| P2     | P-LINT 与 Code Lint planned 规则实现                 | Lint 自动化率 91%→100% | 中     |

---

## 十四、总结

`docs/goal/` 是一套**工程成熟度极高的自举式交付方法论**。它不是简单的"写文档规范"，而是将软件交付全生命周期建模为一套可执行、可验证、可追溯、可自我改进的工程系统。

**核心创新点**：

- **四轴状态模型** — 解决了传统单一 status 字段在多场景下的语义混乱
- **Matrix Edge Model** — 将追溯从表格升级为强类型有向图，relation 严格枚举消除歧义
- **Controlled RSI** — 用 10 道 Gate（R0-R9）确保自我改进不会降低质量，配合角色分离防止自批自改
- **Schema 权威化** — 用机器可读 YAML 统一人类文档间的字段漂移，field_mapping 表透明追踪三源差异
- **三平台 Agent 投影** — 核心 5 Agent 在 Claude/Copilot/Codex 三平台保持语义等价，平台投影不成为新规则源

当前综合统一度 **81/100**，核心体系已基本收敛。剩余工作主要在于：(1) Lint 自动化率从 77% 提升到 100%；(2) 跨仓库推广的"最小部署包"；(3) Vision 文档的逐步落地。
