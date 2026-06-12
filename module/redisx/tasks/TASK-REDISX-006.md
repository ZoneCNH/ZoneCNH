# TASK-REDISX-006

> Locker token owner 与 Lua guarded release

---

```yaml
task_id: TASK-REDISX-006
module: redisx
scope: "实现 Locker Acquire/Renew/Release，保证 holder token、TTL、续期和原子释放校验。"
spec_ref:
  - "module/redisx/SPEC.md#FR-010"
  - "module/redisx/SPEC.md#FR-011"
test_cases:
  - "TC-002"
files:
  - "locker.go"
  - "lock_script.go"
  - "locker_test.go"
  - "lock_concurrency_test.go"
  - "testutil_test.go"
acceptance_criteria:
  - "Acquire 获取锁成功返回 true"
  - "Acquire 获取锁失败返回 false 或 ErrLockAcquireFailed"
  - "Release 释放锁"
  - "锁 TTL 过期自动释放"
depends_on:
  - "TASK-REDISX-000"
  - "TASK-REDISX-001"
  - "TASK-REDISX-002"
estimated_effort: "1d"
priority: P0
status: pending
```

---

## Purpose

提供单 Redis 实例语义下的分布式锁基础能力，重点保证 holder token、TTL、续期和释放保护，而不是扩展为多节点一致性算法。

## Requirements Covered

| Requirement | Description           | Acceptance Criteria           |
| ----------- | --------------------- | ----------------------------- |
| FR-010      | Acquire：获取分布式锁 | 成功返回 true，已被持有返回 false 或 ErrLockAcquireFailed |
| FR-011      | Release：释放锁       | 持有者释放成功；非持有者返回 ErrLockNotHeld |

## Test Plan

| Test Case | Type | Description                          |
| --------- | ---- | ------------------------------------ |
| TC-002    | Unit | Acquire 成功后 Release 释放          |
| TC-002    | Unit | 重复 Acquire 返回 false 或 ErrLockAcquireFailed |
| TC-002    | Unit | TTL 过期后可重新 Acquire             |

## Non-Scope

- 不直接 import `configx`、`observex`、`resiliencx` 或 `contracts`。
- 不实现业务缓存模型、业务领域 DTO 或跨模块注册逻辑。
- 直接依赖边界保持为 `kernel` + Redis client library `github.com/redis/go-redis/v9`。

## Implementation Notes

- 使用 Redis SET NX EX 实现分布式锁
- `Release(ctx, key)` 使用 Lua 脚本保证仅持有者可释放，非持有者返回 ErrLockNotHeld

## Done Evidence

| Step | Description                                  | Deliverables     | Verification |
| ---- | -------------------------------------------- | ---------------- | ------------ |
| 1    | 实现 `Acquire`：SET NX EX + 返回 bool/error | `locker_impl.go` | TC-002 通过 |
| 2    | 实现 `Release` Lua 脚本保证仅持有者释放      | `locker_impl.go` | TC-002 通过 |

### Risk Assessment

| Risk       | Probability | Impact | Mitigation                |
| ---------- | ----------- | ------ | ------------------------- |
| 锁超时竞态 | Medium      | High   | fencing token 或 Lua 脚本 |
