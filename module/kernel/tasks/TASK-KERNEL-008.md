# TASK-KERNEL-008

> validx 子包：前置条件与不变量校验

---

```yaml
task_id: TASK-KERNEL-008
module: kernel
scope: "实现 validx 子包：Precondition、Invariant、RequireNonEmpty"
spec_ref:
  - "module/kernel/SPEC.md#FR-008"
  - "module/kernel/SPEC.md#9.8"
files:
  - "validx/validx.go"
  - "validx/validx_test.go"
  - "validx/example_test.go"
acceptance_criteria:
  - "AC-012: Precondition/Invariant/RequireNonEmpty 返回正确的 *Error（kind/op/message）"
  - "AC-VALIDX-01: Precondition(true) 返回 nil，Precondition(false) 返回 ErrorKindValidation + Warning"
  - "AC-VALIDX-02: Invariant(true) 返回 nil，Invariant(false) 返回 ErrorKindInternal + Error"
  - "AC-VALIDX-03: RequireNonEmpty 空值返回 Precondition 错误，非空返回 nil"
  - "AC-VALIDX-04: go test -race -count=1 ./validx/... 通过"
depends_on:
  - "TASK-KERNEL-000"
  - "TASK-KERNEL-001"
estimated_effort: "1h"
priority: P0
status: pending
```

---

## Files Likely to Change

- `validx/validx.go` — 新建（Precondition/Invariant/RequireNonEmpty）
- `validx/validx_test.go` — 新建
- `validx/example_test.go` — 新建

## Requirements Covered

> Spec TC: TC-011

| Requirement | Description  |
| ----------- | ------------ |
| FR-008      | 前置条件校验 |

## Internal Dependencies

- `errx` — 返回 `*errx.Error` 类型错误

## Non-scope

- 不引入断言宏/panic 行为（始终返回 error）
- 不校验复杂业务规则（仅做前置条件检查）

## Test Plan

| TC     | Type   | Description                              |
| ------ | ------ | ---------------------------------------- |
| TC-011 | Unit   | RequireNonEmpty 空值返回 validation 错误 |

## Implementation Notes

- Precondition 失败返回 `ErrorKindValidation + SeverityWarning`
- Invariant 失败返回 `ErrorKindInternal + SeverityError`
- RequireNonEmpty 封装 Precondition，消息格式 `"<name> must not be empty"`
