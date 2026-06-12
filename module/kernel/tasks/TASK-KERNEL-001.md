# TASK-KERNEL-001

> errx 子包：结构化错误模型

---

```yaml
task_id: TASK-KERNEL-001
module: kernel
scope: "实现 errx 子包：ErrorKind/Severity 类型、Error 结构体、NewError/WrapError/IsKind/AsError"
spec_ref:
  - "module/kernel/SPEC.md#FR-002"
  - "module/kernel/SPEC.md#BR-004"
  - "module/kernel/SPEC.md#BR-005"
  - "module/kernel/SPEC.md#9.2"
  - "module/kernel/SPEC.md#10.1"
files:
  - "errx/errx.go"
  - "errx/errx_test.go"
  - "errx/example_test.go"
acceptance_criteria:
  - "AC-003: NewError/WrapError 字段完整，Error() 格式正确"
  - "AC-004: Unwrap/IsKind/AsError 全链路正确，errors.Join 多错误链通过 IsKind"
  - "AC-ERRX-01: 12 个 ErrorKind 预定义值全部可用"
  - "AC-ERRX-02: 4 个 Severity 预定义值全部可用"
  - "AC-ERRX-03: WithRetryable/WithCode/WithSeverity 链式调用正确"
  - "AC-ERRX-04: nil *Error 方法安全返回零值"
  - "AC-ERRX-05: errors.Join 多错误链 walkErrors 遍历所有分支"
  - "AC-ERRX-06: go test -race -count=1 ./errx/... 通过"
depends_on:
  - "TASK-KERNEL-000"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Files Likely to Change

- `errx/errx.go` — 新建（ErrorKind、Severity、Error、NewError、WrapError、IsKind、AsError、ShouldRetry）
- `errx/errx_test.go` — 新建（覆盖所有 FR-002 WHEN/THEN）
- `errx/example_test.go` — 新建

## Requirements Covered

> Spec TC: TC-004, TC-005

| Requirement | Description                                      | Acceptance Criteria    | TC |
| ----------- | ------------------------------------------------ | ---------------------- |    |
| FR-002      | 结构化错误                                       | 全部 WHEN/THEN 覆盖    |    |
| BR-004      | Error 必须实现 error、Unwrap 接口                | errors.Is/As 可用      |    |
| BR-005      | IsKind/ShouldRetry 必须支持 errors.Join 多错误链 | 组合错误不丢失分类能力 |    |

## Non-scope

- 不依赖其他 kernel 子包（errx 是纯 stdlib）
- 不实现错误序列化/反序列化（由调用方决定）

## Test Plan

| TC     | Type   | Description                         |
| ------ | ------ | ----------------------------------- |
| TC-004 | Unit   | 错误链遍历：IsKind 穿透双层 wrap    |
| TC-005 | Unit   | errors.Join 多链：IsKind 匹配任一条 |

## Implementation Notes

- Error 实现 `Unwrap() error` 接口
- walkErrors 函数支持 `Unwrap() []error`（errors.Join 返回类型）
- Error.Error() 格式：`"<kind>: <op>: <message>"` 或 `"<kind>/<code>: <op>: <message>"`
- nil *Error 调用任何方法安全返回零值或 nil
- 使用 `sync.Once` 或直接检查 nil 保护 walkErrors 路径
