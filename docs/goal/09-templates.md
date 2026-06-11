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
DESIGN-<domain>-v1

### Source Goal
GOAL-YYYYMMDD-NNN

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

### Source Design
DESIGN-<domain>-v1

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

## 6. Matrix（横切追溯 edge）

Matrix 是横切追溯制品，不是主流程阶段。进入 `.config/goal/matrix/`、Gate、validator、CI 或 Release 控制面的 Matrix MUST 使用 canonical edge model；旧宽表只能作为展示或导入视图，进入控制面前必须转换为 canonical edge。

| edge_id | source_type | source_id | relation | target_type | target_id | status | evidence_id | updated_at |
|---|---|---|---|---|---|---|---|---|---|---|
| EDGE-GOAL-YYYYMMDD-NNN-AC01-TEST01 | AcceptanceCriteria | AC-REQ-SPEC-<domain>-v1-001-001 | verified_by | Test | TEST-TASK-GOAL-YYYYMMDD-NNN-NNN-NNN | Unmapped | EVID-GOAL-YYYYMMDD-NNN-TEST-001 | YYYY-MM-DD |

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
# 字段来源：canonical goal object schema (docs/goal/schema/goal.schema.yaml)
# 使用字段映射：template → canonical
#   goal_id → goal_id, title → title, objective → north_star, success_metrics → success_criteria
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
# 字段来源：canonical matrix edge schema (docs/goal/schema/matrix.schema.yaml)
# 使用 canonical edge model，relation 限于 8 个控制面值
matrix:
  - edge_id: EDGE-GOAL-20260608-002-001
    source_id: GOAL-20260608-002
    source_type: Goal
    target_id: SPEC-export-v1
    target_type: Spec
    relation: decomposes_to
    status: Linked
    evidence_id: EVID-GOAL-20260608-002-001
    risk_id: ~
    drop_reason: ~
    updated_at: 2026-06-08T00:00:00Z
  - edge_id: EDGE-GOAL-20260608-002-002
    source_id: AC-REQ-SPEC-export-v1-001-001
    source_type: AcceptanceCriteria
    target_id: TEST-TASK-GOAL-20260608-002-001-001
    target_type: Test
    relation: verified_by
    status: Verified
    evidence_id: EVID-GOAL-20260608-002-TEST-001
    risk_id: ~
    drop_reason: ~
    updated_at: 2026-06-08T00:00:00Z
```

旧 row 字段（例如 `goalId`、`specId`、`taskId`、`code_module`、`test_case`）MUST NOT 直接写入 Matrix 控制面。需要导入旧表格时，先转换为上面的 canonical edge，并记录转换命令或人工复核证据。

### Design YAML

```yaml
# 字段来源：canonical design object schema (docs/goal/schema/design.schema.yaml)
id: DESIGN-export-v1
name: Order Export Design
source:
  goal: GOAL-20260608-002
  spec: SPEC-export-v1
modules:
  - ExportController
  - CsvExportService
  - OrderRepository
interfaces:
  - exportOrders() -> ExportTask
  - generateOrderCsv() -> CsvFile
  - findByFilterPaged() -> List<Order>
data_flow: >
  HTTP Request → ExportController → CsvExportService → OrderRepository → DB
dependencies: []
adrs: [DEC-20260608-001]
risks:
  - Large datasets may cause memory pressure
  - CSV format changes may break downstream consumers
```

### Plan YAML

```yaml
# 字段来源：canonical plan object schema (docs/goal/schema/plan.schema.yaml)
id: PLAN-GOAL-20260608-002-v1
name: Order CSV Export Plan
source:
  goal: GOAL-20260608-002
  design: DESIGN-export-v1
execution_strategy: >
  Phase 1: core service and repository; Phase 2: API layer + validation;
  Phase 3: test and acceptance.
phases:
  - phase: 1
    tasks: [TASK-GOAL-20260608-002-001]
    goal: OrderRepository.findByFilterPaged() implemented
    validation: task test suite passes
  - phase: 2
    tasks: [TASK-GOAL-20260608-002-002, TASK-GOAL-20260608-002-003]
    goal: API and CSV generation working end-to-end
    validation: integration test suite passes
  - phase: 3
    tasks: [TASK-GOAL-20260608-002-004]
    goal: Full acceptance criteria verified
    validation: all AC tests pass
