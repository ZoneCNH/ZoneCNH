# TASK-KERNEL-009

> retryx 子包：重试策略配置原语

---

```yaml
task_id: TASK-KERNEL-009
module: kernel
scope: "实现 retryx 子包：RetryPolicy、Validate、Delay、DelayWithJitter、ShouldRetry"
spec_ref:
  - "module/kernel/SPEC.md#FR-005"
  - "module/kernel/SPEC.md#9.5"
  - "module/kernel/SPEC.md#10.3"
files:
  - "retryx/retryx.go"
  - "retryx/retryx_test.go"
  - "retryx/example_test.go"
acceptance_criteria:
  - "AC-008: Delay 指数退避 + Jitter + 溢出保护"
  - "AC-RETRYX-01: DefaultRetryPolicy 返回 {MaxAttempts:3, BaseDelay:100ms, MaxDelay:2s}"
  - "AC-RETRYX-02: Validate 在字段非法时返回 ErrorKindValidation 错误"
  - "AC-RETRYX-03: Delay(1) 返回 BaseDelay"
  - "AC-RETRYX-04: Delay 溢出保护生效"
  - "AC-RETRYX-05: DelayWithJitter fraction 钳位到 [-1, 1]"
  - "AC-RETRYX-06: ShouldRetry 遍历 errx 错误链检查 Retryable 标记"
  - "AC-RETRYX-07: go test -race -count=1 ./retryx/... 通过"
depends_on:
  - "TASK-KERNEL-000"
  - "TASK-KERNEL-001"
estimated_effort: "1.5h"
priority: P0
status: pending
```

---

## Files Likely to Change

- `retryx/retryx.go` — 新建（RetryPolicy/Validate/Delay/DelayWithJitter/ShouldRetry）
- `retryx/retryx_test.go` — 新建
- `retryx/example_test.go` — 新建

## Requirements Covered

> Spec TC: TC-006

| Requirement | Description |
|---|---|
| FR-005 | 重试策略 |

## Internal Dependencies

- `errx` — ShouldRetry 遍历 errx.Error 链，Validate 返回 ErrorKindValidation

## Non-scope

- 不实现重试执行循环（→ resiliencx）
- 不实现熔断/限流/退避状态机

## Test Plan

| TC | Type | Description |
|----|------|-------------|
| TC-006 | Unit | 指数退避：Delay(3)≈BaseDelay×2² |

## Implementation Notes

- Delay(attempt) = BaseDelay * 2^(attempt-1)，受 MaxDelay 约束
- 溢出保护：达到 maxDuration/2 时停止加倍
- DelayWithJitter 内部钳位 fraction 到 [-1, 1]，结果 < 0 返回 0
