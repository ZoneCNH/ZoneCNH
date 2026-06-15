# TASK-DOMAINX-001

> Order 值对象 + 枚举常量

---

```yaml
task_id: TASK-DOMAINX-001
module: domainx
scope: "实现 Order 值对象、NewOrder 构造函数、校验逻辑、Side/OrderType/OrderStatus 枚举"
spec_ref:
  - "module/domainx/SPEC.md#FR-001"
  - "module/domainx/SPEC.md#BR-002"
  - "module/domainx/SPEC.md#BR-003"
  - "module/domainx/SPEC.md#BR-004"
  - "module/domainx/SPEC.md#BR-007"
files:
  - "order.go"
  - "order_test.go"
  - "enums.go"
  - "errors.go"
acceptance_criteria:
  - "AC-001: Order 正常构造 → 返回 Order, nil 错误"
  - "AC-002: Order 非法 quantity → ErrInvalidQuantity"
  - "AC-003: Order 非法 price → ErrInvalidPrice"
  - "AC-004: Order 空 symbol → ErrEmptySymbol"
depends_on: []
estimated_effort: "2h"
priority: P0
status: done
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|-------------|-------------|---------------------|
| FR-001 | Order 值对象 — 构造 + 校验 + getter | AC-001 ~ AC-004 |
| BR-002 | Quantity 正数校验 | AC-002 |
| BR-003 | Price 非负校验 | AC-003 |
| BR-004 | Symbol 非空 | AC-004 |
| BR-007 | Decimal 零值语义 | AC-002, AC-003 |

## Non-scope

- 不实现 Fill / Position / Exposure（由 TASK-002~004 负责）
- 不实现 JSON 序列化测试（由 TASK-005 负责）

## Test Plan

| Test Case | Type | Description |
|-----------|------|-------------|
| TC-001 | Unit | Order 正常构造：合法参数 → Order + nil |
| TC-002 | Unit | Order 非法 quantity：<=0 或 decimal 零值 → ErrInvalidQuantity |
| TC-003 | Unit | Order 非法 price：<0 或 decimal 零值 → ErrInvalidPrice |
| TC-004 | Unit | Order 空 symbol："" → ErrEmptySymbol |

## Implementation Notes

- Order 使用私有字段 + 公开 getter 方法（不可变）
- price/quantity 使用 `decimal.Decimal`（来自 decimalx）
- 构造函数 `NewOrder(symbol, side, orderType, quantity, price) (Order, error)`
- createdAt/updatedAt 自动设为 time.Now()
- id 自动生成（UUID）
- status 初始为 OrderStatusPending
