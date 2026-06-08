# AI 协作

## 1. AI 编程控制点

使用 AI 写代码时，最容易出问题的是：**AI 生成了看似正确但没有满足真实需求的代码。**

### 生成前控制

```text
- 提供 Goal
- 提供 Spec
- 提供 Task
- 提供已有代码结构
- 提供约束
- 提供测试要求
```

### 生成中控制

```text
- 一次只让 AI 处理一个 Task
- 不让 AI 自行扩展范围
- 要求 AI 输出变更清单
- 要求 AI 说明对应 Matrix 行
```

### 生成后控制

```text
- 跑测试
- 对照 Matrix Review
- 检查安全要求
- 检查性能要求
- 检查是否改动无关模块
```

---

## 2. Context Package

使用 AI 编程时，不要只把 Task 发给 AI，应该给它一个 **Context Package**。

### 标准结构

```text
Context Package:
1. Goal 摘要
2. Spec 摘要
3. Matrix 行
4. 当前 Task
5. 相关代码结构
6. 相关接口约定
7. 数据模型
8. 约束条件
9. 测试要求
10. 禁止事项
```

### 示例

```text
Context Package: CP-004

Goal:
GOAL-20260601-001 订单 CSV 导出，目标是让运营用户在 5 分钟内完成日报整理。

Spec:
SPEC-order-export-v1.0 订单导出功能。

Matrix Rows:
- REQ-SPEC-order-export-v1.0-003: 生成 CSV 文件
- REQ-SPEC-order-export-v1.0-004: CSV 字段顺序正确
- REQ-SPEC-order-export-v1.0-005: 空数据时仍生成表头

Current Task:
TASK-GOAL-20260601-001-004 实现 CsvExportService.generateOrderCsv()

Existing Code:
- OrderRepository.findByFilterPaged()
- ExportTaskRepository.findById()
- ExportTaskRepository.updateStatus()
- FileStorageService.upload()

Constraints:
- 不得一次性加载全部订单到内存
- 不改变现有订单查询接口
- CSV 文件必须 UTF-8 编码
- 文件上传失败时任务状态为 failed

Tests Required:
- test_generate_csv_success
- test_generate_empty_csv_with_headers
- test_upload_failed_marks_task_failed
- test_csv_column_order

Do Not:
- 不实现 Excel 导出
- 不实现定时邮件发送
- 不修改权限系统
```

---

## 3. PromptOps

Prompt 参与代码生成时，应该像代码一样管理。

### Prompt 文件结构

```text
prompts/
  PROMPT-TASK-GOAL-20260601-001-001-001-design-export-api.md
  PROMPT-TASK-GOAL-20260601-001-002-001-implement-export-task.md
  PROMPT-TASK-GOAL-20260601-001-003-001-generate-tests.md
  PROMPT-TASK-GOAL-20260601-001-004-001-review-against-matrix.md
```

### Prompt 版本记录

```text
Prompt ID: PROMPT-TASK-GOAL-20260601-001-003-001
Version: v1.2

Change Log:
- v1.0: 初版，实现 CSV 生成服务
- v1.1: 增加不允许一次性加载全部数据
- v1.2: 增加文件上传失败处理
```

### Prompt 质量标准

