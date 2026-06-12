# TASK-KERNEL-012

> contracttest 子包：契约测试辅助断言

---

```yaml
task_id: TASK-KERNEL-012
module: kernel
scope: "实现 contracttest 子包：AssertJSONFields、AssertErrorKind、AssertHealthStatus"
spec_ref:
  - "module/kernel/SPEC.md#FR-012"
  - "module/kernel/SPEC.md#9.12"
files:
  - "contracttest/contracttest.go"
  - "contracttest/contracttest_test.go"
  - "contracttest/example_test.go"
acceptance_criteria:
  - "AC-017: 断言函数在匹配/不匹配时行为正确"
  - "AC-CONTRACTTEST-01: AssertJSONFields 字段存在时通过，缺失时 Fatalf"
  - "AC-CONTRACTTEST-02: AssertErrorKind 匹配时通过，不匹配时 Fatalf"
  - "AC-CONTRACTTEST-03: AssertHealthStatus status 匹配时通过"
  - "AC-CONTRACTTEST-04: go test -race -count=1 ./contracttest/... 通过"
depends_on:
  - "TASK-KERNEL-001"
  - "TASK-KERNEL-011"
estimated_effort: "1h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description |
|---|---|
| FR-012 | 契约测试辅助 |

## Internal Dependencies

- `errx` — AssertErrorKind 依赖 ErrorKind 类型
- `healthx` — AssertHealthStatus 依赖 HealthStatusValue 类型

## Non-scope

- 不依赖 testify 等第三方断言库
- 不在断言通过时产生任何输出

## Implementation Notes

- 所有函数接受 `testing.TB` 接口（兼容 *testing.T 和 *testing.B）
- 断言失败调用 `t.Fatalf`
