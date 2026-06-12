# TASK-KERNEL-015

> examples/ 示例程序组（拆分为 015a/015b/015c，每组 ≤ 4 文件）

---

```yaml
task_id: TASK-KERNEL-015
module: kernel
scope: "创建 examples/ 目录下 12 个子包的可运行示例（已拆分为 3 个子任务）"
type: meta
spec_ref:
  - "module/kernel/SPEC.md#7"
  - "FR: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012 (全部由子任务覆盖)"
sub_tasks:
  - "module/kernel/tasks/TASK-KERNEL-015a.md"
  - "module/kernel/tasks/TASK-KERNEL-015b.md"
  - "module/kernel/tasks/TASK-KERNEL-015c.md"
acceptance_criteria:
  - "AC-EXAMPLES-01: 12 个示例程序均可 go run 运行"
  - "AC-EXAMPLES-02: 输出稳定无随机值"
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

## 拆分方案（符合 ≤ 5 文件约束）

| Sub-task         | 文件数   | 覆盖子包                                    |
| ---------------- | :------: | ------------------------------------------- |
| TASK-KERNEL-015a | 4        | lifecycx / errx / healthx / obsx            |
| TASK-KERNEL-015b | 4        | retryx / shutdownx / syncx / timex          |
| TASK-KERNEL-015c | 4        | validx / versionx / contextx / contracttest |

## Non-scope

- 不依赖 L1 模块
- 不使用真实 API key
