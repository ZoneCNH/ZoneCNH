# 测试策略

> 从 Spec 生成测试，而不是让 AI 猜。

最后更新：2026-06-08

---

## 核心原则

测试不应该靠 AI 自己猜。测试应该从以下来源生成：

```text
Functional Requirements
Acceptance Criteria
Test Cases
Edge Cases
```text

---

## 从 Spec 生成测试计划

### Prompt

```markdown
请根据 SPEC.md 生成测试计划。

要求：
- 每个 Functional Requirement 至少有一个测试
- 每个 Acceptance Criteria 至少有一个验证方式
- 使用 Given / When / Then
- 区分 unit / component / integration / e2e
- 标出 P0 / P1 / P2 优先级
- 不写代码
```text

### 输出示例

```markdown
| Test ID | Type | Covers | Priority | Scenario |
|---|---|---|---|---|
| TC-001 | Unit | FR-001, AC-001 | P0 | Create valid task |
| TC-002 | Unit | FR-002, BR-001 | P0 | Reject empty title |
| TC-003 | Unit | FR-003, AC-003 | P0 | Toggle complete |
| TC-004 | Unit | FR-004, AC-004 | P0 | Edit task |
| TC-005 | Unit | FR-005, AC-005 | P0 | Delete task |
| TC-006 | E2E | MVP flow | P1 | Full task CRUD flow |
```text

---

## 测试优先级

不是所有测试都一样重要。

### 优先级定义

| 优先级   | 含义              | 何时写   |
| -------- | ----------------- | -------- |
| P0       | 核心业务路径      | 第一批   |
| P1       | 常见边界情况      | 第二批   |
| P2       | 低概率边界        | 第三批   |
| P3       | 视觉细节或 future | 最后     |

### 示例

```text
P0:
- 创建任务
- 空标题不能创建
- 完成任务
- 删除任务

P1:
- 超长标题
- 只有空格
- 编辑后取消
- 刷新后数据保留

P2:
- 连续快速点击
- localStorage 不可用
- 500 条任务性能
```text

**先覆盖 P0，再覆盖 P1。**

---

## 测试类型

| 类型        | 覆盖范围      | 速度   | 成本   |
| ----------- | ------------- | ------ | ------ |
| Unit        | 单个函数/组件 | 快     | 低     |
| Component   | 组件交互      | 中     | 中     |
| Integration | 模块间交互    | 慢     | 高     |
| E2E         | 用户完整流程  | 最慢   | 最高   |

### 推荐比例

```text
Unit:       70%
Component:  20%
Integration: 8%
E2E:         2%
```text

---

## 测试格式

### Unit Test

```markdown
### TC-001: Create valid task

**Given** 用户在任务输入框中输入 "Buy groceries"
**When** 用户点击 Add Task
**Then** 新任务出现在列表中，completed = false

**Covers:** FR-001, AC-001
**Priority:** P0
```text

### Edge Case Test

```markdown
### TC-007: Reject whitespace-only title

**Given** 用户在任务输入框中输入 "   "
**When** 用户点击 Add Task
**Then** 显示错误提示，任务不被创建

**Covers:** FR-002, BR-001
**Priority:** P1
```text

---

## Task 验收测试

每个 Task 完成后，用这个模板验收：

```markdown
# TASK-{NNN} Acceptance Report

## Requirement Coverage

| Requirement | Status | Evidence |
|---|---|---|
| FR-001 | Pass | {证据} |
| FR-002 | Pass | {证据} |

## Tests

| Test | Status |
|---|---|
| Unit tests | Pass |
| Component tests | Pass |
| Typecheck | Pass |
| Lint | Pass |
| Build | Pass |

## Manual QA

- [ ] {手动验证项 1}
- [ ] {手动验证项 2}

## Out-of-scope Check

- [ ] Did not implement {排除项 1}
- [ ] Did not implement {排除项 2}

## Result

Pass / Fail
```text

---

## Feature 验收

当一个模块的所有 Task 都完成后，做完整验收。

### Prompt

```markdown
请根据 SPEC.md 对当前功能做完整 Feature Acceptance Review。

检查：
1. 所有 Requirements 是否实现
2. 所有 Acceptance Criteria 是否满足
3. 所有 Test Cases 是否覆盖
4. Edge Cases 是否处理
5. Security 要求是否满足
6. 是否存在 Spec 外功能
7. 是否可以把 Spec 状态改为 Implemented

输出：
- Overall result: Pass / Fail
- Requirement coverage table
- Acceptance criteria table
- Test coverage table
- Missing items
- Required fixes
- Recommended status
```text

---

## 回归清单

功能越做越多，越需要回归清单。

```markdown
# Regression Checklist

## {Feature Name}

- [ ] {核心功能 1}
- [ ] {核心功能 2}
- [ ] {边界情况 1}
- [ ] {边界情况 2}

## General

- [ ] App loads
- [ ] No blank screen
- [ ] No critical console errors
```text

每次大改前后都跑。

---

## 相关文档

| 文档                                      | 用途         |
| ----------------------------------------- | ------------ |
| `docs/governance/DEFINITION-OF-DONE.md`   | 完成验收条件 |
| `docs/governance/TRACEABILITY.md`         | 需求追踪矩阵 |
| `docs/governance/DEVELOPMENT-WORKFLOW.md` | 完整管线总览 |
