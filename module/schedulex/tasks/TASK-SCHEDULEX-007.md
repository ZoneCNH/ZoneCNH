# TASK-SCHEDULEX-007

> Locker 实现：分布式锁

---

```yaml
task_id: TASK-SCHEDULEX-007
module: schedulex
scope: "实现 Locker 接口，支持分布式锁获取和 TTL 校验"
non_scope: "不实现 Redis/Postgres 存储后端，不引入外部依赖"
spec_ref:
  - "module/schedulex/SPEC.md#FR-008"
files:
  - "locker_impl.go"
  - "locker_test.go"
acceptance_criteria:
  - "锁获取成功时执行 job"
  - "锁获取失败时跳过本次"
  - "lock TTL < job 最大执行时间时返回配置错误"
depends_on:
  - "TASK-SCHEDULEX-011"
estimated_effort: "2h"
priority: P1
status: pending
```

---

## Non-scope

- 不涉及本 Task 范围外的功能

## Requirements Covered

| Requirement | Description                 | Acceptance Criteria |
| ----------- | --------------------------- | ------------------- |
| FR-008      | Locker：分布式锁 + TTL 校验 | 3 个 WHEN/THEN 场景 |

## Test Plan

| Test Case | Type | Description          |
| --------- | ---- | -------------------- |
| TC-004    | Unit | 锁获取成功：执行 job |
| TC-004    | Unit | 锁获取失败：跳过     |
| TC-004    | Unit | TTL 过短：配置错误   |

## Implementation Notes

- `Locker` 接口：`Lock(ctx, key, ttl) (unlock func(), err error)`
- `NoopLocker`：始终成功，用于单机测试
- TTL 校验在 Schedule 注册时检查

## Implementation Plan

| Step | Description                        | Deliverables        | Verification          |
| ---- | ---------------------------------- | ------------------- | --------------------- |
| 1    | 实现 `NoopLocker`：始终成功        | `locker_impl.go`    | `go build ./...` 通过 |
| 2    | 集成到 scheduler：job 执行前获取锁 | `scheduler_impl.go` | §7.8-1, §7.8-2 通过   |
| 3    | 实现 TTL 校验                      | `locker_impl.go`    | §7.8-3 通过           |

### Risk Assessment

| Risk                     | Probability | Impact | Mitigation                |
| ------------------------ | ----------- | ------ | ------------------------- |
| Redis 锁实现引入外部依赖 | Medium      | Medium | 接口抽象，NoopLocker 默认 |
