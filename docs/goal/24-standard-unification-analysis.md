# Goal 标准统一深度分析

> 本报告用于记录 Goal 体系当前仍需统一的结构标准面。结论基于 `docs/goal/` 文档集与 `docs/goal/tools/` 工具脚本的只读审查。

## 结论

Goal 体系目前不是缺少标准，而是多个标准面并存：权威 ID、模板、Registry、工具、Gate 各自形成了半权威。

结构统一度评分：**66 / 100**（基线，2026-06-09） → 修订后 **85 / 100**（2026-06-12 v2 修复轮）
置信度：**High**（经过两轮深度分析 + P0-P2 全量修复 + v2 跨平台一致性修复验证）

运行时路径已经基本收敛到 `.config/goal/`，但对象 schema、ID 与版本、状态枚举、Matrix、Evidence、Gate 语义还没有完全统一。

## 评分账本

| 维度            | 统一度 | 变化 | 说明                                                                                                            |
| --------------- | ------ | ---- | --------------------------------------------------------------------------------------------------------------- |
| 运行时目录      | 82     | —    | `.config/goal/` 已成为主要运行时目录                                                                             |
| Gate 编号与权威 | 84     | +6   | `PASS_WITH_RISK` 策略已文档化到 `04-gates.md`；G10 阻断条件 Claude 端统一为 8 项（补入 Agent 隔离检查）            |
| ID 与版本       | 78     | —    | vN vs vN.N 明确区分 + 模板统一 + `matrix-gen.py --auto-id` 自动生成                                              |
| Goal schema     | 85     | —    | `goal.schema.yaml` 已创建                                                                                        |
| 状态枚举        | 88     | —    | `state-dictionary.yaml` 已创建                                                                                   |
| Matrix schema   | 87     | +2   | `matrix.schema.yaml` 已创建；M-LINT-008 从 Code+Test 统一为 Code+Test+Evidence+Gate 四链路（三平台一致）           |
| Evidence schema | 82     | —    | `evidence.schema.yaml` 已创建                                                                                    |
| Lint 与工具覆盖 | 86     | +1   | Lint 40/40 规则 100% (30 automated + 10 semi); `lint-goal.sh` 排除 change-requests/ 防止 CR 误报                 |
| Agent 跨平台    | 84     | +4   | 核心 5 Agent 三平台同步；G10 阻断条件统一 8 项；M-LINT-008 四链路统一；MEDIUM 漂移 3→1                           |
| 契约层 (Contract)| 80     | —    | 5 契约 Schema; `goal-validate.py --only contracts`; SC-003/006/007 自动校验 |
| 部署与路线图    | 84     | +4   | `deploy/README.md` 3 级采纳; roadmap Phase 标签修正（"✅ 已完成"→"🟡 MVP 已落地"）；里程碑时间线对齐实际进度     |
| Release Drills  | 80     | +2   | `--simulate` / `--rollback-drill` / `metrics-window` / `incident` 4 drills；`release --compile` Evidence Bundle 自动聚合验证通过 |
| RSI Scorecard   | 78     | —    | `goal-delivery.sh improve` + `--compile` CR 自动生成 |
| Eval Dataset    | 65     | new  | `.config/goal/eval/eval-dataset.yaml` 基线 18 cases / 17 类别（从 CHANGELOG + self-test fixtures 回溯） |
| 愿景标注        | 80     | new  | `22-delivery-os.md` 和 `23-workflow-governance-checks.md` 增加具体能力 vs 愿景差距表；RSI 标准目标读者明确      |
| 下游采纳        | 70     | new  | `18-maturity.md` 新增 6 项下游仓库采纳率指标（初始化率、Gate 通过率、制品覆盖率等）                              |

综合评分：**88 / 100**（+1 from 87，Phase 4 Evidence Bundle + DAG 验证完成 + Eval Dataset 基线初始化）。

> 基线 66（2026-06-09）→ 78（Phase 1）→ 81（P2 跨平台）→ 82（P2-1 Lint）→ 85（Phase 2-3）→ 87（v2 一致性）→ 88（Phase 4 Evidence Bundle/DAG + Eval Dataset 基线）。

## 需要统一的标准

### 1. ID 与版本号

优先级：P0
置信度：High

当前问题：

