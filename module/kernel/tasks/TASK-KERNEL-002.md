# TASK-KERNEL-002

> timex 子包：时钟抽象

---

```yaml
task_id: TASK-KERNEL-002
module: kernel
scope: "实现 timex 子包：Clock 接口、RealClock、FixedClock、FakeClock"
spec_ref:
  - "module/kernel/SPEC.md#FR-007"
  - "module/kernel/SPEC.md#BR-012"
  - "module/kernel/SPEC.md#9.7"
files:
  - "timex/timex.go"
  - "timex/timex_test.go"
  - "timex/example_test.go"
acceptance_criteria:
  - "AC-011: FakeClock Advance 后 Now 返回正确时间，RealClock 使用 time.Now"
  - "AC-TIMEX-01: FixedClock.Now() 始终返回构造时时间（不可变）"
  - "AC-TIMEX-02: nil *FakeClock.Now() 返回 time.Time{}（零值安全）"
  - "AC-TIMEX-03: nil *FakeClock.Advance() 静默忽略"
  - "AC-TIMEX-04: FakeClock.Advance 累积多次调用正确"
  - "AC-TIMEX-05: go test -race -count=1 ./timex/... 通过"
depends_on:
  - "TASK-KERNEL-000"
estimated_effort: "1.5h"
priority: P0
status: pending
```

---

## Files Likely to Change

- `timex/timex.go` — 新建（Clock、RealClock、FixedClock、FakeClock）
- `timex/timex_test.go` — 新建
- `timex/example_test.go` — 新建

## Requirements Covered

> Spec TC: TC-015

| Requirement | Description              | Acceptance Criteria    | TC |
| ----------- | ------------------------ | ---------------------- |    |
| FR-007      | 时钟抽象                 | 全部 WHEN/THEN 覆盖    |    |
| BR-012      | FakeClock 零值接收者安全 | 防止测试中的 nil panic |    |

## Non-scope

- 不包含 Timer/Ticker 抽象（可在后续版本扩展）
- 不包含时区处理

## Test Plan

| TC     | Type   | Description                          |
| ------ | ------ | ------------------------------------ |
| TC-015 | Unit   | FakeClock Advance(d) 后 Now() 前进 d |

## Implementation Notes

- Clock 接口只包含 `Now() time.Time` 单一方法
- FixedClock 是值类型，通过 `NewFixedClock(now)` 构造
- FakeClock 是指针类型，内部使用 mutex 保护并发访问
- FakeClock.Advance 只接受正 duration
