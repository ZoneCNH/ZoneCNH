# TASK-KERNEL-010

> contextx 子包：类型安全上下文工具

---

```yaml
task_id: TASK-KERNEL-010
module: kernel
scope: "实现 contextx 子包：Key[T]、WithValue、Value、HasDeadline、DeadlineRemaining、IsDone、CancelCause"
spec_ref:
  - "module/kernel/SPEC.md#FR-010"
  - "module/kernel/SPEC.md#BR-010"
  - "module/kernel/SPEC.md#9.10"
files:
  - "contextx/contextx.go"
  - "contextx/contextx_test.go"
  - "contextx/example_test.go"
acceptance_criteria:
  - "AC-014: Key 唯一性，类型安全存取，零值 Key panic"
  - "AC-CONTEXTX-01: NewKey 同名字不同调用返回不同 Key"
  - "AC-CONTEXTX-02: Value 类型匹配返回 (value, true)，不匹配返回 (zero, false)"
  - "AC-CONTEXTX-03: 零值 Key 调用 contextKey() panic"
  - "AC-CONTEXTX-04: HasDeadline/DeadlineRemaining/IsDone/CancelCause 行为正确"
  - "AC-CONTEXTX-05: DeadlineRemaining 已过期返回 (0, true)"
  - "AC-CONTEXTX-06: go test -race -count=1 ./contextx/... 通过"
depends_on:
  - "TASK-KERNEL-000"
  - "TASK-KERNEL-002"
estimated_effort: "1.5h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description |
|---|---|
| FR-010 | 类型安全上下文 |
| BR-010 | Key 必须通过 NewKey 创建，零值使用 panic |

## Internal Dependencies

- `timex` — DeadlineRemaining 接受 timex.Clock 实现可测试性

## Non-scope

- 不使用 context.WithValue 裸 API（必须通过 Key[T]）
- 不实现 context 替代方案（仅做类型安全包装）

## Implementation Notes

- Key[T] 基于 sentinel 指针实现唯一性
- Value 返回 (T, bool)，零分配
- contextKey() 检查零值 Key 并 panic