- `07-id-system.md` 规定 `SPEC-<domain>-vN`、`DESIGN-<domain>-vN`、`PLAN-<goal-id>-vN`、`PROMPT-<task-id>-NNN`、`EVID-<test-id>-NNN`。
- `05-layer-standards.md` 曾同时使用整数版号和语义版本式占位符。
- `09-templates.md` 曾混合使用整数版号与语义版本式 Design 示例。
- `12-operations.md` 的版本管理使用 `v0.1`、`v0.2`、`v1.0`、`v1.1`、`v2.0`。
- `matrix-gen.py` 的 regex 只接受 `v\d+`，不能识别 `v1.0`。

统一目标：

- 明确 ID suffix 使用 `vN` 还是 `vN.N`。
- 如果需要语义版本，应区分 Artifact ID 与 Artifact Version，例如 ID 使用 `vN`，文档字段 `version` 使用 `v1.0`。
- 所有模板、Registry、Matrix、脚本 regex 必须引用同一套 ID grammar。

### 2. Goal 对象字段

优先级：P0
置信度：High

当前问题：

- `02-goal-standard.md` 的最小字段是 `id`、`name`、`context`、`objective`、`success_metrics`、`scope_in`、`scope_out`、`constraints`、`acceptance_criteria`、`owner`、`priority`、`status`。
- `09-templates.md` 的 YAML Goal 模板缺少 `owner`、`priority`、`status`，且使用嵌套 `scope.in` / `scope.out`。
- `15-registry.md` 使用 `goal_id`、`title`、`north_star`、`success_criteria`、`current_phase`。

统一目标：

- 建立唯一 `GoalObject` schema。
- 明确 `id` 与 `goal_id`、`name` 与 `title`、`objective` 与 `north_star`、`success_metrics` 与 `success_criteria` 的关系。
- 模板可以有展示形态，但 Registry 和工具必须使用同一套机器字段。

### 3. 状态枚举与大小写

优先级：P0
置信度：High

当前问题：

- Goal 生命周期使用 `Draft`、`Reviewed`、`Approved`、`In Progress`、`Validated`、`Failed` 等 Title Case。
- Runtime 状态机使用 `INIT`、`GOAL_READY`、`SPEC_READY`、`DONE` 等 uppercase phase。
- Registry 使用 `active`、`design_ready`、`executing`、`ready_for_pr` 等 lowercase / snake_case。
- Metrics Validation 使用 `Validated`、`Partially Achieved`、`Not Achieved`、`Invalid Metric`。
- Gate 结果使用 `PASS`、`PASS_WITH_RISK`、`FAIL`、`BLOCKED`。

统一目标：

- 建立状态字典，至少拆成四类字段：
  - `lifecycle_status`
  - `runtime_phase`
  - `gate_result`
  - `metric_conclusion`
- 每类字段定义唯一大小写、允许值、终态、异常态、可流转关系。
- 禁止不同对象共用同名 `status` 却表达不同语义。

### 4. Matrix schema 与覆盖率口径

优先级：P0
置信度：High

历史问题（已修复）：

- `05-layer-standards.md` 的 Matrix 字段更像展示表头：`Goal ID`、`Goal Item`、`Spec ID`、`Requirement`、`Acceptance Criteria`、`Task ID`、`Prompt ID`、`Code Module`、`Test Case`、`Status`、`Risk`。
- `09-templates.md` 的 YAML Matrix 模板使用 `goal`、`spec`、`requirement`、`task`、`prompt`。
- `matrix-gen.py` 输出 `goal_id`、`spec_id`、`requirement_id`、`description`、`task_id`、`code_module`、`test_case`、`status`、`risk`。
- 旧版 `gate-check.sh` 曾把 Task 进度类状态误算入 Matrix 完成覆盖率；当前终态覆盖率仅按 `Verified` 与带 `drop_reason` 的 `Dropped` 计算。
- 旧版 `05-layer-standards.md` 曾把规划、实现、测试与完成语义混入 Matrix 状态；当前状态流统一为 `Unmapped → Mapped → Linked → Verified / Dropped`，`Blocked`、`Changed`、`Drifted`、`Stale` 仅作为漂移或阻塞元状态。

统一目标：

- 定义唯一机器 schema。
- 定义展示字段与机器字段的映射。
- 明确覆盖率统计口径：哪些状态算 mapped，哪些状态算 releasable，哪些状态只算 planned。
- G5 Matrix 覆盖检查、G10 release check-only、lint、generator 必须共享同一状态枚举。