> Prompt 质量标准（6 条）见 [05-layer-standards.md §5](05-layer-standards.md#5-prompt-标准)。

---

## 4. Prompt Chain

AI 编程不要用一个 Prompt 让它完成全部功能。推荐 Prompt Chain：

```text
PROMPT-...-001 Analyze    → 分析需求、风险、边界条件
PROMPT-...-002 Design     → 设计接口、模块、数据结构
PROMPT-...-003 Implement  → 实现一个具体 Task
PROMPT-...-004 Test       → 生成或补充测试
PROMPT-...-005 Review     → 对照 Matrix 检查覆盖
PROMPT-...-006 Fix        → 修复 Review 发现的问题
PROMPT-...-007 Summarize  → 输出 PR 描述和 Matrix 更新建议
```

### Prompt 分层

| Prompt 类型 | 作用 |
|-------------|------|
| Analysis Prompt | 分析需求和风险 |
| Design Prompt | 设计方案和接口 |
| Implementation Prompt | 生成代码 |
| Test Prompt | 生成测试 |
| Review Prompt | 检查代码是否满足 Matrix |

---

## 5. AI Prompt 总控模板

所有实现类 Prompt 的母模板：

```text
You are implementing a task in a traceable delivery workflow.

Source:
- Goal: {goal_id} {goal_name}
- Spec: {spec_id} {spec_name}
- Matrix Rows: {matrix_rows}
- Task: {task_id} {task_name}

Context:
{system_context}

Task Objective:
{task_objective}

Requirements:
{requirements}

Constraints:
{constraints}

Existing Code:
{existing_code_summary}

Expected Output:
{expected_output}

Acceptance Criteria:
{acceptance_criteria}

Tests Required:
{test_cases}

Do Not:
- Do not implement features outside the task scope.
- Do not change unrelated modules.
- Do not remove existing behavior unless explicitly required.
- Do not ignore acceptance criteria.
- Do not generate code without tests for critical logic.

After implementation, output:
1. Files changed
2. Requirement coverage
3. Tests added
4. Matrix rows satisfied
5. Known risks
```

---

## 6. Review Prompt 模板

代码生成后，用这个 Prompt 做检查：

```text
Please review the implementation against the traceability matrix.

Source:
Goal: {goal}
Spec: {spec}
Matrix: {matrix}

Code Changes:
{code_changes}

Tests:
{tests}

Check:
1. Which Matrix rows are fully covered?
2. Which Matrix rows are partially covered?
3. Which Matrix rows are missing?
4. Are there any orphan code changes?
5. Are there any acceptance criteria without tests?
6. Are there any security or performance risks?
7. Does the implementation exceed the defined scope?

Output format:
- Covered
- Partially Covered
- Missing
- Orphan Changes
- Risks
- Required Fixes
```

---

## 7. AI 输出验收协议

AI 生成代码后，要求它输出验收报告：

```text
Implementation Report:

1. Files Changed
- src/export/ExportController.ts
- src/export/ExportTaskService.ts

2. Matrix Coverage
- REQ-SPEC-order-export-v1.0-001: Covered
- REQ-SPEC-order-export-v1.0-002: Covered
- REQ-SPEC-order-export-v1.0-003: Partially Covered

3. Acceptance Criteria
- AC-REQ-SPEC-export-v1-001-001: Passed
- AC-REQ-SPEC-export-v1-002-001: Passed
- AC-REQ-SPEC-export-v1-003-001: Missing test

4. Tests Added
- test_create_export_task_success
- test_create_export_task_permission_denied

5. Risks
- 大数据量导出性能尚未验证

6. Out of Scope
- 未实现 Excel 导出
- 未实现定时邮件
```

---

## 8. Code Boundary

AI 写代码时最容易乱改，Prompt 里要明确 Code Boundary：

```text
Allowed to change:
- src/modules/export/*
- tests/export/*

Not allowed to change:
- src/modules/auth/*
- src/modules/payment/*
- database/user_schema.sql
- existing password login flow
```

更严格：

```text
You may only modify the following files:
- ExportTaskService.ts
- CsvExportService.ts
- csv-export.test.ts

You must not modify:
- UserService.ts
- AuthService.ts
- PaymentService.ts
```

---

## 9. Non-goals 贯穿所有层

Goal 里写：

```text
Non-goals:
- 不做 Excel 导出
- 不做定时邮件
- 不做报表可视化
```

Prompt 里也要写：

```text
Do Not:
- Do not implement Excel export.
- Do not implement scheduled email.
- Do not implement report dashboard.
```

Code Review 时也要检查：是否出现了 Excel 相关代码？是否新增了邮件调度逻辑？

---

## 10. Prompt → Code 执行循环

不要期望一次 Prompt 就生成最终代码。推荐循环：

```text
Prompt → Draft Code → Run Tests → Review Against Matrix → Fix → Run Tests Again → Update Matrix
```

标准循环：

```text
1. 使用 Implementation Prompt 生成第一版代码
2. 使用 Test Prompt 生成测试
3. 执行测试
4. 使用 Review Prompt 对照 Matrix 检查覆盖
5. 修复缺失逻辑
6. 再次执行测试
7. 更新 Matrix 状态
8. 写 PR 说明
```
