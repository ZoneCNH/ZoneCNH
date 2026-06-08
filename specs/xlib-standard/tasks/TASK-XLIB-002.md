# TASK-XLIB-002

> 采纳状态机：8 状态枚举、6 禁止转换、状态转换验证

---

```yaml
task_id: TASK-XLIB-002
module: xlib-standard
scope: "实现 AdoptionStatus 8 状态枚举、6 个禁止转换规则和状态转换验证逻辑"
spec_ref:
  - "specs/xlib-standard/SPEC.md#FR-005"
  - "specs/xlib-standard/SPEC.md#FR-006"
  - "specs/xlib-standard/SPEC.md#BR-006"
files:
  - "docs/standard/adoption-status.yaml"
  - "docs/standard/adoption-transitions.yaml"
acceptance_criteria:
  - "AC-I01: 8 状态枚举和 6 个禁止转换规则正确执行"
  - "FR-005 WHEN 查询 adoption_status THEN 返回 8 种状态之一"
  - "FR-006 WHEN adoption_status=registered 直接尝试 -> adopted THEN enforcer 拒绝"
depends_on:
  - "TASK-XLIB-001"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description |
|---|---|
| FR-005 | 8 个 REQ 采纳状态枚举 |
| FR-006 | 状态转换验证（6 个禁止转换） |
| BR-006 | 状态转换必须经过验证 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| xlib-TC-013 | TL2 Truth-state | registered -> adopted 被拒绝 |
| — | Unit | 所有合法转换路径可执行 |
| — | Unit | 6 个禁止转换全部返回错误 |

## Implementation Plan

### Step 1: 定义状态枚举
- 创建 `adoption-status.yaml`，定义 8 个状态：
  - `not_adopted` → `registered` → `validating` → `validated` → `integrating` → `integrated` → `adopted` → `deprecated`

### Step 2: 定义转换规则
- 创建 `adoption-transitions.yaml`
- 定义合法转换路径和 6 个禁止转换：
  - registered → adopted（跳过中间状态）
  - deprecated → adopted（不可回退）
  - not_adopted → adopted（跳过全部）
  - adopted → registered（不可回退）
  - deprecated → registered（不可回退）
  - not_adopted → deprecated（跳过全部）

### Step 3: 实现验证逻辑
- goalcli `adoption-check` 命令读取转换规则
- 验证状态转换合法性
- 返回拒绝原因

### Step 4: 验证
- xlib-TC-013 通过
- 所有合法转换可执行
- 6 个禁止转换全部返回错误

### 风险评估

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| 状态枚举遗漏 | 低 | 高 | 对照上游 governance.md §3.5 核对 |
| 禁止转换规则不完整 | 低 | 中 | 从 CONFLICT-LEDGER.md 提取 |
