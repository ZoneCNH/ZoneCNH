# docs/goal/ 结构性修复完成报告

- 日期：2026-06-08
- 对应分析报告：`docs/report/goal-docs-structural-issues-score-20260608.md`
- 原结构评分：78/100
- 修复后估计评分：92/100

> 说明：本次是针对已识别结构漂移的修复收口，未重新执行四源结构评分门禁，因此不声明达到 98 分管线准入。

## 1. 执行方式

用户要求使用 agent teams 执行修复。由于 `omx team` 因当前工作区已有未提交变更而拒绝创建 worktree，本次改用 Codex native agent team 分三路执行，并由主线程集成验证：

- Worker A：修复状态机、Registry 与 Glossary 口径。
- Worker B：修复 Matrix 生命周期、DoR/DoD 分层、工具规则数量漂移。
- Worker C：修复 Gate/Profile 命名、运行时人工检查命名和主索引口径。

## 2. 已修复的结构性问题

### 2.1 Matrix 生命周期冲突

- 将 Matrix 明确为横切追溯制品，不再被描述为主流程阶段。
- 区分初始 Matrix DoR、执行期更新和 Gate DoD 验证。
- 修正 Matrix 初始化口径：初始阶段允许 `plan_id`、`task_id` 为空，后续由 Plan/Task 阶段补齐。
- 统一 Matrix status 语义：`Verified` 表示验证完成，`Dropped` 表示需求关闭，`Blocked/Changed` 表示异常处理态。

### 2.2 Pipeline 状态模型冲突

- 将状态模型统一为双轴：`pipeline_state` 表示 13 个主流程状态，`current_phase` 表示当前阶段，`phase_status` 表示阶段内状态。
- 修正 Registry 示例，避免 `current_phase: design_ready` 这类状态/阶段混用。
- 回滚语义不再“退回 DESIGN_READY/PLAN_READY 并记录 needs_replan”，改为保持当前 `pipeline_state` 并通过 `phase_status`、`blockers`、`gate_failures` 表达异常。
- 修正旧锚点 `03-pipeline.md#2-状态机`，统一指向 `03-pipeline.md#2-双轴状态机`。

### 2.3 Gate 命名空间漂移

- 将运行时人工检查从 `H-G*` 改为 `H-CHK*`，避免与规范 Gate `G0-G11` 形成第二套 Gate 命名空间。
- 明确 `H-CHK*` 是 G0-G11 的人工验证证据或检查点，不是独立 Gate。
- 将 “Human Approval Gate” 口径改为 “Human Approval Check”。

### 2.4 Profile 命名漂移

- 统一最小流程为 `MVA Profile`。
- 统一裁剪层级为 `Lite / Standard / Full Profile`。
- 修正主索引、Quickstart、Runtime、Risk/Maturity 文档中的 Lite/MVA 混用。

### 2.5 工具与 Glossary 漂移

- 工具规则数量统一为 50 条。
- Glossary 将 Pipeline State Machine 定义为 13 个正常主流程状态，异常通过 blocker/error/lifecycle 表示。
- Change Level 的 SSOT 指向拆分后的 runtime/risk 口径，降低重复定义风险。

### 2.6 Lint 规则误伤与 Changelog 追溯

- 收窄 Code Lint 对 PR/Commit/Changelog 文件的识别范围，要求文件名中的 `pr`、`commit`、`changelog` 等关键词以分隔符形成独立词。
- 避免 `agent-protocols.md`、`self-improving.md` 被错误识别为 PR/Commit 文档。
- 为 `CHANGELOG.md` 补充 Task、Matrix Row 与验证命令引用。

## 3. 验证结果

已执行以下验证：

```bash
rg -n "current_phase: design_ready|H-G[0-9]|03-pipeline\.md#2-状态机|03-pipeline\.md#状态机|38 条|12 种正常状态|状态卡在 BLOCKED|停在 BLOCKED 状态|全部关键项为 Done|Goal → Spec → Requirement → Task → Prompt → Code → Test → Acceptance Criteria|DESIGN_READY 并更新|PLAN_READY，并记录 needs_replan" docs/goal
git diff --check -- docs/goal docs/report
bash docs/goal/tools/lint-goal.sh docs/goal
```

验证结论：

- 关键残留口径扫描：无命中。
- Patch 格式检查：通过。
- Goal lint：`ERRORS=0`，`WARNINGS=0`。

剩余 warning：无。

## 4. 剩余风险

- 本轮未处理工作区中既有的无关删除和未提交变更。
- 本轮未执行完整 Markdown 渲染检查。
- 本轮未执行四源结构评分门禁，92/100 是基于目标漂移修复后的保守估计，不是最终准入分。
