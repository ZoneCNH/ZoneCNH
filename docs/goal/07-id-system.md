# ID 系统

> 管线定义见 [03-pipeline.md#完整管线](03-pipeline.md#1-完整管线)。

本文档定义 Goal 驱动交付体系的 **ID 格式和规则**。

---

## 1. ID 格式

| 对象                | ID 格式                            | 示例                                         |
| ------------------- | ---------------------------------- | -------------------------------------------- |
| Goal                | `GOAL-YYYYMMDD-NNN`                | GOAL-20260608-001                            |
| Spec                | `SPEC-<domain>-vN`                 | SPEC-market-data-v1                          |
| Requirement         | `REQ-<spec-id>-NNN`                | REQ-SPEC-market-data-v1-001                  |
| Acceptance Criteria | `AC-<req-id>-NNN`                  | AC-REQ-SPEC-market-data-v1-001-001           |
| Design              | `DESIGN-<domain>-vN`               | DESIGN-market-data-v1                        |
| ADR                 | `ADR-YYYYMMDD-NNN`                 | ADR-20260608-001                             |
| Plan                | `PLAN-<goal-id>-vN`                | PLAN-GOAL-20260608-001-v1                    |
| Milestone           | `MILE-<plan-id>-NNN`               | MILE-PLAN-GOAL-20260608-001-v1-001           |
| Task                | `TASK-<goal-id>-NNN`               | TASK-GOAL-20260608-001-001                   |
| Prompt              | `PROMPT-<task-id>-NNN`             | PROMPT-TASK-GOAL-20260608-001-001-001        |
| Test                | `TEST-<task-id>-NNN`               | TEST-TASK-GOAL-20260608-001-001-001          |
| Evidence            | `EVID-<test-id>-NNN`               | EVID-TEST-TASK-GOAL-20260608-001-001-001-001 |
| Risk                | `RISK-<goal-id>-NNN`               | RISK-GOAL-20260608-001-001                   |
| Decision            | `DEC-YYYYMMDD-NNN`                 | DEC-20260608-001                             |
| Review              | `REV-<task-or-pr-id>-YYYYMMDD-NNN` | REV-TASK-GOAL-20260608-001-001-20260608-001  |
| Release             | `REL-YYYYMMDD-<domain>`            | REL-20260608-market-data                     |
| Retrospective       | `RETRO-YYYYMMDD-NNN`               | RETRO-20260608-001                           |
| Prompt Patch        | `PATCH-PROMPT-YYYYMMDD-NNN`        | PATCH-PROMPT-20260608-001                    |
| Harness Patch       | `PATCH-HARNESS-YYYYMMDD-NNN`       | PATCH-HARNESS-20260608-001                   |
| Rule Patch          | `PATCH-RULE-YYYYMMDD-NNN`          | PATCH-RULE-20260608-001                      |

## 2. ID 规则

```text
1. ID 一经发布不得复用
2. Deprecated 对象必须保留历史记录
3. Replaced 对象必须写 replaced_by
4. 所有 Evidence 必须绑定 Test ID
5. 所有 PR 必须绑定 Goal ID 和 Issue ID
6. 所有 Release 必须绑定 Release Manifest
```

## 3. 旧格式兼容

早期文档中的简写格式仍可识别，但新产物必须使用完整格式。

### 格式迁移对照

| 旧格式                | 新格式                 | 说明                                                          |
| --------------------- | ---------------------- | ------------------------------------------------------------- |
| 早期 Goal 简写        | `GOAL-YYYYMMDD-NNN`    | Goal ID，如 GOAL-20260608-001                                 |
| 早期 Spec 简写        | `SPEC-<domain>-vN`     | Spec ID，如 SPEC-market-data-v1                               |
| 早期 Task 简写        | `TASK-<goal-id>-NNN`   | Task ID，如 TASK-GOAL-20260608-001-001                        |
| 早期 Milestone 简写   | `MILE-<plan-id>-NNN`   | Milestone ID，如 MILE-PLAN-GOAL-20260608-001-v1-001           |
| 早期 Prompt 简写      | `PROMPT-<task-id>-NNN` | Prompt ID，如 PROMPT-TASK-GOAL-20260608-001-001-001           |
| 早期 Requirement 简写 | `REQ-<spec-id>-NNN`    | Requirement ID，如 REQ-SPEC-market-data-v1-001                |
| 早期 AC 简写          | `AC-<req-id>-NNN`      | Acceptance Criteria ID，如 AC-REQ-SPEC-market-data-v1-001-001 |
| 早期 Test 简写        | `TEST-<task-id>-NNN`   | Test ID，如 TEST-TASK-GOAL-20260608-001-001-001               |
| `P-TASK-`             | `PROMPT-TASK-`         | Prompt ID 前缀                                                |

### 迁移规则

1. 旧格式 ID 在历史文档中保留原文，不回溯修改
2. 新产物（Goal、Spec、Task 等）必须使用新格式
3. 引用历史产物时，可在新格式后标注旧 ID，例如在备注字段写明历史来源
4. 工具链应同时支持新旧格式的解析，但输出统一使用新格式
5. `XLIB-*` 只作为 grandfathered/import namespace，用于导入历史 xlib 资料或解析既有引用
6. 校验器可以解析 legacy ID 以完成历史追溯，但生成器和新文档必须输出 canonical Goal ID
7. 导入的历史记录必须标注 `id_format: legacy` 或等价字段，避免被误判为新规范产物
8. legacy ID 不能作为新 artifact 的主键、文件名或 Registry 新条目 ID

## 4. ID 版本 vs 制品版本

### 区分原则

ID 中的版本后缀与文档级语义版本是两个独立概念：

| 维度     | ID 版本后缀                | 制品版本字段                           |
| -------- | -------------------------- | -------------------------------------- |
| 位置     | ID 字符串末尾              | 文档或 Registry 的 `version` 字段      |
| 格式     | `vN`（整数递增）           | `vN.N.N`（语义版本）                   |
| 示例     | `SPEC-market-data-v2`      | `version: "v2.1.0"`                    |
| 语义     | 标识第几次重写/替换        | 标识当前版本的兼容性                   |
| 递增规则 | 每次 Supersede 或重写时 +1 | 每次语义变更/新增/修复时按 semver 递增 |

### 版本冲突消解

- ID 后缀 `vN` 只表示"这是该对象的第 N 版"，不传达兼容性信息。
- 需要表达兼容性（breaking/minor/patch）时，使用 `version` 字段，格式 `vN.N.N`。
- `docs/goal/12-operations.md` 中的 `v0.1`、`v1.0` 等是制品 version 字段值，不是 ID 后缀。
- 工具链 regex 使用 `v\d+` 匹配 ID 后缀，与 `version` 字段的值格式无关。

### Schema 引用

- ID 格式的权威 schema 定义见 `.config/goal/schema/rules.yaml` 的 `ids` 段。
- 新增 ID 对象类型 MUST 先更新 `docs/goal/schema/` 中对应的对象 schema，再同步 rules.yaml、templates 和工具 regex。
