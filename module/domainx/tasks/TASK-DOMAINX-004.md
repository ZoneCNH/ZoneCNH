# TASK-DOMAINX-004

> Exposure 值对象

---

```yaml
task_id: TASK-DOMAINX-004
module: domainx
scope: "实现 Exposure 值对象、NewExposure 构造函数、NetExposureRatio()"
spec_ref:
  - "module/domainx/SPEC.md#FR-004"
files:
  - "exposure.go"
  - "exposure_test.go"
acceptance_criteria:
  - "AC-009: Exposure 正常构造 → 返回 Exposure, nil 错误"
  - "AC-010: NetExposureRatio() 除零保护：grossExposure=0 → 返回 0"
depends_on:
  - "TASK-DOMAINX-001"
estimated_effort: "1h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|-------------|-------------|---------------------|
| FR-004 | Exposure 值对象 — NetExposureRatio() | AC-009, AC-010 |

## Non-scope

- 不计算希腊字母 delta/gamma/theta（OQ-004 待确认）
- 不做多交易所聚合（OQ-006 待评估）

## Test Plan

| Test Case | Type | Description |
|-----------|------|-------------|
| TC-009 | Unit | Exposure 正常构造：合法参数 → Exposure + nil |
| TC-010 | Unit | NetExposureRatio() = netExposure / grossExposure |
| TC-010 | Unit | NetExposureRatio() grossExposure=0 → 返回 0（不 panic） |

## Implementation Notes

- 除零保护：grossExposure 为 0 时返回 0，不 panic
- netPosition 可为负（short 仓位）
- 所有金额字段使用 `decimal.Decimal`
