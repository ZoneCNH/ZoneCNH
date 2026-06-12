# TASK-KERNEL-015c

> examples/ Group C：validx / versionx / contextx / contracttest 可运行示例

---

```yaml
task_id: TASK-KERNEL-015c
module: kernel
scope: "创建 examples/ 目录下 4 个子包的可运行示例程序（Group C）"
parent: TASK-KERNEL-015
spec_ref:
  - "module/kernel/SPEC.md#FR-008"
  - "module/kernel/SPEC.md#FR-009"
  - "module/kernel/SPEC.md#FR-010"
  - "module/kernel/SPEC.md#FR-012"
files:
  - "examples/validation/main.go"
  - "examples/version_info/main.go"
  - "examples/context/main.go"
  - "examples/contract_helper/main.go"
acceptance_criteria:
  - "AC-EXAMPLES-C01: 4 个示例程序均可 go run 运行"
  - "AC-EXAMPLES-C02: 输出稳定无随机值"
depends_on:
  - "TASK-KERNEL-007"
  - "TASK-KERNEL-008"
  - "TASK-KERNEL-010"
  - "TASK-KERNEL-012"
estimated_effort: "0.75h"
priority: P2
status: pending
```

---

## Requirements Covered

| FR     | 子包         | 示例内容                    |
| ------ | ------------ | --------------------------- |
| FR-008 | validx       | Precondition/Invariant 使用 |
| FR-009 | versionx     | BuildInfo + Compatibility   |
| FR-010 | contextx     | Key 创建 + 类型安全存取     |
| FR-012 | contracttest | 断言函数使用                |

## Non-scope

- 不依赖 L1 模块
- 不使用真实 API key
- 不输出随机时间戳

## Test Plan

| TC   | Type   | Description                                                                                           |
| ---- | ------ | ----------------------------------------------------------------------------------------------------- |
| —    | CI     | `for d in examples/{validation,version_info,context,contract_helper}/; do go run ./$d; done` 全部通过 |
