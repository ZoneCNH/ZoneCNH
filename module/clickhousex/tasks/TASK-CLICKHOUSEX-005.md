# TASK-CLICKHOUSEX-005

> Health 健康检查 + Close 关闭

---

```yaml
task_id: TASK-CLICKHOUSEX-005
module: clickhousex
scope: "实现 Health 健康检查和 Close 资源释放，均为幂等操作"
spec_ref:
  - "module/clickhousex/SPEC.md#FR-005"
  - "module/clickhousex/SPEC.md#FR-006"
  - "module/clickhousex/SPEC.md#BR-005"
  - "module/clickhousex/SPEC.md#BR-009"
files:
  - "health.go"
  - "health_test.go"
  - "client.go"
  - "client_test.go"
acceptance_criteria:
  - "AC-015: Close 幂等，多次调用不 panic"
  - "AC-016: Health 连接正常 → Ready=true, Live=true"
  - "AC-017: Health 连接异常 → Ready=false, Live=false"
  - "AC-022: Health() 多次调用结果一致，无副作用"
depends_on:
  - "TASK-CLICKHOUSEX-001"
estimated_effort: "1.5h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|-------------|-------------|---------------------|
| FR-005 | Health：连接池健康检查 | AC-016, AC-017 |
| FR-006 | Close：关闭连接池，等待进行中查询 | AC-015 |
| BR-005 | Health() 幂等无副作用 | AC-022 |
| BR-009 | Close() 幂等 | AC-015 |

## Non-scope

- 不实现连接池动态扩缩容
- 不做深度健康检查（如执行 SELECT 1）——仅检查连接池状态
- Close() 不保证所有进行中查询完成（有超时上限）

## Test Plan

| Test Case | Type | Description |
|-----------|------|-------------|
| TC-006 | Unit | Health 连接正常 → Ready=true, Live=true |
| TC-006 | Unit | Health 连接异常 → Ready=false, Live=false |
| TC-006 | Unit | Health 连接池部分可用 → low pool capacity |
| TC-007 | Unit | Close 后再次 Close → 返回 nil，不 panic |
| — | Unit | Close 并发调用 → 不 panic |
| — | Unit | Health 多次调用结果一致 |

## Implementation Notes

- Health() 使用 `conn.Ping(ctx)` 检查单个连接的健康状态
- Close() 使用 `sync.Once` 或 `atomic.Bool` 保证幂等
- Close() 等待超时：5s（通过 context.WithTimeout）
- HealthStatus.Message 在部分可用时提示 "low pool capacity"
