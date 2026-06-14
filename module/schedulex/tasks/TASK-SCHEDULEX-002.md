# TASK-SCHEDULEX-002

> Scheduler 实现：Schedule、Cancel、Start

---

```yaml
task_id: TASK-SCHEDULEX-002
module: schedulex
scope: "实现 Scheduler 接口的 Schedule、Cancel、Start 方法"
non_scope: "不实现 Overlap/Misfire 策略，不处理 Stop 停机逻辑"
spec_ref:
  - "module/schedulex/SPEC.md#FR-001"
  - "module/schedulex/SPEC.md#FR-002"
  - "module/schedulex/SPEC.md#FR-005"
files:
  - "scheduler_impl.go"
  - "scheduler_test.go"
acceptance_criteria:
  - "Schedule 注册 job 并返回 JobID"
  - "cron 语法错误时返回 ErrInvalidTrigger"
  - "interval <= 0 时返回 ErrInvalidTrigger"
  - "重复 JobID 返回 ErrDuplicateJob"
  - "Cancel 取消存在的 job"
  - "Cancel 不存在的 job 返回 ErrJobNotFound"
  - "Start 启动调度循环"
depends_on:
  - "TASK-SCHEDULEX-001"
  - "TASK-SCHEDULEX-011"
estimated_effort: "4h"
priority: P0
status: pending
```

---

## Non-scope

- 不涉及本 Task 范围外的功能

## Requirements Covered

| Requirement | Description                   | Acceptance Criteria |
| ----------- | ----------------------------- | ------------------- |
| FR-001      | Schedule：注册 job + 参数校验 | 4 个 WHEN/THEN 场景 |
| FR-002      | Trigger：cron/interval 触发   | 3 个 WHEN/THEN 场景 |
| FR-005      | Cancel：取消 job              | 2 个 WHEN/THEN 场景 |

## Test Plan

| Test Case | Type | Description                            |
| --------- | ---- | -------------------------------------- |
| TC-001    | Unit | Schedule 合法 cron job：返回 JobID     |
| TC-009    | Unit | Schedule 重复 ID：ErrDuplicateJob      |
| TC-001    | Unit | Schedule 合法 interval job：返回 JobID |
| TC-005    | Unit | Cancel 存在的 job：返回 nil            |
| TC-005    | Unit | Cancel 不存在的 job：ErrJobNotFound    |
| —         | Unit | Start 后 job 按时触发                  |

## Implementation Notes

- 内部使用 `map[string]*jobState` 存储已注册 job
- `Start` 启动主循环 goroutine，按 trigger 计算下次执行时间
- cron 解析使用第三方库或自实现简化版

## Implementation Plan

| Step | Description                                              | Deliverables        | Verification          |
| ---- | -------------------------------------------------------- | ------------------- | --------------------- |
| 1    | 实现 `schedulerImpl` 结构体（jobs map, mu, ctx, cancel） | `scheduler_impl.go` | `go build ./...` 通过 |
| 2    | 实现 `Schedule`：校验 trigger → 注册 job → 返回 ID       | `scheduler_impl.go` | §7.1 全部通过         |
| 3    | 实现 `Cancel`：查找 job → 取消 → 从 map 移除             | `scheduler_impl.go` | §7.5 全部通过         |
| 4    | 实现 `Start`：主循环 → 计算下次时间 → 触发 handler       | `scheduler_impl.go` | 触发测试通过          |

### Risk Assessment

| Risk                  | Probability | Impact | Mitigation               |
| --------------------- | ----------- | ------ | ------------------------ |
| cron 解析库引入       | Medium      | Medium | 自实现简化版或使用成熟库 |
| 主循环 goroutine 泄漏 | Low         | High   | ctx 取消时清理           |
