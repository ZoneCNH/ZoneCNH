# TASK-REDISX-004

> Client 实现：LPush/LRange/Subscribe

---

```yaml
task_id: TASK-REDISX-004
module: redisx
scope: "实现 Client 接口的 List 和 Subscribe 方法（FR-007、FR-008）"
spec_ref:
  - "module/redisx/SPEC.md#FR-007"
  - "module/redisx/SPEC.md#FR-008"
test_cases:
  - "TC-007"
  - "TC-008"
files:
  - "structures.go"
  - "pubsub.go"
  - "structures_test.go"
  - "pubsub_test.go"
  - "testutil_test.go"
acceptance_criteria:
  - "LPush/LRange 操作 List 正确"
  - "Subscribe 订阅 channel 并接收消息"
  - "取消订阅正确清理"
depends_on:
  - "TASK-REDISX-000"
  - "TASK-REDISX-001"
estimated_effort: "1d"
priority: P0
status: pending
```

---

## Purpose

补齐 Redis 结构化访问和订阅场景的最小稳定语义，使调用方无需直接操作底层 Redis client，同时所有网络调用仍受 context、KeyBuilder 与错误模型约束。

## Requirements Covered

| Requirement | Description             | Acceptance Criteria |
| ----------- | ----------------------- | ------------------- |
| FR-007      | LPush/LRange：List 操作 | 列表读写正确        |
| FR-008      | Subscribe：Pub/Sub 订阅 | 消息接收正确        |

## Test Plan

| Test Case | Type | Description                |
| --------- | ---- | -------------------------- |
| TC-007    | Unit | LPush 后 LRange 返回正确列表 |
| TC-008    | Unit | Subscribe 后发布消息可接收   |

## Non-Scope

- 不直接 import `configx`、`observex`、`resiliencx` 或 `contracts`。
- 不实现业务缓存模型、业务领域 DTO 或跨模块注册逻辑。
- 直接依赖边界保持为 `kernel` + Redis client library `github.com/redis/go-redis/v9`。

## Implementation Notes

- List 操作直接包装 Redis List 命令
- 使用 redis Pub/Sub
- 返回 `Message` channel

## Done Evidence

| Step | Description                                   | Deliverables     | Verification |
| ---- | --------------------------------------------- | ---------------- | ------------ |
| 1    | 实现 `LPush`/`LRange`                      | `client_impl.go` | TC-007 通过 |
| 2    | 实现 `Subscribe`：创建订阅 → 返回消息 channel | `client_impl.go` | TC-008 通过 |

### Risk Assessment

| Risk           | Probability | Impact | Mitigation        |
| -------------- | ----------- | ------ | ----------------- |
| 连接断开未重连 | Medium      | Medium | go-redis 内置重连 |
