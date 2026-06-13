# TASK-CLICKHOUSEX-006

> 可观测集成：metrics / tracing / logging

---

```yaml
task_id: TASK-CLICKHOUSEX-006
module: clickhousex
scope: "集成 observex 的 metrics、tracing、logging，输出慢查询和写入观测指标"
spec_ref:
  - "module/clickhousex/SPEC.md#BR-008"
  - "module/clickhousex/SPEC.md#18"
files:
  - "observability.go"
  - "observability_test.go"
  - "client.go"
  - "options.go"
acceptance_criteria:
  - "AC-025: metrics 包含 table 标签（写入）或 query 标签（查询）"
  - "NFR-016: metrics 指标输出正确"
  - "NFR-017: tracing span 传播正确"
depends_on:
  - "TASK-CLICKHOUSEX-002"
  - "TASK-CLICKHOUSEX-003"
  - "TASK-CLICKHOUSEX-004"
estimated_effort: "2h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|-------------|-------------|---------------------|
| BR-008 | 可观测指标含 table/query 标签 | AC-025 |
| NFR-016 | metrics 指标输出正确 | go test |
| NFR-017 | tracing span 传播正确 | go test |

## Non-scope

- 不实现 observex 本身（由 observex 模块负责）
- 不定义新的 metrics 类型（使用 observex 标准 API）
- 不做告警规则定义

## Test Plan

| Test Case | Type | Description |
|-----------|------|-------------|
| — | Unit | Exec 后 clickhousex.query.duration histogram 有记录 |
| — | Unit | InsertBatch 后 clickhousex.write.duration histogram 有记录 |
| — | Unit | clickhousex.write.rows counter 正确计数 |
| — | Unit | clickhousex.write.bytes counter 正确计数 |
| — | Unit | clickhousex.pool.active gauge 反映连接池状态 |
| — | Unit | clickhousex.pool.idle gauge 反映空闲连接 |
| — | Unit | clickhousex.pool.exhausted counter 在池耗尽时递增 |
| — | Unit | clickhousex.exec span 创建和传播 |
| — | Unit | clickhousex.query span 创建和传播 |
| — | Unit | clickhousex.insert_batch span 创建和传播 |
| — | Unit | clickhousex.connected 日志输出 |
| — | Unit | clickhousex.disconnected 日志输出（warn 级别） |
| — | Unit | clickhousex.batch.insert 日志含 rows + duration |
| — | Unit | clickhousex.query.error 日志含 sql + error |

## Implementation Notes

- observex 通过接口注入（不直接 import observex 实现包）
- 接收 `observex.Logger` / `observex.Meter` / `observex.Tracer` 接口
- 在 Client 创建时通过 Option 模式注入
- 若未注入，使用 no-op 实现（不阻塞功能）
- table 标签：InsertBatch/Exec 写操作使用
- sqlId 标签：Query 操作使用 SQL 哈希或调用方传入的标识
