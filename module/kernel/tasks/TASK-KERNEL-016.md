# TASK-KERNEL-016

> docs/ + CHANGELOG + CI gates + Release preflight（拆分为 016a/016b/016c）

---

```yaml
task_id: TASK-KERNEL-016
module: kernel
scope: "完成 kernel 文档、CI 脚本、CHANGELOG、Release 预检（拆分为 3 个子任务）"
type: meta
spec_ref:
  - "module/kernel/SPEC.md#20"
  - "module/kernel/SPEC.md#22"
  - "module/kernel/SPEC.md#BR-009"
sub_tasks:
  - "module/kernel/tasks/TASK-KERNEL-016a.md"
  - "module/kernel/tasks/TASK-KERNEL-016b.md"
  - "module/kernel/tasks/TASK-KERNEL-016c.md"
acceptance_criteria:
  - "AC-018: stdlib-only gate 通过"
  - "AC-RELEASE-01: CHANGELOG.md 记录 v1.0.0"
  - "AC-RELEASE-02: make release-preflight 通过"
  - "AC-RELEASE-07: golangci-lint 无错误"
  - "AC-RELEASE-08: gitleaks 无泄露"
depends_on:
  - "TASK-KERNEL-014"
  - "TASK-KERNEL-015a"
  - "TASK-KERNEL-015b"
  - "TASK-KERNEL-015c"
estimated_effort: "2h"
priority: P1
status: pending
```

## 拆分方案（符合 ≤ 5 文件约束）

| Sub-task         | 文件数   | 覆盖内容                                                   |
| ---------------- | :------: | ---------------------------------------------------------- |
| TASK-KERNEL-016a | 5        | docs/adr + design + governance + spec + standard           |
| TASK-KERNEL-016b | 5        | scripts/ci + release/manifest + dependency + standard-sync |
| TASK-KERNEL-016c | 2        | CHANGELOG.md + Makefile release-preflight                  |

## Non-scope

- 不在 CHANGELOG 中包含未实现功能
- 不包含测试密钥或个人环境路径
