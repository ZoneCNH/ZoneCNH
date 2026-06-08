# TASK-REDISX-002

> Client 实现：Get/Set/Del/Exists/Expire

---

```yaml
task_id: TASK-REDISX-002
module: redisx
scope: "实现 Client 接口的基础 KV 操作（FR-001 至 FR-005）"
spec_ref:
  - "module/redisx/SPEC.md#FR-001"
  - "module/redisx/SPEC.md#FR-002"
  - "module/redisx/SPEC.md#FR-003"
  - "module/redisx/SPEC.md#FR-004"
  - "module/redisx/SPEC.md#FR-005"
files:
  - "client_impl.go"
  - "client_impl_test.go"
acceptance_criteria:
  - "Get 返回已设置的值"
  - "Get 不存在的 key 返回 ErrKeyNotFound"
  - "Set 存储值，可设置 TTL"
  - "Del 删除 key"
  - "Exists 返回 true/false"
  - "Expire 设置 TTL"
depends_on:
  - "TASK-REDISX-001"
estimated_effort: "3h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-001 | Get：获取值 | 返回正确值或 ErrKeyNotFound |
| FR-002 | Set：设置值 | 存储成功，TTL 生效 |
| FR-003 | Del：删除 key | 删除成功 |
| FR-004 | Exists：检查存在 | 返回 true/false |
| FR-005 | Expire：设置 TTL | TTL 生效 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | Unit | Set 后 Get 返回正确值 |
| — | Unit | Get 不存在的 key 返回 ErrKeyNotFound |
| — | Unit | Del 后 Get 返回 ErrKeyNotFound |
| — | Unit | Exists 返回正确值 |
| — | Unit | Expire 后 key 过期 |

## Implementation Notes

- 内部使用 `go-redis/v9` 客户端
- 每个方法包装 redis 命令并转换错误

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `Get`/`Set`/`Del` | `client_impl.go` | 基础 KV 测试通过 |
| 2 | 实现 `Exists`/`Expire` | `client_impl.go` | 全部测试通过 |
| 3 | 错误转换：redis.Nil → ErrKeyNotFound | `client_impl.go` | 错误类型正确 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| redis 连接失败 | Low | High | 连接池 + 重试 |
