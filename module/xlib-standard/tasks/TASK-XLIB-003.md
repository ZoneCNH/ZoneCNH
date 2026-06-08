# TASK-XLIB-003

> 规则治理：PR 流程、ADR 管理、规则生命周期

---

```yaml
task_id: TASK-XLIB-003
module: xlib-standard
scope: "建立规则治理协议——PR 流程（proposal/review/approve/merge）、ADR 管理和规则生命周期（active/deprecated/superseded）"
spec_ref:
  - "module/xlib-standard/SPEC.md#FR-007"
  - "module/xlib-standard/SPEC.md#FR-008"
files:
  - "docs/standard/governance/CONTRIBUTING.md"
  - "docs/standard/governance/rule-lifecycle.yaml"
  - "docs/adr/ADR-TEMPLATE.md"
  - "docs/adr/ADR-001-standard-source-of-truth.md"
  - "docs/adr/ADR-002-harness-gate-design.md"
acceptance_criteria:
  - "AC-T03: docs/adr/ 存在 9 个 Accepted ADR"
  - "FR-007 WHEN 新规则通过 PR 提交 THEN 经过 proposal -> review -> approve -> merge 流程"
  - "FR-008 WHEN ADR 被创建 THEN 格式符合模板且状态为 Accepted"
depends_on:
  - "TASK-XLIB-001"
estimated_effort: "4h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description |
|---|---|
| FR-007 | 规则治理 PR 流程 |
| FR-008 | ADR 管理（9 个 Accepted ADR） |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | File Check | docs/adr/ 存在 9 个 Accepted ADR |
| — | CI Gate | ADR 格式验证通过 |

## Implementation Plan

### Step 1: 创建 ADR 模板
- 创建 `docs/adr/ADR-TEMPLATE.md`
- 包含：标题、状态、上下文、决策、后果

### Step 2: 创建 9 个 Accepted ADR
- ADR-001: Standard Source of Truth
- ADR-002: Harness Gate Design
- ADR-003: Evidence Runtime
- ADR-004: Go Reference Template
- ADR-005: Generator Strategy
- ADR-006: Debt Governance
- ADR-007: Goal Runtime Architecture
- ADR-008: Downstream Sync Protocol
- ADR-009: Security Boundary

### Step 3: 创建治理文件
- `governance/CONTRIBUTING.md`：PR 流程（proposal → review → approve → merge）
- `governance/rule-lifecycle.yaml`：规则生命周期（active/deprecated/superseded）

### Step 4: 验证
- docs/adr/ 存在 9 个 Accepted ADR
- ADR 格式验证通过
- PR 流程文档完整

### 风险评估

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| ADR 内容不准确 | 中 | 中 | 从上游 docs/adr/ 提取已有内容 |
| PR 流程与上游不一致 | 低 | 中 | 参照上游 CONTRIBUTING.md |
