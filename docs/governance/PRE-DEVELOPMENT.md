# 开发前准备

> **投影声明**（2026-07-03 P2.3）：各层 DoR/DoD 的 canonical SSOT 是 `docs/goal/06-dod.md`。本文件定义 Spec→Code 快速通道中 Spec→Code 的实操步骤（Matrix/Tasks/Plan/Prompt 一键生成），是 goal 管线 G4-G6 前置准备的快速通道实现。
>
> Spec 完成后、写代码前必须生成的 4 个产物。

最后更新：2026-07-03

---

## 概述

Spec 完成后，下一步不是代码，而是生成：

```text
1. Traceability Matrix     需求追踪表
2. Task Breakdown          任务拆分
3. Implementation Plan     实现顺序
4. TASK-001 Prompt         第一个开发提示词
```text

即：

```text
Spec → Matrix → Tasks → Plan → Prompt → Code
```text

**原则：先让 AI 生成这些，但不让它写代码。**

---

## 一键生成 Prompt

直接发给编码 AI：

```markdown
请根据当前已完成的 Spec，生成开发前准备材料。

要求：
1. 不要写代码
2. 生成 Requirement Traceability Matrix
3. 将 Spec 拆成可执行 Tasks
4. 给出推荐实现顺序
5. 标出每个 Task 的依赖关系
6. 标出每个 Task 的测试方式
7. 为第一个 Task 写出可直接执行的开发 Prompt

输出结构：
- Spec Readiness
- Traceability Matrix
- Task Breakdown
- Implementation Order
- Dependencies
- Testing Plan
- Recommended First Task
- TASK-001 Development Prompt
```text

---

## 实现策略：水平切 vs 垂直切

拆 Task 有两种方式，选择取决于项目阶段。

### 方式 A：水平切

按技术层拆：

```text
Data Model → Validation → Service → API → UI → Tests
```text

**适合：** 架构复杂、后端较多、数据模型重要、多人协作

**优点：** 结构清楚
**缺点：** 前几个 task 做完后，用户还看不到完整功能

### 方式 B：垂直切

按用户行为拆：

```text
Create Task (e2e) → View Tasks (e2e) → Toggle Complete (e2e) → ...
```text

**适合：** MVP、小产品、快速验证、个人项目

**优点：** 每个 task 都能跑通一个用户价值
**缺点：** 早期可能有重复，后面再重构

### 推荐做法

```text
先垂直切，再轻量重构
```text

即：

1. 先让一个核心流程完整跑通
2. 再整理架构
3. 再补边界
4. 再补测试
5. 再优化

**不要一开始就让 AI 搭一个过度复杂的架构。**

---

## 推荐实现顺序

大多数 App 的标准顺序：

```text
0. Project skeleton
1. Data model
2. Validation
3. Core service / storage
4. First happy path UI
5. Error states
6. Edge cases
7. Tests
8. Refactor
9. Accessibility
10. Docs
11. Build / Deploy
```text

**注意：** TASK-000 可以是骨架任务，不一定对应某个业务需求。

---

## Task 文件结构

每个 Task 独立成文件：

```text
module/{module}/tasks/
├── TASK-000-project-skeleton.md
├── TASK-001-data-model.md
├── TASK-002-create-flow.md
├── TASK-003-list-view.md
├── TASK-004-toggle-complete.md
├── TASK-005-edit.md
├── TASK-006-delete.md
├── TASK-007-persistence.md
├── TASK-008-error-empty-states.md
├── TASK-009-tests.md
└── TASK-010-release.md
```text

---

## Traceability Matrix 格式

```markdown
| Requirement | Description | Acceptance Criteria | Test Case | Task | Status |
|---|---|---|---|---|---|
| FR-001 | Create Task | AC-001 | TC-001 | TASK-002 | ⬜ |
| FR-002 | Reject Empty | AC-002 | TC-002 | TASK-002 | ⬜ |
| FR-003 | View List | AC-003 | TC-003 | TASK-003 | ⬜ |
```text

状态符号：

| 符号   | 含义   |
| ------ | ------ |
| ⬜      | 未开始 |
| 🔵      | 进行中 |
| ✅      | 已完成 |
| ❌      | 阻塞   |
| ⏭️     | 延后   |

校验规则：

- 每个 FR 必须有 ≥1 AC
- 每个 AC 必须有 ≥1 TC
- 每个 TC 必须映射回 ≥1 FR
- 不允许无需求支撑的 TC（范围蔓延）
- 不允许无测试覆盖的需求（盲区）

---

## 实现顺序与依赖

输出格式：

```markdown
## Implementation Order

| Order | Task | Depends On | Priority |
|---|---|---|---|
| 1 | TASK-000 | — | P0 |
| 2 | TASK-001 | 000 | P0 |
| 3 | TASK-002 | 001 | P0 |
| 4 | TASK-003 | 001 | P0 |
| 5 | TASK-004 | 003 | P0 |
| 6 | TASK-005 | 003 | P1 |
| 7 | TASK-006 | 003 | P1 |
| 8 | TASK-007 | 002 | P0 |
| 9 | TASK-008 | 003 | P1 |
| 10 | TASK-009 | ALL | P0 |
| 11 | TASK-010 | ALL | P0 |
```text

---

## 相关文档

| 文档                                         | 用途                                    |
| -------------------------------------------- | --------------------------------------- |
| `docs/governance/TASK-TEMPLATE.md`           | Task spec 模板                          |
| `docs/governance/TRACEABILITY.md`            | 追溯矩阵规范                            |
| `docs/governance/DEVELOPMENT-WORKFLOW.md`    | 完整管线总览（含 Agent 编排与门禁定义） |
| `docs/governance/CODING-SESSION-PROTOCOL.md` | 编码会话协议                            |

> 完整工作流定义见 `docs/governance/DEVELOPMENT-WORKFLOW.md`，其中包含每个阶段的 Agent 分配、进入/退出门禁、产物定义和状态管理。
