# TASK-CLICKHOUSEX-001

> NewClient 工厂函数 + Config 配置结构体

---

```yaml
task_id: TASK-CLICKHOUSEX-001
module: clickhousex
scope: "实现 NewClient 工厂函数、Config 配置结构体、DSN 校验、连接池初始化"
spec_ref:
  - "module/clickhousex/SPEC.md#FR-001"
  - "module/clickhousex/SPEC.md#BR-001"
files:
  - "clickhousex.go"
  - "config.go"
  - "config_test.go"
  - "clickhousex_test.go"
acceptance_criteria:
  - "AC-001: NewClient 合法配置 → 返回 Client, nil 错误"
  - "AC-002: NewClient 空 DSN → 返回 ErrInvalidConfig"
  - "AC-018: 连接池默认 size=10, max=100，Config 可覆盖"
  - "NFR-014: DSN 密码部分用 *** 脱敏"
depends_on: []
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|-------------|-------------|---------------------|
| FR-001 | NewClient：创建连接池，DSN 校验 | AC-001, AC-002 |
| BR-001 | 连接池大小默认 10，最大 100 | AC-018 |
| NFR-014 | DSN 不泄露到日志 | Code review |

## Non-scope

- 不实现 Exec/Query/InsertBatch 方法（由 TASK-002~004 负责）
- 不实现 Health/Close（由 TASK-005 负责）
- 不实现内部连接池逻辑（internal/pool/，后续实现）

## Test Plan

| Test Case | Type | Description |
|-----------|------|-------------|
| TC-005 | Unit | NewClient 合法 DSN → 返回 Client |
| TC-005 | Unit | NewClient 空 DSN → ErrInvalidConfig |
| TC-005 | Unit | NewClient DSN 格式错误 → ErrInvalidConfig |
| — | Unit | Config 默认值：PoolSize=10, MaxPoolSize=100 |
| — | Unit | Config.Validate() 校验逻辑 |

## Implementation Notes

- Config 结构体定义在 `config.go`，使用 Option 模式
- NewClient 不建立实际连接（延迟连接），仅验证 DSN 格式
- 使用 `fmt.Sprintf` 而非 `%w` 包装来自 clickhouse-go 驱动的错误
- DSN 脱敏：日志中替换 `password=` 后的部分为 `***`