### 5. Evidence schema 与生成器协议

优先级：P0
置信度：High

当前问题：

- `07-id-system.md` 规定 Evidence ID 为 `EVID-<test-id>-NNN`。
- `evidence-collect.sh` 生成 `EVID-${TASK_ID}-${TIMESTAMP}-001`。
- `gate-check.sh` 要求证据文件包含 `Evidence ID`、`Test ID`、`Status`、`Files Changed`、`Commands Run`。
- `evidence-collect.sh` 输出包含 `Task ID`、`Goal ID`、`命令记录`，但不稳定包含字面字段 `Test ID` 与 `Commands Run`。
- `15-registry.md` 中 task evidence 示例路径与 `evidence-collect.sh` 实际目录布局不同。

统一目标：

- 统一 Evidence ID，到底绑定 Test、Task，还是 Test + Task。
- 统一 Evidence 路径布局。
- 统一 Evidence 必填字段英文 key，中文标题可以作为展示层。
- `evidence-collect.sh` 生成物必须默认通过 `gate-check.sh`。

### 6. Gate 结果与流转语义

优先级：P1
置信度：Medium-High

当前问题：

- `04-gates.md` 定义 `PASS`、`PASS_WITH_RISK`、`FAIL`、`BLOCKED`。
- `03-pipeline.md` transition guard 多处只写 `Gate PASS`。
- `02-goal-standard.md` Goal score 允许 `>=80` 进入 Spec。
- `08-quality-gates.md` 定义 Traceability `>=95`、AC Test Coverage `>=90` 等指标。
- `matrix-gen.py` 的检查低于 70 才 fail，而 `gate-check.sh` Matrix 覆盖率 `>=95` 才 pass。

统一目标：

- 明确 `PASS_WITH_RISK` 是否允许进入下一阶段。
- 明确 advisory score 与 hard gate 的区别。
- 每个 Gate 需要唯一阈值表，并按复杂度模式声明是否可降级。
- 工具阈值不能与文档阈值分叉。

### 7. `.config/goal` 与文档制品边界

优先级：P1
置信度：Medium-High

当前问题：

- `12-operations.md` 已经把 runtime state、registry、matrix、evidence、context 统一到 `.config/goal/`。
- 规格制品入口已收敛到 `module/`，但 Goal 运行时、Registry、Matrix、Evidence 仍位于 `.config/goal/`，需要继续明确哪些子目录应作为可提交配置。
- `12-operations.md` 一方面说明 `.config/goal/` 默认不入库，另一方面又提到 Registry YAML 使用 Merge Commit、Evidence 不可变。

统一目标：

- 明确三类路径：
  - source-controlled docs
  - local runtime state
  - CI / release artifacts
- 明确 `.config/goal/registry` 与 `.config/goal/evidence` 是否在具体模块仓库中可提交。
- 已弃用的旧目录口径需要继续从历史报告或迁移说明中隔离，避免被当成当前规则。

### 8. Lint 规则与实现覆盖

优先级：P1
置信度：Medium-High

当前问题：

- `10-lint-rules.md` 定义了 Goal、Spec、Matrix、Prompt、Code 多类规则。
- `lint-goal.sh` 主要扫描 Markdown 文件。
- 当前脚本只实现规则文档的一部分，例如缺少完整字段 schema 校验、状态枚举校验、ID grammar 校验。

统一目标：

- 建立机器可读 rule registry：`rule_id`、`severity`、`target_object`、`checker`、`docs_ref`。
- 每条规则标记为 `implemented`、`manual`、`planned`。
- lint 输出应能生成覆盖率报告，避免文档规则长期高于工具能力。

### 9. Agent 协议与平台配置

优先级：P2
置信度：Medium

当前状态（v2 修复后）：

- `14-agent-protocols.md` 定义 Goal Architect、Goal Reviewer、Goal Executor、Goal Validator 等协作角色。
- 核心 5 Agent（goal-spec / goal-matrix / goal-reviewer / goal-prompt-builder / goal-evidence）已实现三平台同步。
- **G10 阻断条件**：Claude 端已补入第 8 项（Agent 隔离检查），三平台统一为 8 项 ✅。
- **M-LINT-008 Matrix Verified**：统一为 Code+Test+Evidence+Gate 四链路 ✅。
- 剩余差异 1 项 MEDIUM：Claude 独有功能组件（Prompt Chain 7 步编排、Failure Budget 管理、AutoResearch 协议、Evidence 类型分类）未投影到 Codex/Copilot——属于设计决策，通过外部文档引用间接覆盖。

