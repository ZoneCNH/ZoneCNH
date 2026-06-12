# TASK-KERNEL-015

> examples/：12 子包可运行示例

---

```yaml
task_id: TASK-KERNEL-015
module: kernel
scope: "创建 examples/ 目录下 12 个子包对应的可运行示例程序"
spec_ref:
  - "module/kernel/SPEC.md#14"
files:
  - "examples/lifecycle/main.go"
  - "examples/error_kind/main.go"
  - "examples/health_checker/main.go"
  - "examples/observability/main.go"
  - "examples/retry_policy/main.go"
  - "examples/shutdown/main.go"
  - "examples/sync_group/main.go"
  - "examples/clock/main.go"
  - "examples/validation/main.go"
  - "examples/version_info/main.go"
  - "examples/context/main.go"
  - "examples/contract_helper/main.go"
acceptance_criteria:
  - "AC-EXAMPLES-01: 12 个示例程序均可 go run 运行"
  - "AC-EXAMPLES-02: 示例输出稳定（无随机值）"
depends_on:
  - "TASK-KERNEL-001"
  - "TASK-KERNEL-002"
  - "TASK-KERNEL-003"
  - "TASK-KERNEL-004"
  - "TASK-KERNEL-005"
  - "TASK-KERNEL-006"
  - "TASK-KERNEL-007"
  - "TASK-KERNEL-008"
  - "TASK-KERNEL-009"
  - "TASK-KERNEL-010"
  - "TASK-KERNEL-011"
  - "TASK-KERNEL-012"
estimated_effort: "2h"
priority: P2
status: pending
```

---

## Implementation Notes

- 每个示例放在独立目录（examples/<name>/main.go）
- 示例应可独立运行：`go run ./examples/lifecycle/`
- 输出稳定，用于 CI golden 对比
