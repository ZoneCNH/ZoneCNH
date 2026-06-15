# TASK-DOMAINX-002

> Fill 值对象

---

```yaml
task_id: TASK-DOMAINX-002
module: domainx
scope: "实现 Fill 值对象、NewFill 构造函数、校验逻辑、FillSide 枚举"
spec_ref:
  - "module/domainx/SPEC.md#FR-002"
  - "module/domainx/SPEC.md#BR-002"
files:
  - "fill.go"
  - "fill_test.go"
acceptance_criteria:
  - "AC-005: Fill 正常构造 → 返回 Fill, nil 错误"
  - "AC-006: Fill 非法 fee → ErrInvalidFee"
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
| FR-002 | Fill 值对象 — 构造 + 校验 | AC-005, AC-006 |
| BR-002 | Quantity 正数校验 | AC-006（隐式：quantity <= 0 拒绝） |

## Non-scope

- 不实现 Position / Exposure（由 TASK-003~004 负责）
- 不实现 JSON 序列化测试（由 TASK-005 负责）

## Test Plan

| Test Case | Type | Description |
|-----------|------|-------------|
| TC-005 | Unit | Fill 正常构造：合法参数 → Fill + nil |
| TC-006 | Unit | Fill 非法 fee：fee < 0 → ErrInvalidFee |
| TC-006 | Unit | Fill 非法 quantity：<= 0 → ErrInvalidQuantity |

## Implementation Notes

- Fill 依赖 Order ID（orderID 字段）但不 import Order 类型
- price/quantity/fee 使用 `decimal.Decimal`
- 构造函数 `NewFill(orderID, symbol, side, quantity, price, fee, feeCurrency) (Fill, error)`
- timestamp 自动设为 time.Now()
- id 自动生成（UUID）