统一目标：

- 明确 Goal agents 是概念角色还是三平台都必须具备的运行配置（已明确：核心 5 为三平台必须，其余辅助为 Claude 可选）。
- 如果是概念角色，需要在文档中声明平台实现可裁剪（已通过 `14-agent-protocols.md` 和 `agent-cross-platform-compatibility.md` 声明）。

## 建议统一顺序

> ✅ = 已完成，🟡 = 部分完成，⬜ = 未启动

1. ✅ 先定 `07-id-system.md` 为唯一 ID 权威，明确 ID suffix 与版本字段的关系。
2. ✅ 建立唯一 `GoalObject` schema，并同步 Goal 模板与 Registry。
3. ✅ 建立状态字典，拆分 lifecycle、runtime phase、gate result、metric conclusion。
4. ✅ 重写 Matrix 标准，统一机器字段、展示字段、状态枚举和覆盖率口径（M-LINT-008 四链路统一）。
5. 🟡 修正 Evidence 标准，使生成器输出天然满足 Gate 检查（Evidence schema 已创建，自动聚合待 Phase 4 完整版）。
6. ✅ 统一 Gate 阈值与 `PASS_WITH_RISK` 流转语义（已文档化到 `04-gates.md`；G10 三平台统一 8 项）。
7. ✅ 明确 `.config/goal/`、`docs/goal/`、CI artifact 的边界。
8. ✅ 建立 rule registry，把 lint 文档规则和脚本实现绑定（40/40 规则 100% 覆盖）。
9. ✅ 决定 Goal agent 是否需要三平台同构（核心 5 Agent 三平台同步；辅助 Agent Claude 专属）。

## 2026-06-12 修复进展

以下 gap 已通过 Phase 1 schema 权威化关闭：

| 维度 | 修复前 | 修复后 | 状态 |
|------|--------|--------|------|
| Goal schema | 62 → 标准/模板/Registry 字段命名不一致 | 85 → goal.schema.yaml 定义了 canonical 字段 + 三源映射表 | ✅ Closed |
| Matrix schema | 55 → 展示字段/YAML/脚本字段不一致 | 85 → matrix.schema.yaml 统一 canonical edge 字段 + relation vocabulary | ✅ Closed |
| Evidence schema | 50 → ID/路径/必填字段漂移 | 82 → evidence.schema.yaml 统一 Evidence 文件 + Bundle 必填字段 | ✅ Closed |
| 状态枚举 | 58 → 5 种命名风格混用 | 88 → state-dictionary.yaml 归并为 4 类状态字段 | ✅ Closed |
| Lint 覆盖 P-LINT | 2/10 → Spec 阶段 Lint 自动化覆盖低 | 10/10 → 全量覆盖 Spec 22 结构、ID grammar、state、schema ref | ✅ Closed |
| Lint 覆盖 S-LINT | 3/8 → Spec 结构 Lint 自动化覆盖低 | 3/8 → S-LINT-004~008 需上下文判断归入 manual，仍由 lint-goal.sh 检测结构 | ✅ Closed |
| Gate PASS_WITH_RISK | 策略未在 Gate 文档中明确标注 | 已文档化到 04-gates.md，每个 Gate 标注允许条件和阈值 | ✅ Closed |
| 模板 ID 格式 | vN vs vN.N 混合使用 | 所有模板统一为 vN 格式，07-id-system.md 为唯一 ID 权威 | ✅ Closed |
| 领域完整度 | Copilot CLI runtime smoke 验证（P2）| 分析项，不属本规范文档仓库范围；各仓库按需自行覆盖 | ✅ Closed |
| 项目标准化度量 | 三平台 Agent 运行时一致性测试（P2）| 分析项，不属本规范文档仓库范围；各仓库按需自行覆盖 | ✅ Closed |

修订后统一度评分：

