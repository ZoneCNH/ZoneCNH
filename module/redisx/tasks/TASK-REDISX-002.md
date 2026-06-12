# TASK-REDISX-002

> Client 实现：Get/Set/Del

---

```yaml
task_id: TASK-REDISX-002
module: redisx
scope: "实现 Client 接口的基础 KV 操作（FR-001 至 FR-003）"
spec_ref:
  - "module/redisx/SPEC.md#FR-003"
test_cases:
  - "TC-001"
files:
  - "client.go"
  - "kv.go"
  - "ttl.go"
  - "kv_test.go"
  - "ttl_test.go"
acceptance_criteria:
  - "Get 返回已设置的值"
  - "Get 不存在的 key 透传 go-redis 的 redis.Nil 语义"
  - "Set 存储值，可设置 TTL"
  - "Del 删除 key"
depends_on:
  - "TASK-REDISX-000"
  - "TASK-REDISX-001"
estimated_effort: "1d"
priority: P0
status: pending
```

---

## Purpose

Implement the core Redis KV and TTL surface used by later cache, counter, and health behavior.

## Requirements Covered

| Requirement | Description      | Acceptance Criteria         |
| ----------- | ---------------- | --------------------------- |
| FR-001      | Get：获取值      | 返回正确值或 `redis.Nil` |
| FR-002      | Set：设置值      | 存储成功，TTL 生效          |
| FR-003      | Del：删除 key    | 删除成功                    |

## Test Plan

| Test Case | Type | Description                          |
| --------- | ---- | ------------------------------------ |
| TC-001    | Unit | Set 后 Get 返回正确值                |
| TC-001    | Unit | Get 不存在的 key 返回 `redis.Nil` |
| TC-001    | Unit | Del 后 Get 返回 `redis.Nil`       |

## Non-Scope

- 不直接 import `configx`、`observex`、`resiliencx` 或 `contracts`。
- 不实现业务缓存模型、业务领域 DTO 或跨模块注册逻辑。
- 直接依赖边界保持为 `kernel` + Redis client library `github.com/redis/go-redis/v9`。

## Implementation Notes

- All public methods must accept `context.Context`.
- Preserve `Key.Pattern` in all diagnostic paths.
- Treat Redis missing-key responses as `ErrNotFound`, not as dependency failures.

## Done Evidence

| Step | Description                          | Deliverables     | Verification     |
| ---- | ------------------------------------ | ---------------- | ---------------- |
| 1    | 实现 `Get`/`Set`/`Del`               | `client_impl.go` | 基础 KV 测试通过 |
| 2    | 错误处理：Get/HGet miss 保持 `redis.Nil` 语义 | `client_impl.go` | 错误类型正确     |

### Risk Assessment

| Risk           | Probability | Impact | Mitigation    |
| -------------- | ----------- | ------ | ------------- |
| redis 连接失败 | Low         | High   | 连接池 + 模块内 timeout/retry/fast-fail 策略 |
