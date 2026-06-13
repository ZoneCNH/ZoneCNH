# TASK-CLICKHOUSEX-004

> InsertBatch 批量写入

---

```yaml
task_id: TASK-CLICKHOUSEX-004
module: clickhousex
scope: "实现 InsertBatch 批量写入方法，原生 batch insert 协议，列校验，表存在检查"
spec_ref:
  - "module/clickhousex/SPEC.md#FR-004"
  - "module/clickhousex/SPEC.md#BR-002"
  - "module/clickhousex/SPEC.md#BR-010"
files:
  - "client.go"
  - "client_test.go"
  - "batch.go"
  - "batch_test.go"
acceptance_criteria:
  - "AC-007: InsertBatch 正常写入 → 返回 nil"
  - "AC-008: InsertBatch 空 rows → 返回 nil（空操作）"
  - "AC-009: InsertBatch 空 cols → 返回 ErrEmptyColumns"
  - "AC-010: InsertBatch 列数不匹配 → 返回 ErrColumnCountMismatch"
  - "AC-011: InsertBatch 表不存在 → 返回 ErrTableNotFound"
  - "AC-019: 使用 ClickHouse 原生 batch insert 协议"
depends_on:
  - "TASK-CLICKHOUSEX-002"
estimated_effort: "3h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|-------------|-------------|---------------------|
| FR-004 | InsertBatch：原生 batch insert，列校验 | AC-007~AC-011 |
| BR-002 | 使用原生 batch insert 协议 | AC-019 |
| BR-010 | 不自动建表，表不存在时返回错误 | AC-011 |

## Non-scope

- 不做 SQL 拼接式批量写入
- 不做表自动创建
- 不做数据压缩（ClickHouse 原生支持）
- 不做部分重试（首个错误即返回）

## Test Plan

| Test Case | Type | Description |
|-----------|------|-------------|
| TC-001 | Integration | InsertBatch 100 行 + Query 验证一致性 |
| TC-003 | Integration | 100000 行 InsertBatch < 1s |
| — | Unit | InsertBatch 空 rows → 返回 nil |
| — | Unit | InsertBatch 空 cols → ErrEmptyColumns |
| — | Unit | InsertBatch 列数不匹配 → ErrColumnCountMismatch（含行号） |
| — | Unit | InsertBatch 表不存在 → ErrTableNotFound |
| — | Unit | 部分行失败 → 返回首个错误含行号 |
| — | Unit | ctx 超时时中断写入 |

## Implementation Notes

- 使用 `clickhouse-go/v2` 的 `conn.PrepareBatch(ctx, "INSERT INTO ...")` 
- 不拼接 SQL 字符串构建 INSERT
- 列数校验在 PrepareBatch 前执行（fast fail）
- 表存在检查：依赖 ClickHouse 返回的错误码判断
- 性能目标：10000 行 < 1s，100000 行 < 10s
