# ID 系统

> 管线定义见 [03-pipeline.md](03-pipeline.md)。

本文档定义 Goal 驱动交付体系的 **ID 格式和规则**。

---

## 1. ID 格式

| 对象 | ID 格式 | 示例 |
|------|---------|------|
| Goal | `GOAL-YYYYMMDD-NNN` | GOAL-20260601-001 |
| Spec | `SPEC-<domain>-v<major>.<minor>` | SPEC-market-data-v1.0 |
| Requirement | `REQ-<spec-id>-NNN` | REQ-SPEC-market-data-v1.0-001 |
| Acceptance Criteria | `AC-<req-id>-NNN` | AC-REQ-market-data-001-001 |
| Design | `DESIGN-<domain>-v<major>.<minor>` | DESIGN-export-v1.0 |
| ADR | `ADR-YYYYMMDD-NNN` | ADR-20260601-001 |
| Plan | `PLAN-<goal-id>-v<major>.<minor>` | PLAN-GOAL-20260601-001-v1.0 |
| Milestone | `MILE-<plan-id>-NNN` | MILE-PLAN-GOAL-20260601-001-v1.0-001 |
| Task | `TASK-<goal-id>-NNN` | TASK-GOAL-20260601-001-001 |
| Test | `TEST-<task-id>-NNN` | TEST-TASK-GOAL-20260601-001-001-001 |
| Evidence | `EVID-<task-id>-YYYYMMDD-NNN` | EVID-TASK-GOAL-20260601-001-001-20260601-001 |
| Risk | `RISK-<goal-id>-NNN` | RISK-GOAL-20260601-001-001 |
| Decision | `DEC-YYYYMMDD-NNN` | DEC-20260601-001 |
| Review | `REV-<task-or-pr-id>-YYYYMMDD-NNN` | REV-PR-123-20260601-001 |
| Release | `REL-YYYYMMDD-<domain>` | REL-20260601-market-data |
| Retrospective | `RETRO-YYYYMMDD-NNN` | RETRO-20260601-001 |
| Prompt Patch | `PATCH-PROMPT-YYYYMMDD-NNN` | PATCH-PROMPT-20260601-001 |
| Harness Patch | `PATCH-HARNESS-YYYYMMDD-NNN` | PATCH-HARNESS-20260601-001 |
| Rule Patch | `PATCH-RULE-YYYYMMDD-NNN` | PATCH-RULE-20260601-001 |

## 2. ID 规则

```text
1. ID 一经发布不得复用
2. Deprecated 对象必须保留历史记录
3. Replaced 对象必须写 replaced_by
4. 所有 Evidence 必须绑定 Task ID
5. 所有 PR 必须绑定 Goal ID 和 Issue ID
6. 所有 Release 必须绑定 Release Manifest
```

## 3. 旧格式兼容

早期文档中的简写格式仍可识别，但新产物必须使用完整格式。

### 格式迁移对照

| 旧格式 | 新格式 | 说明 |
|--------|--------|------|
| `G-001` | `GOAL-YYYYMMDD-NNN` | Goal ID，如 GOAL-20260601-001 |
| `S-001` | `SPEC-<domain>-v<major>.<minor>` | Spec ID，如 SPEC-market-data-v1.0 |
| `T-001` | `TASK-<goal-id>-NNN` | Task ID，如 TASK-GOAL-20260601-001-001 |
| `M-001` | `MILE-<plan-id>-NNN` | Milestone ID，如 MILE-PLAN-GOAL-20260601-001-v1.0-001 |
| `P-001` | `PROMPT-<task-id>-NNN` | Prompt ID，如 PROMPT-TASK-GOAL-20260601-001-001-001 |
| `REQ-001` | `REQ-<spec-id>-NNN` | Requirement ID，如 REQ-SPEC-market-data-v1.0-001 |
| `AC-001` | `AC-<req-id>-NNN` | Acceptance Criteria ID，如 AC-REQ-market-data-001-001 |
| `TEST-001` | `TEST-<task-id>-NNN` | Test ID，如 TEST-TASK-GOAL-20260601-001-001-001 |
| `P-TASK-` | `PROMPT-TASK-` | Prompt ID 前缀 |

### 迁移规则

1. 旧格式 ID 在历史文档中保留原文，不回溯修改
2. 新产物（Goal、Spec、Task 等）必须使用新格式
3. 引用历史产物时，可在新格式后标注旧 ID，如 `TASK-GOAL-20260601-001-001（旧 T-003）`
4. 工具链应同时支持新旧格式的解析，但输出统一使用新格式
