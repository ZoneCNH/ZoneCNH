# TASK-CLICKHOUSEX-003

> Query 方法 + Rows 接口实现 + ClickHouse 类型映射

---

```yaml
task_id: TASK-CLICKHOUSEX-003
module: clickhousex
scope: "实现 Query 方法、Rows 接口（Next/Scan/Close/Err/ColumnTypes）、ClickHouse 类型映射"
spec_ref:
  - "module/clickhousex/SPEC.md#FR-003"
  - "module/clickhousex/SPEC.md#FR-007"
  - "module/clickhousex/SPEC.md#FR-008"
  - "module/clickhousex/SPEC.md#BR-011"
  - "module/clickhousex/SPEC.md#BR-012"
files:
  - "rows.go"
  - "rows_test.go"
  - "client.go"
  - "client_test.go"
  - "types.go"
acceptance_criteria:
  - "AC-005: Query 有结果 → Rows 可迭代"
  - "AC-006: Query 无结果 → 空 Rows，Next() 返回 false"
  - "AC-012: Scan 列数不匹配 → ErrColumnCountMismatch"
  - "AC-013: Scan Nullable 列到非指针 → ErrTypeMismatch"
  - "AC-014: ColumnTypes 返回列名、类型、Nullable"
  - "AC-026: Decimal 类型映射到 decimal.Decimal"
depends_on:
  - "TASK-CLICKHOUSEX-002"
estimated_effort: "4h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|-------------|-------------|---------------------|
| FR-003 | Query：OLAP 查询，返回 Rows | AC-005, AC-006 |
| FR-007 | Rows.Next/Scan/Close | AC-005, AC-012, AC-013 |
| FR-008 | Rows.ColumnTypes | AC-014 |
| BR-011 | Nullable → Go 指针类型 | AC-013 |
| BR-012 | Decimal → decimal.Decimal | AC-026 |

## Non-scope

- 不实现 InsertBatch（由 TASK-004 负责）
- 不实现 Exec（由 TASK-002 负责）
- 不实现 Health/Close（由 TASK-005 负责）
- 不做结果集缓存或预取

## Test Plan

| Test Case | Type | Description |
|-----------|------|-------------|
| TC-001 | Integration | Query 返回 100 行，Next/Scan 正确迭代 |
| — | Unit | Query 无结果 → Next() 首次返回 false，nil error |
| TC-004 | Integration | Nullable(Int32) 列 → Scan 到 *int32，NULL 时为 nil |
| — | Unit | Scan 到非指针类型处理 Nullable → ErrTypeMismatch |
| — | Unit | Scan 列数不匹配 → ErrColumnCountMismatch |
| — | Unit | ColumnTypes() 返回列名、ClickHouse 原生类型名、Nullable 标志 |
| — | Unit | Decimal(18,8) → decimal.Decimal 精度无丢失 |
| — | Unit | LowCardinality(String) → string |
| — | Unit | Array(Int32) → []int32 |
| — | Unit | Rows.Close() 释放资源 |

## Implementation Notes

- 类型映射表在 `types.go` 中定义
- Nullable 列在 Scan 前检查 dest 是否为指针类型
- ColumnTypes 在首次 Next() 调用后可用（利用驱动元数据）
- Rows.Err() 返回迭代过程中的错误（区别于 Query 返回的错误）
- 大结果集逐行迭代，不一次性加载到内存