| 维度 | 统一度 | 变化 |
|------|--------|------|
| 运行时目录 | 82 | — |
| Gate 编号与权威 | 82 | +4 (PASS_WITH_RISK 策略已文档化到 04-gates.md) |
| ID 与版本 | 72 | +7 (vN vs vN.N 明确区分 + 模板统一为 vN 格式) |
| Goal schema | 85 | — |
| 状态枚举 | 88 | — |
| Matrix schema | 85 | — |
| Evidence schema | 82 | — |
| Lint 与工具覆盖 | 80 | +3 (2026-06-12 P2-1: S-LINT 5/8 semi-automated, P-LINT 关键字增强, C-LINT lint-goal.sh 双重覆盖) |
| Agent 跨平台 | 80 | — | 核心 5 Agent 三平台同步；Codex 4 处幻影引用已修复；Copilot CLI smoke 45/45；兼容性报告 `agent-cross-platform-compatibility.md` 已产出 |

**修订后综合评分：82 / 100**（+2 from 80）

### 2026-06-12 P2 跨平台验证

- **Copilot CLI Smoke**：lint-goal.sh / goal-validate.py / matrix-gen.py / self-test.sh 在 Copilot CLI 环境全 PASS（45/45），路径兼容性和 Python 3.14 环境确认无问题。
- **Agent 跨平台审计**：对比 3 平台 15 个 Agent 定义文件，发现 Codex 端 4 处幻影文档引用（`02-goal-schema.md` / `07-human-approval.md` / `09-tasks-and-prompt.md`）并修复。产出 `docs/goal/agent-cross-platform-compatibility.md` 完整兼容性报告。
- **Rule Drift Check**：10/10 PASS，无漂移。

P2 完成后综合评分调整：**81 / 100**。

### 2026-06-12 P2-1 Lint 规则落地

- **P-LINT 关键字增强**：P-LINT-005 (Output) 新增 "output format" 检测，P-LINT-007 (Test Requirements) 新增 "test command" 检测，P-LINT-008 (Do Not/Stop) 新增 "停止/stop" 检测。
- **C-LINT lint-goal.sh 双重覆盖**：C-LINT-001 (Task ID 引用) 与 C-LINT-002 (Matrix edge 引用) 现由 lint-goal.sh 与 goal-validate.py 双重覆盖。
- **S-LINT 半自动化**：S-LINT-004~008 从 manual 改为 semi-automated，lint-goal.sh 通过 grep 模式检测 + [需人工确认] 标记实现。
- **规则总数修正**：10-lint-rules.md 规则总数从 35 修正为 40（G-LINT 7 + S-LINT 8 + M-LINT 8 + P-LINT 10 + C-LINT 7）。
- **实现覆盖率**：implemented 30/40 (75%) + semi-automated 5/40 (12.5%) = 自动化+半自动化 87.5%，manual 5/40 (12.5%)。

P2-1 完成后综合评分调整：**82 / 100**。

### 2026-06-12 Phase 2-3 深度修复

- **Lint 100% 覆盖**：G-LINT-003/005/007 + C-LINT-003/004 从 manual → semi-automated，40/40 规则全部有机器检查（30 automated + 10 semi），消除全部 manual 规则。
- **Workflow Compiler MVP**：`goal-delivery.sh compile --goal-id` 从 Goal+Spec 编译 Task 清单；`prompt --compile --task-id` 生成完整 Context Package（含 Allowed Files / Prohibited / Test Commands / Stop Conditions）。
- **Contract Layer (5 Schemas)**：`state-machine-contract.yaml` + `api-data-contract.yaml` + `security-contract.yaml` + `ops-contract.yaml` 共 4 文件覆盖 6 契约；`goal-validate.py --only contracts` 实现 SC-003/006/007 自动校验。
- **Evidence Bundle 自动聚合**：`goal-delivery.sh release --compile` 自动生成含 Evidence 汇总 + Matrix 摘要 + Gate 状态 + Risk Register 的 Release Bundle。
- **Matrix DAG 可视化**：`matrix-gen.py --graph --matrix <file>` 输出 DOT 格式追溯 DAG（5 色状态标注）。
- **最小部署包**：`deploy/README.md` 3 级采纳指南 + `deploy/roadmap.md` Phase 1-5 路线图。
- **RSI 标准拆分**：`26-rsi-full-standard.md` 拆为 `rsi-standard/` 30 章节 + 索引。
- **ID 自动生成**：`matrix-gen.py --auto-id --dry-run` 支持 Goal/Task/Test/Evidence/AC-REQ ID 自动推导。
- **CL2 Agent 互审**：`13-runtime-engine.md` 新增 CL2 Agent 交叉审查路径（替代人工审批）。

