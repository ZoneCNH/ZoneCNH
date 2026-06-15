# TASK-DOMAINX-003

> Position 值对象

---

```yaml
task_id: TASK-DOMAINX-003
module: domainx
scope: "实现 Position 值对象、NewPosition 构造函数、MarketValue()、UnrealizedPnL()"
spec_ref:
  - "module/domainx/SPEC.md#FR-003"
files:
  - "position.go"
  - "position_test.go"
acceptance_criteria:
  - "AC-007: Position.MarketValue() 返回 quantity * avgPrice"
  - "AC-008: Position.UnrealizedPnL(currentPrice) 返回 (currentPrice - avgPrice) * quantity"
depends_on:
  - "TASK-DOMAINX-001"
estimated_effort: "1h"
priority: P0
status: done
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|-------------|-------------|---------------------|
| FR-003 | Position 值对象 — MarketValue() + UnrealizedPnL() | AC-007, AC-008 |

## Non-scope

- 不实现 Exposure（由 TASK-004 负责）
- 不做组合级 Position 聚合（属于 portfolio-engine）

## Test Plan

| Test Case | Type | Description |
|-----------|------|-------------|
| TC-007 | Unit | MarketValue() = quantity * avgPrice（decimal 精确） |
| TC-008 | Unit | UnrealizedPnL(currentPrice) = (price - avg) * qty |
| TC-008 | Unit | UnrealizedPnL 正值（盈利）/ 负值（亏损） |

## Implementation Notes

- MarketValue() 和 UnrealizedPnL() 使用 decimal 精确运算
- 不缓存计算结果（每次调用重新计算）
- symbol 非空校验 + avgPrice >= 0 校验
