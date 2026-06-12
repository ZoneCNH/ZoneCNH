# TASK-KERNEL-013

> internal/testutil：内部测试工具

---

```yaml
task_id: TASK-KERNEL-013
module: kernel
scope: "实现 internal/testutil 子包：RequireEqual 泛型断言"
spec_ref:
  - "module/kernel/SPEC.md#FR-011"
  - "module/kernel/SPEC.md#BR-011"
  - "module/kernel/SPEC.md#9.13"
files:
  - "internal/testutil/testutil.go"
  - "internal/testutil/testutil_test.go"
acceptance_criteria:
  - "AC-TESTUTIL-01: RequireEqual 匹配时通过，不匹配时 Fatalf"
  - "AC-TESTUTIL-02: go test -race -count=1 ./internal/testutil/... 通过"
depends_on:
  - "TASK-KERNEL-000"
estimated_effort: "0.5h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description |
|---|---|
| §9.13 | 内部测试工具接口 |

## Non-scope

- 不暴露给外部消费者（internal 包）

## Implementation Notes

- `RequireEqual[T comparable](t testing.TB, got T, want T)`
- 使用 generics 保证类型安全
