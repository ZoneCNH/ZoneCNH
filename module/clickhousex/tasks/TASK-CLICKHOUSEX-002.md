# TASK-CLICKHOUSEX-002

> Exec 方法 + 错误包装 + 连接重试

---

```yaml
task_id: TASK-CLICKHOUSEX-002
module: clickhousex
scope: "实现 Exec 方法、context 取消支持、错误包装、连接断开自动重试"
spec_ref:
  - "module/clickhousex/SPEC.md#FR-002"
  - "module/clickhousex/SPEC.md#BR-003"
  - "module/clickhousex/SPEC.md#BR-004"
  - "module/clickhousex/SPEC.md#BR-006"
  - "module/clickhousex/SPEC.md#BR-007"
files:
  - "client.go"
  - "client_test.go"
  - "errors.go"
acceptance_criteria:
  - "AC-003: Exec 正常 SQL → 返回 nil"
  - "AC-004: Exec 语法错误 → 返回包装后的 ClickHouse 错误"
  - "AC-020: SQL 参数使用占位符绑定，非字符串拼接"
  - "AC-021: 连接断开后自动重试 3 次（指数退避）"
  - "AC-023: ctx 取消/超时时操作中断，返回 ctx.Err()"
  - "AC-024: 错误消息格式 'clickhousex: <operation>: <detail>'"
depends_on:
  - "TASK-CLICKHOUSEX-001"
estimated_effort: "3h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|-------------|-------------|---------------------|
| FR-002 | Exec：DDL/DML 执行，ctx 取消 | AC-003, AC-004, AC-023 |
| BR-003 | 参数化绑定，禁止 SQL 拼接 | AC-020 |
| BR-004 | 自动重试 3 次，指数退避 | AC-021 |
| BR-006 | 所有操作接受 context.Context | AC-023 |
| BR-007 | 错误消息格式规范 | AC-024 |

## Non-scope

- 不实现 Query（由 TASK-003 负责）
- 不实现 InsertBatch（由 TASK-004 负责）
- 不实现内部重试策略库（可直接使用 retry 包或手写简单循环）

## Test Plan

| Test Case | Type | Description |
|-----------|------|-------------|
| TC-001 | Integration | Exec DDL + 数据写入成功 |
| TC-002 | Integration | 模拟连接断开 → ErrConnectionLost → 恢复后自动重连 |
| — | Unit | Exec SQL 语法错误 → 包装错误含 SQL 上下文 |
| — | Unit | ctx 超时 → 操作中断，返回 ctx.Err() |
| — | Unit | ctx 取消 → 操作中断，返回 ctx.Err() |
| — | Unit | 错误消息格式断言："clickhousex: exec: ..." |

## Implementation Notes

- 使用 `clickhouse-go/v2` 驱动的 `conn.ExecContext(ctx, sql, args...)`
- 错误包装：`fmt.Errorf("clickhousex: exec: %w", err)`
- 重试逻辑：最多 3 次，退避算法 `backoff * 2^attempt`，初始 100ms
- ctx 检查在每次重试前执行
- Exec 不返回 rows（与 Query 区分）
