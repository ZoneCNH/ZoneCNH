# TASK-REDISX-003

> Client 实现：Exists/Expire/HGet/HSet

---

```yaml
task_id: TASK-REDISX-003
module: redisx
scope: "实现 Client 接口的 Exists/Expire 与 Hash 操作（FR-004、FR-005、FR-006）"
spec_ref:
  - "module/redisx/SPEC.md#FR-004"
  - "module/redisx/SPEC.md#FR-005"
  - "module/redisx/SPEC.md#FR-006"
test_cases:
  - "TC-005"
  - "TC-006"
files:
  - "cache.go"
  - "cache_policy.go"
  - "cache_test.go"
  - "cache_concurrency_test.go"
  - "testutil_test.go"
acceptance_criteria:
  - "Exists 返回 true/false"
  - "Expire 设置 TTL"
  - "HGet/HSet 操作 Hash 字段正确"
depends_on:
  - "TASK-REDISX-000"
  - "TASK-REDISX-002"
estimated_effort: "1d"
priority: P0
status: pending
```

---

## Purpose

交付面向业务读路径的缓存客户端，同时保持 redisx 的基础设施边界：调用方通过 typed Options 和 Codec 注入策略，redisx 不读取配置中心、不暴露完整 Key、不承担业务缓存模型。

## Requirements Covered

| Requirement | Description             | Acceptance Criteria |
| ----------- | ----------------------- | ------------------- |
| FR-004      | Exists：检查存在        | 返回 true/false     |
| FR-005      | Expire：设置 TTL        | TTL 生效            |
| FR-006      | HGet/HSet：Hash 操作    | 字段读写正确        |

## Test Plan

| Test Case | Type | Description                  |
| --------- | ---- | ---------------------------- |
| TC-005    | Unit | Exists 返回正确值，Expire 后 TTL 更新 |
| TC-006    | Unit | HSet 后 HGet 返回正确值              |

## Non-Scope

- 不直接 import `configx`、`observex`、`resiliencx` 或 `contracts`。
- 不实现业务缓存模型、业务领域 DTO 或跨模块注册逻辑。
- 直接依赖边界保持为 `kernel` + Redis client library `github.com/redis/go-redis/v9`。

## Implementation Notes

- Exists/Expire/Hash 操作直接包装 redis 命令并转换错误

## Done Evidence

| Step | Description           | Deliverables     | Verification  |
| ---- | --------------------- | ---------------- | ------------- |
| 1    | 实现 `Exists`/`Expire` | `client_impl.go` | TC-005 通过 |
| 2    | 实现 `HGet`/`HSet`    | `client_impl.go` | TC-006 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
| ---- | ----------- | ------ | ---------- |
| 无   | Low         | Low    | —          |
