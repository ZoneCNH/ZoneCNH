# 改进规格: spec_ref 实质优先于形式

- **日期**: 2026-06-14
- **来源**: natsx tasks 阶段评分 (44→99, 8 轮迭代)
- **影响文件**: `docs/governance/scoring/RUBRIC-tasks.md` (受保护, 需走 RSI)
- **状态**: 提议

---

## 1. 问题

Rubric 红线规则 "任一 Task 无 spec_ref" 的字面含义是 "YAML frontmatter 中缺少 spec_ref 字段"。
但在实际评分中发现：task 的 Acceptance 章节已通过 `FR-001 verified via TC-001` 等形式声明了 FR 覆盖，
YAML acceptance_criteria 引用了 AC ID — 追溯链路实质存在，仅缺少一个名叫 `spec_ref` 的 YAML key。

这导致评分从 80+ 被红线压制到 40+，8 轮自我纠错才收敛至 99。
根本原因是 rubric 的触发条件过于形式化，未区分"追溯缺失"和"追溯信息在不同字段中"。

## 2. 改进建议

Rubric 红线规则建议从：

> 任一 Task 无 spec_ref

改为：

> 任一 Task 无法追溯到 Spec 的 FR/BR/AC — 即既不包含 spec_ref 字段，
> 也不在 acceptance_criteria、Acceptance 章节或其他可定位位置引用 FR/BR/AC ID

对应的 spec_ref 闭合维度也应从"每个 Task 显式引用 FR/BR ID"改为"每个 Task 的 FR/BR 覆盖可从任务文件定位验证"。

## 3. 不做什么

- 不删除 spec_ref 字段 (仍为推荐格式, 统一位置便于机器解析)
- 不修改 TASK-TEMPLATE.md 的 spec_ref 必填标记

## 4. RSI 路径

本改进涉及 `docs/governance/scoring/RUBRIC-tasks.md` (受保护文件) 和
`docs/governance/STRUCTURAL-SCORING.md` §5.2 红线定义的措辞。
修改需走 CONSTITUTION.md §14.3 流程: fork → A/B → outer-metric 评判 → 人类批准。

## 5. 决策记录

| 日期 | 决策 | 理由 |
|------|------|------|
| 2026-06-14 | 创建本改进规格 | natsx 评分 8 轮 spec_ref 争议, 根源在 rubric 形式化触发条件 |

## 变更日志

| 日期 | 变更内容 |
|------|----------|
| 2026-06-14 | 提议创建 |
| 2026-06-14 | 实施：RUBRIC-tasks.md 红线规则从"任一 Task 无 spec_ref"改为"任一 Task 无法追溯到 Spec — 即 task 文件中既无 spec_ref 字段，也不在 acceptance_criteria、Acceptance 章节或其他可定位位置引用 FR/BR/AC ID"；spec_ref 闭合维度描述同步更新 |
