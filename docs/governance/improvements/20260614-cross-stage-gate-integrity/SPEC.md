# 改进规格: 跨阶段门禁完整性

- **日期**: 2026-06-14
- **来源**: natsx 全管线复盘 (tasks 阶段 44→99, 发现 matrix/plan 阶段 false gate pass)
- **影响文件**: `docs/governance/scoring/RUBRIC-matrix.md`, `docs/governance/scoring/RUBRIC-plan.md` (受保护, 需走 RSI)
- **状态**: 提议

---

## 1. 问题

natsx 全管线六阶段均 pass，但 tasks 阶段 16 轮纠错中发现了多个上游阶段门禁未拦截的缺陷：

| 缺陷 | 发生的阶段 | 阶段得分 | 根因 |
|------|-----------|----------|------|
| BR-004→TASK-010 文件不存在 | matrix | 100 | "Task 映射"只检查列是否填写，不检查文件存在性 |
| FR-006/007 在 Forward Coverage 和 Task Coverage 中分配不一致 | matrix | 100 | rubric 无跨表一致性检查 |
| BR-008/BR-009 未出现在 Forward Coverage | matrix | 100 | scorer 漏检 (rubric 有"FR 覆盖闭合"但未执行到位) |
| Plan 仅 6 个 task，但 TRACEABILITY 有 26 行需求 | plan | 100 | "与 Spec/Matrix 一致"维度太粗，未做逐行对比 |

这些缺陷在 false gate pass 后流入下游，导致 tasks 阶段花费大量轮次修复本应在 matrix/plan 阶段解决的问题。

数域说明：TRACEABILITY Forward Coverage 共 26 行（8 FR + 9 BR + 9 NFR），Task Coverage 表将其映射到 14 个 TASK ID（001-014，TASK-010 废弃 → 13 个实际 task）。旧 plan 仅覆盖 6 个 task（FR-001~008 + CI/docs），缺口为 7 个 task（NFR-006~009, NFR-001~005 及 SubjectBuilder/Envelope/Config/Observatory/Security/Performance/Layer）。

## 2. 改进建议

### 2.1 Matrix rubric: Task 映射 → 加入文件存在性验证

现有维度:

> Task 映射 (10 分): 每条 FR 已分配 Task 或显式标记未分配

建议增加子项:

> Task 存在性验证: 矩阵中引用的每个 TASK ID 在 `module/{module}/tasks/` 目录下有对应文件。不存在 → 扣分，不存在且超过 10% → 红线。

### 2.2 Matrix rubric: 新增跨表一致性检查

建议新增维度或子项:

> 跨表一致性: Forward Coverage 的 Task 分配与 Task Coverage 的 Requirement Coverage 双向一致。同一 FR/BR 在两表中的 Task 分配不同 → 扣分。

### 2.3 Plan rubric: "与 Spec/Matrix 一致" 拆分为可验证子项

现有维度 (15 分):

> 与 Spec/Matrix 一致: 不跳过 Task，不引入 Spec 外内容，不跨模块

建议拆分为:

| 子项 | 分值 | 检查方法 |
|------|------|----------|
| Task 数量对齐 | 5 | Plan 中的 Task 数量 >= TRACEABILITY Task Coverage 表中的唯一 Task 数量 |
| Task ID 一致性 | 5 | Plan 中引用的每个 TASK ID 在 tasks 目录下有对应文件，且 scope 描述与 TASK 文件一致 |
| 不引入 Spec 外内容 | 3 | Plan 中的 Task scope 不超出 SPEC.md 功能范围 |
| 不跨模块 | 2 | 所有 Task 文件 module 字段一致 |

## 3. 不做什么

- 不修改 matrix rubric 的满分结构 (保持 100 分制)
- 不要求 matrix scorer 读取 TASK 文件全文 (只检查文件名存在性即可)
- 不要求 plan scorer 评估任务质量 (只做数量/Task ID 对齐的结构性检查)

## 4. RSI 路径

本改进涉及 `docs/governance/scoring/RUBRIC-matrix.md` 和 `docs/governance/scoring/RUBRIC-plan.md` (受保护文件)。
修改需走 CONSTITUTION.md §14.3 流程: fork → A/B → outer-metric 评判 → 人类批准。

## 5. 证据

- natsx matrix verdict: gate=pass, composite=100 (后发现 BR-004→TASK-010 不存在)
- natsx plan verdict: gate=pass, composite=100 (后发现仅 6 task, TRACEABILITY 映射至 13 个实际 TASK + 1 个废弃 TASK-010)
- natsx tasks 阶段纠错记录: 16 轮, 44→99, 至少 3 个问题是上游阶段遗留

## 6. 决策记录

| 日期 | 决策 | 理由 |
|------|------|------|
| 2026-06-14 | 创建本改进规格 | natsx 全管线 false gate pass 复盘 |
