# TASK-REDISX-008

> Health、PoolStats、Hooks 与依赖守卫

---

```yaml
task_id: TASK-REDISX-008
module: redisx
scope: "实现 Health、pool stats、低基数 hook 事件和禁止依赖静态守卫。"
spec_ref:
  - "module/redisx/SPEC.md#16"
  - "module/redisx/SPEC.md#17"
test_cases:
  - "TC-001"
  - "TC-002"
  - "TC-003"
  - "TC-004"
  - "TC-005"
  - "TC-006"
  - "TC-007"
  - "TC-008"
  - "TC-009"
files:
  - "health.go"
  - "hooks.go"
  - "stats.go"
  - "observability_test.go"
  - "health_test.go"
acceptance_criteria:
  - "AC-012-1: Health、pool stats、hook 事件、指标名和低基数标签约束有测试。"
  - "AC-BR-008: hook 接口可表达 retry/reconnect/circuit 事件且无禁止依赖。"
  - "AC-BR-009: hook/metric 测试拒绝完整 Key 标签。"
  - "AC-BR-010: 静态依赖守卫禁止直接 import configx/observex/resiliencx/contracts。"
non_scope:
  - "不编辑 module/redisx/SPEC.md、TRACEABILITY.md 或 goal.md。"
  - "不新增 configx、observex、resiliencx、contracts 或业务域模块的直接运行时依赖。"
  - "不实现外部 metrics exporter、tracer、retry 或 circuit breaker。"
test_plan:
  - "TC-012-1: Health、PoolStats、HookEvent、指标名。"
  - "TC-BR-008: retry/reconnect/circuit 事件通过本地 hook 表达。"
  - "TC-BR-009: 指标低基数标签约束。"
  - "TC-BR-010: 禁止直接依赖 configx/observex/resiliencx/contracts。"
depends_on:
  - "TASK-REDISX-000"
  - "TASK-REDISX-001"
  - "TASK-REDISX-002"
  - "TASK-REDISX-005"
  - "TASK-REDISX-006"
estimated_effort: "1d"
priority: P0
status: pending
```

---

## Purpose

定义 redisx 对外暴露的健康检查、连接池状态和本地 hook 面，允许上层 adapter 接入 observex/resiliencx/contracts，同时 redisx 生产代码保持直接依赖边界。

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
| --- | --- | --- |
| FR-012 | Health、pool stats 与观测 hooks | AC-012-1 |
| BR-008 | 重试/重连/熔断只通过本地 hooks 接入 | AC-BR-008 |
| BR-009 | 指标命名和低基数标签约束 | AC-BR-009 |
| BR-010 | 依赖边界：stdlib/kernel/Redis client only | AC-BR-010 |

## Scope

- 实现 `Health(ctx)`，通过 PING 返回 live/ready/message。
- 暴露 pool active/idle 等低风险统计。
- 定义本地 HookEvent，表达 operation、status、error_code、client、key_pattern。
- 增加静态依赖守卫测试，禁止生产代码 import `configx/observex/resiliencx/contracts`。

## Non-Scope

- 不创建 metrics exporter、tracer provider 或 circuit breaker 实现。
- 不把 retry/reconnect/circuit 绑定到 resiliencx。
- 不泄露完整 Key、连接串、密码、token 或业务值。

## Files

| File | Purpose |
| --- | --- |
| `health.go` | Health API 与 PING 状态 |
| `hooks.go` | HookEvent、低基数字段和回调接口 |
| `stats.go` | PoolStats 投影 |
| `observability_test.go` | hook 标签、依赖守卫和脱敏测试 |
| `health_test.go` | 健康检查成功/失败测试 |

## Test Plan

| Test Case | Type        | Description    |
| --------- | ----------- | -------------- |
| TC-001 至 TC-009 | Integration | 全部操作端到端 |
| TC-001    | Benchmark   | Get/Set 延迟   |

## Non-Scope

- 不直接 import `configx`、`observex`、`resiliencx` 或 `contracts`。
- 不实现业务缓存模型、业务领域 DTO 或跨模块注册逻辑。
- 直接依赖边界保持为 `kernel` + Redis client library `github.com/redis/go-redis/v9`。

## Implementation Notes

- HookEvent 字段必须是低基数集合，不接受 raw key 或 connection string。
- `Health(ctx)` 必须尊重 context deadline。
- 依赖守卫只扫描生产 Go 文件，测试中的字符串 fixture 需避免误报。

## Done Evidence

- `go test ./...` 通过。
- TC-012-1、TC-BR-008、TC-BR-009、TC-BR-010 均有同任务测试证据。
- 静态依赖守卫证明生产直接依赖仅限 stdlib、kernel 和 Redis client library。
