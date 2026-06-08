# TASK-REDISX-006

> Locker 实现：Acquire/Release

---

```yaml
task_id: TASK-REDISX-006
module: redisx
scope: "实现 Locker 接口的 Acquire/Release 方法（FR-010、FR-011）"
spec_ref:
  - "specs/redisx/SPEC.md#FR-010"
  - "specs/redisx/SPEC.md#FR-011"
files:
  - "locker_impl.go"
  - "locker_impl_test.go"
acceptance_criteria:
  - "Acquire 获取锁成功返回 unlock 函数"
  - "Acquire 获取锁失败返回 ErrLockNotAcquired"
  - "Release 释放锁"
  - "锁 TTL 过期自动释放"
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
| FR-010 | Acquire：获取分布式锁 | 成功返回 unlock，失败返回错误 |
| FR-011 | Release：释放锁 | 释放成功 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | Unit | Acquire 成功后 Release 释放 |
| — | Unit | 重复 Acquire 返回 ErrLockNotAcquired |
| — | Unit | TTL 过期后可重新 Acquire |

## Implementation Notes

- 使用 Redis SET NX EX 实现分布式锁
- unlock 函数使用 Lua 脚本保证原子性

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `Acquire`：SET NX EX + 返回 unlock func | `locker_impl.go` | 测试通过 |
| 2 | 实现 Lua 脚本保证 Release 原子性 | `locker_impl.go` | 并发测试通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 锁超时竞态 | Medium | High | fencing token 或 Lua 脚本 |
