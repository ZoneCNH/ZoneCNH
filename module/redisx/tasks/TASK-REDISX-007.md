# TASK-REDISX-007

> Counter 与 fixed-window RateLimitHelper

---

```yaml
task_id: TASK-REDISX-007
module: redisx
scope: "实现 Counter 与 fixed-window RateLimitHelper，保证原子计数、窗口 TTL 和剩余额度返回。"
spec_ref:
  - "module/redisx/SPEC.md#FR-012"
test_cases:
  - "TC-009"
files:
  - "counter.go"
  - "ratelimit.go"
  - "counter_test.go"
  - "ratelimit_test.go"
  - "testutil_test.go"
acceptance_criteria:
  - "AC-010-1: Counter 与 RateLimitHelper 覆盖原子计数、窗口过期、并发和剩余额度。"
  - "AC-BR-004: 默认 TTL、显式 no-expire 和 jitter 语义被区分。"
  - "AC-BR-003: 关键操作覆盖 context cancel/deadline 测试。"
non_scope:
  - "不编辑 module/redisx/SPEC.md、TRACEABILITY.md 或 goal.md。"
  - "不新增 configx、observex、resiliencx、contracts 或业务域模块的直接运行时依赖。"
  - "不实现滑动窗口、令牌桶、分布式配额管理或业务限流策略。"
test_plan:
  - "TC-010-1: Counter、RateLimit、并发、窗口 TTL。"
  - "TC-BR-004: TTL 默认、显式无过期和 jitter。"
  - "TC-BR-003: 网络操作 context cancel/deadline。"
depends_on:
  - "TASK-REDISX-000"
  - "TASK-REDISX-002"
estimated_effort: "1d"
priority: P0
status: pending
```

---

## Purpose

提供最小计数和固定窗口限流 helper，覆盖 Redis 原子自增、窗口过期和并发安全，避免调用方重复编写易错的 TTL/INCR 组合逻辑。

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
| --- | --- | --- |
| FR-010 | Counter 与 fixed-window RateLimitHelper | AC-010-1 |
| BR-004 | TTL 默认策略、jitter 与无意永不过期防护 | AC-BR-004 |
| BR-003 | 所有网络操作尊重 context | AC-BR-003 |

## Scope

- 实现 Counter 的 incr/add/get/reset 最小 API。
- 实现 fixed-window `Allow`，返回 allowed、remaining、resetAt。
- 首次计数必须设置窗口 TTL，避免无意永久 Key。
- 覆盖并发、过期、context cancel/deadline 和 TTL 策略。

## Non-Scope

- 不实现滑动窗口、令牌桶或漏桶。
- 不提供业务主体识别、租户配额或外部分布式协调。
- 不接入外部 metrics/retry/circuit 模块。

## Files

| File | Purpose |
| --- | --- |
| `counter.go` | Counter API 与原子计数 |
| `ratelimit.go` | fixed-window RateLimitHelper |
| `counter_test.go` | 计数、reset、过期测试 |
| `ratelimit_test.go` | Allow、remaining、resetAt 和并发测试 |
| `testutil_test.go` | Redis 测试夹具 |

## Test Plan

| Test Case | Type | Description           |
| --------- | ---- | --------------------- |
| TC-009    | Unit | PING 成功返回 healthy |

## Non-Scope

- 不直接 import `configx`、`observex`、`resiliencx` 或 `contracts`。
- 不实现业务缓存模型、业务领域 DTO 或跨模块注册逻辑。
- 直接依赖边界保持为 `kernel` + Redis client library `github.com/redis/go-redis/v9`。

## Implementation Notes

- 原子计数优先使用 Redis 原生命令或 Lua，不能以客户端 read-modify-write 实现。
- resetAt 必须来自窗口 TTL/时间计算，避免返回零值掩盖过期语义。
- 错误文本和 hook payload 必须使用 Key pattern，不使用完整 Key。

## Done Evidence

- `go test ./...` 通过。
- TC-010-1、TC-BR-004、TC-BR-003 均有同任务测试证据。
- 并发测试证明窗口内计数和剩余额度稳定。
