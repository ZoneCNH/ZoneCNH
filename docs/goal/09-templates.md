# 模板库

> **ID 格式说明**：本文档使用新格式 ID（如 GOAL-20260608-001、TASK-GOAL-20260608-001-001），详见 [07-id-system.md#id-格式](07-id-system.md#1-id-格式)。

## 1. 端到端模板

可以直接复制使用的完整模板：

```text
# Goal → Spec → Design → Plan → Tasks → Prompt → Code → Test Template

## 1. Goal

### Goal ID
GOAL-YYYYMMDD-NNN

### Goal Name
【目标名称】

### Context
【背景和问题】

### Objective
【目标结果】

### Target User
【目标用户】

### Success Metrics
- 【指标 1】
- 【指标 2】

### Scope
In Scope:
- 【包含内容】

Out of Scope:
- 【不包含内容】

### Acceptance Criteria
- 【验收标准 1】
- 【验收标准 2】

### Constraints
- 【约束 1】
- 【约束 2】

---

## 2. Spec

### Spec ID
SPEC-<domain>-v1

### Source Goal
GOAL-YYYYMMDD-NNN

### User Story
作为【角色】，我希望【能力】，以便【价值】。

### Functional Requirements
- REQ-SPEC-<domain>-v1-001:
- REQ-SPEC-<domain>-v1-002:

### Business Rules
- BR-001:
- BR-002:

### Edge Cases
- EC-001:
- EC-002:

### Error Handling
- EH-001:
- EH-002:

### Security Requirements
- SEC-001:
- SEC-002:

### Performance Requirements
- PERF-001:
- PERF-002:

### Acceptance Criteria
- AC-REQ-SPEC-<domain>-v1-001-001:
- AC-REQ-SPEC-<domain>-v1-002-001:

---

## 3. Design

### Design ID
DESIGN-<domain>-v1.0

### Source Spec
SPEC-<domain>-v1

### Modules
- 【模块 1】
- 【模块 2】

### Interfaces
- 【接口 1】
- 【接口 2】

### Data Flow / Dependencies / ADR / Risks

---

## 4. Plan

### Plan ID
PLAN-GOAL-YYYYMMDD-NNN-v1

### Source Goal
GOAL-YYYYMMDD-NNN

### Execution Strategy / Phases / Risks / Rollback / Final Validation

---

## 5. Tasks

### Task ID
TASK-GOAL-YYYYMMDD-NNN-NNN

### Task Name
【任务名称】

### Source
Goal: GOAL-YYYYMMDD-NNN / Spec: SPEC-<domain>-v1 / Plan: PLAN-GOAL-YYYYMMDD-NNN-v1

### Objective
【任务目标】

### Input / Output / Acceptance Criteria / Dependencies / Test Requirement

---

## 6. Matrix（横切追溯表）

| Goal ID | Spec ID | Requirement | Acceptance Criteria | Task ID | Prompt ID | Code Module | Test Case | Status |
|---|---|---|---|---|---|---|---|---|
| GOAL-YYYYMMDD-NNN | SPEC-<domain>-v1 | REQ-SPEC-<domain>-v1-001 | AC-REQ-SPEC-<domain>-v1-001-001 | TASK-GOAL-YYYYMMDD-NNN-NNN | PROMPT-TASK-GOAL-YYYYMMDD-NNN-NNN-NNN |  | TEST-TASK-GOAL-YYYYMMDD-NNN-NNN-NNN | Unmapped |

---

## 7. Prompt

### Prompt ID / Role / Source / Context / Objective / Requirements / Constraints / Output / Acceptance Criteria / Test Requirements / Do Not

---

## 8. Code Delivery

### Code Module / Source / Changes / Tests / Validation Result / Matrix Update

---

## 9. Test Evidence

### Test Cases / Commands / Results / Evidence ID / Matrix Update
```

---

## 2. PR 描述模板

```text
## Summary
实现邮箱验证码登录能力。

## Source
Goal: GOAL-20260608-001 新增邮箱验证码登录能力
Spec: SPEC-auth-v1 邮箱验证码登录
Tasks: TASK-GOAL-20260608-001-001, TASK-GOAL-20260608-001-002, TASK-GOAL-20260608-001-003, TASK-GOAL-20260608-001-004

## Changes
- 新增 AuthCodeService
- 新增 AuthCodeStore
- 新增邮箱验证码发送接口
- 新增邮箱验证码登录接口
- 新增发送频率限制
- 新增验证码过期、使用、错误次数处理
- 新增单元测试和集成测试

## Tests
- test_send_code_success
- test_send_code_rate_limit
- test_verify_code_success
- test_verify_code_expired
- test_verify_code_reuse_failed
- test_verify_code_max_attempts

## Acceptance Criteria
- 已注册用户可以请求邮箱验证码
- 正确验证码可以完成登录
- 验证码过期后不可使用
- 验证码成功使用后不可重复使用
- 超过频率限制后无法继续发送
- 日志中不记录明文验证码

## Risks
- 邮件服务不可用会影响验证码发送
- 频率限制配置过严可能影响正常用户

## Rollback
- 关闭 email_code_login feature flag
- 保留原密码登录路径
```

---

## 3. YAML 化结构

### Goal YAML

```yaml
id: GOAL-20260608-002
name: Order CSV Export
context: >
  Operations users currently spend around 30 minutes per day manually preparing order reports.
objective: >
  Provide CSV export capability for order reports and reduce daily report preparation time to under 5 minutes.
target_users:
  - operations_user
success_metrics:
  - metric: report_preparation_time
    from: 30 minutes
    to: <= 5 minutes
  - metric: max_export_rows
    target: <= 100000
scope:
  in: [order CSV export, export permission check, audit log]
  out: [Excel export, scheduled report email, dashboard visualization]
constraints:
  - existing order list page must remain unchanged
  - only users with order_export permission can export
acceptance_criteria:
  - id: AC-REQ-SPEC-export-v1-001-001
    description: authorized users can export CSV
  - id: AC-REQ-SPEC-export-v1-001-002
    description: unauthorized users cannot export CSV
```

### Matrix YAML

```yaml
matrix:
  - goal: GOAL-20260608-002
    spec: SPEC-export-v1
    requirement: REQ-SPEC-export-v1-001
    acceptance_criteria: AC-REQ-SPEC-export-v1-001-001
    task: TASK-GOAL-20260608-002-001
    prompt: PROMPT-TASK-GOAL-20260608-002-001-001
    code_module: ExportController.createExportTask
    test_case: TEST-TASK-GOAL-20260608-002-001-001
    status: Unmapped
```

### Task YAML

```yaml
id: TASK-GOAL-20260608-002-003
name: Generate Order CSV
source:
  goal: GOAL-20260608-002
  spec: SPEC-export-v1
objective: Generate CSV file for order export tasks.
inputs: [exportTaskId]
outputs: [csvFile, downloadUrl]
dependencies: [TASK-GOAL-20260608-002-001, TASK-GOAL-20260608-002-002]
acceptance_criteria:
  - CSV file contains correct headers
  - CSV file contains filtered orders
  - empty result exports headers only
tests: [TEST-TASK-GOAL-20260608-002-003-001, TEST-TASK-GOAL-20260608-002-003-002]
priority: P0
```

---

## 4. JSON 化结构

```json
{
  "goal": {
    "id": "GOAL-20260608-002",
    "name": "Order CSV Export",
    "objective": "Provide CSV export capability for order reports.",
    "successMetrics": [{"metric": "report_preparation_time", "target": "<= 5 minutes"}],
    "scope": {"in": ["CSV export", "permission check"], "out": ["Excel export"]}
  },
  "specs": [{"id": "SPEC-export-v1", "goalId": "GOAL-20260608-002", "requirements": [{"id": "REQ-SPEC-export-v1-001", "description": "User can create an export task."}]}],
  "matrix": [{"goalId": "GOAL-20260608-002", "specId": "SPEC-export-v1", "taskId": "TASK-GOAL-20260608-002-001", "status": "Unmapped"}]
}
```

---

## 5. 仓库目录结构

```text
project/
  docs/
    goals/       GOAL-20260608-002-order-export-goal.md
    specs/       SPEC-export-v1-order-export-spec.md
    matrix/      matrix-export-traceability.md
    tasks/       TASK-GOAL-20260608-002-001-create-export-task.md, TASK-GOAL-20260608-002-002-...
    plans/       PLAN-GOAL-20260608-002-v1-order-export.md
    prompts/     PROMPT-TASK-GOAL-20260608-002-001-001-design-export-api.md
  src/modules/export/
  tests/export/
```

---

## 6. 文件命名标准

格式：`类型编号-简短英文描述.md`

```text
GOAL-20260608-002-order-export-goal.md
SPEC-export-v1-order-export-spec.md
matrix-export-traceability.md
TASK-GOAL-20260608-002-001-create-export-task.md
PLAN-GOAL-20260608-002-v1-order-export.md
PROMPT-TASK-GOAL-20260608-002-001-001-implement-export-task.md
```

不要：`需求文档.md`、`最终版.md`、`最终版2.md`、`新最终版.md`。
