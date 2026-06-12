# TASK-KERNEL-015a

> examples/ Group A：lifecycx / errx / healthx / obsx 可运行示例

---

```yaml
task_id: TASK-KERNEL-015a
module: kernel
scope: "创建 examples/ 目录下 4 个子包的可运行示例程序（Group A）"
parent: TASK-KERNEL-015
spec_ref:
  - "module/kernel/SPEC.md#FR-001"
  - "module/kernel/SPEC.md#FR-002"
  - "module/kernel/SPEC.md#FR-003"
  - "module/kernel/SPEC.md#FR-004"
files:
  - "examples/lifecycle/main.go"
  - "examples/error_kind/main.go"
  - "examples/health_checker/main.go"
  - "examples/observability/main.go"
acceptance_criteria:
  - "AC-EXAMPLES-A01: 4 个示例程序均可 go run 运行"
  - "AC-EXAMPLES-A02: 输出稳定无随机值（使用 FixedClock）"
depends_on:
  - "TASK-KERNEL-001"
  - "TASK-KERNEL-003"
  - "TASK-KERNEL-005"
  - "TASK-KERNEL-011"
estimated_effort: "0.75h"
priority: P2
status: pending
```

---

## Requirements Covered

| FR | 子包 | 示例内容 |
|----|------|----------|
| FR-001 | lifecycx | Component 注册/启动/停止完整流程 |
| FR-002 | errx | Error 构造 + IsKind 分类判断 |
| FR-003 | healthx | HealthChecker 实现 + Aggregate 聚合 |
| FR-004 | obsx | NoopLogger 注入 + SecretString 脱敏 |

## Non-scope

- 不依赖 L1 模块（configx/observex 等）
- 不使用真实 API key
- 不输出随机时间戳（使用 FixedClock）

## Test Plan

| TC | Type | Description |
|----|------|-------------|
| — | CI | `for d in examples/{lifecycle,error_kind,health_checker,observability}/; do go run ./$d; done` 全部通过 |
