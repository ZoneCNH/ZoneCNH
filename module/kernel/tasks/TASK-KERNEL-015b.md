# TASK-KERNEL-015b

> examples/ Group B：retryx / shutdownx / syncx / timex 可运行示例

---

```yaml
task_id: TASK-KERNEL-015b
module: kernel
scope: "创建 examples/ 目录下 4 个子包的可运行示例程序（Group B）"
parent: TASK-KERNEL-015
spec_ref:
  - "module/kernel/SPEC.md#FR-005"
  - "module/kernel/SPEC.md#FR-006"
  - "module/kernel/SPEC.md#FR-007"
  - "module/kernel/SPEC.md#FR-011"
files:
  - "examples/retry_policy/main.go"
  - "examples/shutdown/main.go"
  - "examples/sync_group/main.go"
  - "examples/clock/main.go"
acceptance_criteria:
  - "AC-EXAMPLES-B01: 4 个示例程序均可 go run 运行"
  - "AC-EXAMPLES-B02: 输出稳定无随机值"
depends_on:
  - "TASK-KERNEL-002"
  - "TASK-KERNEL-004"
  - "TASK-KERNEL-006"
  - "TASK-KERNEL-009"
estimated_effort: "0.75h"
priority: P2
status: pending
```

---

## Requirements Covered

| FR     | 子包      | 示例内容                       |
| ------ | --------- | ------------------------------ |
| FR-005 | retryx    | RetryPolicy 配置 + Delay 计算  |
| FR-006 | shutdownx | Hook 注册 + OS signal 处理     |
| FR-011 | syncx     | SemaphoreLimiter + WorkerGroup |
| FR-007 | timex     | FakeClock 注入测试             |

## Non-scope

- 不依赖 L1 模块
- 不使用真实 API key
- 不输出随机时间戳

## Test Plan

| TC   | Type   | Description                                                                                  |
| ---- | ------ | -------------------------------------------------------------------------------------------- |
| —    | CI     | `for d in examples/{retry_policy,shutdown,sync_group,clock}/; do go run ./$d; done` 全部通过 |