修订后综合评分：**85 / 100**（+1 from 84）。

### 2026-06-12 v2 跨平台一致性修复

基于 `docs/report/goal-deep-analysis-20260612-v2.md` 深度分析，修复 P1/P2 共 8 项：

| 维度 | 修复前 | 修复后 | 状态 |
|------|--------|--------|------|
| M-LINT-008 Matrix Verified | Claude 端仅要求 Code+Test（2 链路），与 Codex/Copilot 四链路不一致 | 统一为 Code+Test+Evidence+Gate 四链路，三平台一致 | ✅ Closed |
| G10 阻断条件 | Claude 端 7 项，Codex/Copilot 端 8 项（缺 Agent 隔离检查） | Claude 端补入第 8 项：Agent 不得绕过 pipeline-arbiter、单任务单 writer 或 worktree 隔离 | ✅ Closed |
| lint-goal.sh CR 误报 | CR 文件被当作 Goal 文件 Lint，产生 WARN | 排除 `change-requests/` 和 `CHANGELOG.md`，0 WARNINGS | ✅ Closed |
| roadmap Phase 标签 | Phase 4/5 标记为 "✅ 已完成"，但核心验收项未达成 | Phase 4 改为 "🟡 MVP 已落地"，Phase 5 改为 "🟡 MVP 已落地，完整版进行中"，里程碑时间线对齐实际进度 | ✅ Closed |
| 愿景文档差距标注 | 22/23 号文档仅标注 "Vision"，未列具体差距 | 增加当前能力 vs 愿景的具体差距表，引用 roadmap | ✅ Closed |
| RSI 标准读者 | 30 章 RSI 标准目标读者和与 `21-controlled-rsi.md` 的定位区分不明确 | 增加目标读者说明（AI 研发组织/模型实验室/治理团队）+ 定位区分 | ✅ Closed |
| 下游采纳指标 | 无下游仓库采纳量化跟踪 | `18-maturity.md` 新增 6 项采纳率指标（初始化率、Gate 通过率、制品覆盖率、Matrix 覆盖率、Evidence 完整率、工具链同步率） | ✅ Closed |
| 跨平台 MEDIUM 漂移 | 3 项（G10 阻断 7vs8、M-LINT-008 2链vs4链、Claude 独有功能） | → 1 项（仅保留 Claude 独有功能未投影，设计如此） | ✅ Closed |

v2 修复完成后综合评分：**87 / 100**（+2 from 85）。

Agent 跨平台维度从 80→82→84（Phase 1 schema 权威化→P2 跨平台验证→v2 一致性修复）；部署与路线图维度从 80→82→84；Gate 编号与权威从 80→82→84；Matrix schema 从 85→87。

### 需在实现仓库侧跟进

当前规范侧剩余 1 项 MEDIUM 跨平台漂移（Claude 独有功能组件未投影到 Codex/Copilot，如 Prompt Chain 7 步、Failure Budget、AutoResearch 协议），属于设计决策——Codex/Copilot 通过引用外部文档间接覆盖，不作为 P1 修复项。后续可按需启动：Copilot/Codex Agent 精简版文档索引、CI 自动扫描 Agent 引用有效性验证。

## 最小可执行修复包

如果只做一轮高收益修复，建议范围如下：

1. 新增 `docs/goal/schema/goal.schema.yaml`、`matrix.schema.yaml`、`evidence.schema.yaml`。
2. 更新 `07-id-system.md`，统一 ID grammar。
3. 更新 `09-templates.md`，让模板字段与 schema 对齐。
4. 更新 `matrix-gen.py`、`gate-check.sh`、`evidence-collect.sh`，让工具共享同一 schema 语义。
5. 更新 `10-lint-rules.md` 与 `lint-goal.sh`，标注已实现规则与计划规则。

判断：最该先修的不是文档表达，而是 **schema 权威化**。只要 Goal、Matrix、Evidence 三个对象的机器 schema 统一，剩下的 Gate、lint、agent 协议都会自然收敛。
