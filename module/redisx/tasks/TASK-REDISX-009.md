# TASK-REDISX-009

> 集成、性能与发布证据

---

```yaml
task_id: TASK-REDISX-009
module: redisx
scope: "补齐真实 Redis 集成、benchmark、README、CHANGELOG 和发布 DoD 证据。"
spec_ref:
  - "module/redisx/SPEC.md#FR-012"
  - "module/redisx/SPEC.md#NFR-002"
  - "module/redisx/SPEC.md#NFR-003"
  - "module/redisx/SPEC.md#NFR-004"
files:
  - "integration_test.go"
  - "benchmark_test.go"
  - "README.md"
  - "CHANGELOG.md"
  - "example_test.go"
acceptance_criteria:
  - "AC-012-1: Health、pool stats、hook 事件、指标名和低基数标签约束有测试。"
  - "AC-NFR-002: 集成测试可用 REDIS_ADDR 或 test harness 开启，默认短测不阻塞。"
  - "AC-NFR-003: benchmark 结果记录在发布证据，超预算需说明。"
  - "AC-NFR-004: README 示例、CHANGELOG、DoD 证据和 task 链接完整。"
non_scope:
  - "不编辑 module/redisx/SPEC.md、TRACEABILITY.md 或 goal.md。"
  - "不新增 configx、observex、resiliencx、contracts 或业务域模块的直接运行时依赖。"
  - "不把可选真实 Redis 集成测试变成默认短测硬依赖。"
test_plan:
  - "TC-012-1: Health、PoolStats、HookEvent、指标名。"
  - "TC-NFR-002: 真实 Redis 集成、失败路径、并发路径。"
  - "TC-NFR-003: KV、Pipeline、Locker、RateLimit benchmark。"
  - "TC-NFR-004: README、CHANGELOG、发布 DoD 证据。"
depends_on:
  - "TASK-REDISX-000"
  - "TASK-REDISX-001"
  - "TASK-REDISX-002"
  - "TASK-REDISX-003"
  - "TASK-REDISX-004"
  - "TASK-REDISX-005"
  - "TASK-REDISX-006"
  - "TASK-REDISX-007"
  - "TASK-REDISX-008"
estimated_effort: "1d"
priority: P1
status: pending
```

---

## Purpose

把 redisx 从功能任务推进到可发布证据：真实 Redis 集成覆盖、性能预算记录、README 示例、CHANGELOG 和 DoD 链路必须可审查。

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
| --- | --- | --- |
| FR-012 | Health、pool stats 与观测 hooks | AC-012-1 |
| NFR-002 | 真实 Redis 集成、并发和失败路径测试 | AC-NFR-002 |
| NFR-003 | 性能基线与 benchmark 预算 | AC-NFR-003 |
| NFR-004 | README、配置参考、发布证据齐全 | AC-NFR-004 |

## Scope

- 增加 opt-in 真实 Redis 集成测试，覆盖成功、失败、并发和 context 取消路径。
- 增加 KV、Pipeline、Locker、RateLimit benchmark。
- 编写 README 示例、配置投影说明、依赖边界说明和任务链接。
- 编写 CHANGELOG/发布证据，记录 DoD、测试命令和 benchmark 结果位置。

## Non-Scope

- 不要求默认 `go test ./...` 启动外部 Redis。
- 不发布包版本、不打 tag、不改 GitHub Actions 之外的运行环境。
- 不新增外部依赖或容器编排系统。

## Files

| File | Purpose |
| --- | --- |
| `integration_test.go` | opt-in 真实 Redis 集成与失败路径测试 |
| `benchmark_test.go` | KV、Pipeline、Locker、RateLimit benchmark |
| `README.md` | 使用示例、配置投影和边界说明 |
| `CHANGELOG.md` | 发布说明与迁移记录 |
| `example_test.go` | 可编译示例 |

## Test Plan

| Test Case | Type | Description | Same-task test file |
| --- | --- | --- | --- |
| TC-012-1 | Unit/Integration | Health、PoolStats、HookEvent、指标名。 | `integration_test.go` |
| TC-NFR-002 | Integration | 真实 Redis 集成、失败路径、并发路径。 | `integration_test.go` |
| TC-NFR-003 | Benchmark | KV、Pipeline、Locker、RateLimit benchmark。 | `benchmark_test.go` |
| TC-NFR-004 | Documentation | README、CHANGELOG、发布 DoD 证据。 | `README.md`, `CHANGELOG.md`, `example_test.go` |

## Implementation Notes

- 集成测试默认在 `testing.Short()` 或无 `REDIS_ADDR` 时跳过，并在输出中说明跳过原因。
- README 必须说明直接生产依赖边界：stdlib、kernel、Redis client library。
- benchmark 预算引用 SPEC 的性能目标，超预算时在 CHANGELOG 或发布证据中记录说明。

## Done Evidence

- `go test ./...` 通过，且默认短测不依赖外部 Redis。
- `REDIS_ADDR=<addr> go test ./... -run Integration` 在可用 Redis 上通过。
- `go test ./... -bench . -run '^$'` 产出 KV、Pipeline、Locker、RateLimit benchmark。
- README、CHANGELOG 和 example_test.go 可追溯到 TC-NFR-004。