risks:
  - Performance risk with >100,000 rows
checkpoints:
  - After Phase 1: verify query performance
  - After Phase 2: verify end-to-end flow
  - After Phase 3: verify all ACs
rollback_plan: >
  Revert to manual report workflow. Feature flag allows disabling export.
final_validation: >
  All ACs Verified in Matrix. Release Gate passed.
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
matrix:
  - edge_id: EDGE-GOAL-20260608-002-004
    source_type: AcceptanceCriteria
    source_id: AC-REQ-SPEC-export-v1-003-001
    relation: verified_by
    target_type: Test
    target_id: TEST-TASK-GOAL-20260608-002-003-001
    status: Verified
    evidence_id: EVID-GOAL-20260608-002-TEST-001
    updated_at: 2026-06-08T00:00:00Z
priority: P0
```

### Evidence YAML

```yaml
# 字段来源：canonical evidence schema (docs/goal/schema/evidence.schema.yaml)
# 必填字段：evidence_id, test_id, task_id, goal_id, spec_id, acceptance_criteria_id, date, status, files_changed, commands_run
evidence_id: EVID-GOAL-20260608-002-TEST-001
test_id: TEST-TASK-GOAL-20260608-002-001-001
task_id: TASK-GOAL-20260608-002-001
goal_id: GOAL-20260608-002
spec_id: SPEC-export-v1
acceptance_criteria_id: AC-REQ-SPEC-export-v1-001-001
date: 2026-06-12T00:00:00Z
status: Passed
files_changed:
  - src/export/csv_generator.go
  - src/export/export_handler.go
commands_run:
  - go test ./tests/export/ -run TestCsvExport
evidence_notes: >
  All CSV export test cases passed. File size and row count verified.
matrix:
  - edge_id: EDGE-GOAL-20260608-002-002
    source_type: AcceptanceCriteria
    source_id: AC-REQ-SPEC-export-v1-001-001
    relation: verified_by
    target_type: Test
    target_id: TEST-TASK-GOAL-20260608-002-001-001
    status: Verified
    evidence_id: EVID-GOAL-20260608-002-TEST-001
    updated_at: 2026-06-08T00:00:00Z
```

---

## 4. JSON 化结构

```json
{
  "goal": {
    "id": "GOAL-20260608-002",
    "name": "Order CSV Export",
    "objective": "Provide CSV export capability for order reports.",
    "success_metrics": [{"metric": "report_preparation_time", "target": "<= 5 minutes"}],
    "scope": {"in": ["CSV export", "permission check"], "out": ["Excel export"]}
  },
  "specs": [{"id": "SPEC-export-v1", "goal_id": "GOAL-20260608-002", "requirements": [{"id": "REQ-SPEC-export-v1-001", "description": "User can create an export task."}]}],
  "matrix": {
    "edge": [
      {
        "edge_id": "EDGE-GOAL-20260608-002-001",
      "source_id": "GOAL-20260608-002",
      "source_type": "Goal",
      "target_id": "SPEC-export-v1",
      "target_type": "Spec",
      "relation": "decomposes_to",
      "status": "Linked",
      "evidence_id": "EVID-GOAL-20260608-002-001",
      "updated_at": "2026-06-08T00:00:00Z"
    },
    {
      "edge_id": "EDGE-GOAL-20260608-002-002",
      "source_id": "AC-REQ-SPEC-export-v1-001-001",
      "source_type": "AcceptanceCriteria",
      "target_id": "TEST-TASK-GOAL-20260608-002-001-001",
      "target_type": "Test",
      "relation": "verified_by",
      "status": "Verified",
      "evidence_id": "EVID-GOAL-20260608-002-TEST-001",
      "updated_at": "2026-06-08T00:00:00Z"
      }
    ]
  }
}
```

---

## 5. 仓库目录结构

```text
project/
  docs/
    goals/       GOAL-20260608-002-order-export-goal.md
    module/       SPEC-export-v1-order-export-spec.md
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
