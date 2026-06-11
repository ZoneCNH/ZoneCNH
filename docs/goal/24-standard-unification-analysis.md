# Goal 标准统一深度分析

> 本报告用于记录 Goal 体系当前仍需统一的结构标准面。结论基于 `docs/goal/` 文档集与 `docs/goal/tools/` 工具脚本的只读审查。

## 结论

Goal 体系目前不是缺少标准，而是多个标准面并存：权威 ID、模板、Registry、工具、Gate 各自形成了半权威。

结构统一度评分：**66 / 100**
置信度：**Medium-High**

运行时路径已经基本收敛到 `.config/goal/`，但对象 schema、ID 与版本、状态枚举、Matrix、Evidence、Gate 语义还没有完全统一。

## 评分账本

| 维度            | 统一度 | 判断                                                                                                            |
| --------------- | ------ | --------------------------------------------------------------------------------------------------------------- |
| 运行时目录      | 82     | `.config/goal/` 已成为主要运行时目录，规格制品入口已收敛到 `module/`；仍需明确哪些 `.config/goal/` 子目录可提交 |
| Gate 编号与权威 | 78     | G0-G11 权威清晰，但 `PASS_WITH_RISK` 与状态流转关系仍需补齐                                                     |
| ID 与版本       | 60     | 整数版号与语义版本式示例混用，工具 regex 只接受部分格式                                                        |
| Goal schema     | 62     | 标准、模板、Registry 使用不同字段命名                                                                           |
| 状态枚举        | 58     | `status`、`current_phase`、`gate_result`、`metric_conclusion` 混杂                                              |
| Matrix schema   | 55     | 展示字段、YAML 模板、脚本字段、覆盖率口径不一致                                                                 |
| Evidence schema | 50     | ID、路径、必填字段、生成器、Gate 检查存在明显漂移                                                               |
| Lint 与工具覆盖 | 57     | 规则文档完整，但脚本只实现子集                                                                                  |

综合评分：**66 / 100**。

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

当前问题：

- `14-agent-protocols.md` 定义 Goal Architect、Goal Reviewer、Goal Executor、Goal Validator 等协作角色。
- 本地 Goal 角色配置主要集中在 Claude agent，Codex 与 Copilot 侧更偏 Spec Code Pipeline 代理。

统一目标：

- 明确 Goal agents 是概念角色，还是三平台都必须具备的运行配置。
- 如果是运行配置，需要为 Claude、Codex、Copilot 建立同构角色矩阵。
- 如果是概念角色，需要在文档中声明平台实现可裁剪。

## 建议统一顺序

1. 先定 `07-id-system.md` 为唯一 ID 权威，明确 ID suffix 与版本字段的关系。
2. 建立唯一 `GoalObject` schema，并同步 Goal 模板与 Registry。
3. 建立状态字典，拆分 lifecycle、runtime phase、gate result、metric conclusion。
4. 重写 Matrix 标准，统一机器字段、展示字段、状态枚举和覆盖率口径。
5. 修正 Evidence 标准，使生成器输出天然满足 Gate 检查。
6. 统一 Gate 阈值与 `PASS_WITH_RISK` 流转语义。
7. 明确 `.config/goal/`、`docs/goal/`、CI artifact 的边界。
8. 建立 rule registry，把 lint 文档规则和脚本实现绑定。
9. 决定 Goal agent 是否需要三平台同构。

## 2026-06-12 修复进展

以下 gap 已通过 Phase 1 schema 权威化关闭：

| 维度 | 修复前 | 修复后 | 状态 |
|------|--------|--------|------|
| Goal schema | 62 → 标准/模板/Registry 字段命名不一致 | 85 → goal.schema.yaml 定义了 canonical 字段 + 三源映射表 | ✅ Closed |
| Matrix schema | 55 → 展示字段/YAML/脚本字段不一致 | 85 → matrix.schema.yaml 统一 canonical edge 字段 + relation vocabulary | ✅ Closed |
| Evidence schema | 50 → ID/路径/必填字段漂移 | 82 → evidence.schema.yaml 统一 Evidence 文件 + Bundle 必填字段 | ✅ Closed |
| 状态枚举 | 58 → 5 种命名风格混用 | 88 → state-dictionary.yaml 归并为 4 类状态字段 | ✅ Closed |

修订后统一度评分：

| 维度 | 统一度 | 变化 |
|------|--------|------|
| 运行时目录 | 82 | — |
| Gate 编号与权威 | 78 | — |
| ID 与版本 | 65 | +5 (07-id-system.md 明确 vN vs version 字段) |
| Goal schema | 85 | +23 ⬆ |
| 状态枚举 | 88 | +30 ⬆ |
| Matrix schema | 85 | +30 ⬆ |
| Evidence schema | 82 | +32 ⬆ |
| Lint 与工具覆盖 | 65 | +8 (10-lint-rules.md 标注规则实现状态) |

**修订后综合评分：78 / 100**（+12）

### 仍需统一

- ID 版本格式：vN vs vN.N 在模板和操作文档中仍有混合使用（65/100 → 目标 85）
- Gate 结果与流转语义：PASS_WITH_RISK 与 advisory score / hard gate 的区分需要各 Gate 文档逐一标注
- Lint 实现覆盖率：46% (16/35)，Prompt Lint 和 Spec Lint 的自动化覆盖率较低
- 三平台 Agent 同构：Codex/Copilot 侧 Goal agent 的运行时 smoke 仍需验证

### 下一批修复建议

1. 将所有模板中的 ID 示例统一为 `vN` 格式
2. 为每个 Gate (G0-G11) 标注允许 PASS_WITH_RISK 的阈值和条件
3. 实现 S-LINT 和 P-LINT 的自动化检查脚本
4. 完成 Copilot CLI runtime smoke 验证

## 最小可执行修复包

如果只做一轮高收益修复，建议范围如下：

1. 新增 `docs/goal/schema/goal.schema.yaml`、`matrix.schema.yaml`、`evidence.schema.yaml`。
2. 更新 `07-id-system.md`，统一 ID grammar。
3. 更新 `09-templates.md`，让模板字段与 schema 对齐。
4. 更新 `matrix-gen.py`、`gate-check.sh`、`evidence-collect.sh`，让工具共享同一 schema 语义。
5. 更新 `10-lint-rules.md` 与 `lint-goal.sh`，标注已实现规则与计划规则。

判断：最该先修的不是文档表达，而是 **schema 权威化**。只要 Goal、Matrix、Evidence 三个对象的机器 schema 统一，剩下的 Gate、lint、agent 协议都会自然收敛。
