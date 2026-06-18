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
  - "AddJob 注册 job 并返回 nil（job 标识为 Job.Name()）"
  - "trigger 不合法时返回 ErrInvalidJob"
  - "interval <= 0 时返回 ErrInvalidJob"
  - "重复 Job name 返回 ErrJobExists"
  - "Cancel 取消存在的 job（v1.1 缺口，运行时未实现）"
  - "Cancel 不存在的 job 返回错误（v1.1 缺口）"
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
| TC-001    | Unit | AddJob 合法 cron job：返回 nil         |
| TC-009    | Unit | AddJob 重复 name：ErrJobExists         |
| TC-001    | Unit | AddJob 合法 interval job：返回 nil     |
| TC-005    | Unit | Cancel 存在的 job：返回 nil（v1.1 缺口） |
| TC-005    | Unit | Cancel 不存在的 job：错误（v1.1 缺口）  |
| —         | Unit | Start 后 job 按时触发                  |

## Implementation Notes

- 内部使用 `map[string]*jobState` 存储已注册 job
- `Start` 启动主循环 goroutine，按 trigger 计算下次执行时间
- cron 解析使用第三方库或自实现简化版

## Implementation Plan

| Step | Description                                              | Deliverables        | Verification          |
| ---- | -------------------------------------------------------- | ------------------- | --------------------- |
| 1    | 实现 `schedulerImpl` 结构体（jobs map, mu, ctx, cancel） | `scheduler_impl.go` | `go build ./...` 通过 |
| 2    | 实现 `AddJob`：校验 trigger → 注册 job → 返回 nil        | `scheduler_impl.go` | §8.1 全部通过         |
| 3    | 实现 `Cancel`：查找 job → 取消 → 从 map 移除（v1.1 缺口） | `scheduler_impl.go` | §8.1 全部通过         |
| 4    | 实现 `Start`：主循环 → 计算下次时间 → 触发 Job.Run       | `scheduler_impl.go` | 触发测试通过          |

### Risk Assessment

| Risk                  | Probability | Impact | Mitigation               |
| --------------------- | ----------- | ------ | ------------------------ |
| cron 解析库引入       | Medium      | Medium | 自实现简化版或使用成熟库 |
| 主循环 goroutine 泄漏 | Low         | High   | ctx 取消时清理           |
