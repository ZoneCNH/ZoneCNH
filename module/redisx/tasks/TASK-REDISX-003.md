# TASK-REDISX-003

> CacheClient 与 Codec 错误路径

---

```yaml
task_id: TASK-REDISX-003
module: redisx
scope: "实现 CacheClient cache-aside、null-cache、防击穿合并、TTL jitter 与 Codec 错误分类。"
spec_ref:
  - "module/redisx/SPEC.md#FR-005"
  - "module/redisx/SPEC.md#FR-011"
  - "module/redisx/SPEC.md#BR-004"
  - "module/redisx/SPEC.md#BR-007"
files:
  - "cache.go"
  - "cache_policy.go"
  - "cache_test.go"
  - "cache_concurrency_test.go"
  - "testutil_test.go"
acceptance_criteria:
  - "AC-005-1: CacheClient 覆盖 hit、miss、loader error、null-cache、防击穿和 Codec 错误。"
  - "AC-011-1: 默认 JSON、自定义 Codec、Encode/Decode 错误和错误脱敏有测试。"
  - "AC-BR-004: 默认 TTL、显式 no-expire 和 jitter 语义被区分。"
  - "AC-BR-007: 错误包装和 hook payload 不包含敏感值。"
non_scope:
  - "不编辑 module/redisx/SPEC.md、TRACEABILITY.md 或 goal.md。"
  - "不新增 configx、observex、resiliencx、contracts 或业务域模块的直接运行时依赖。"
  - "不实现 FR-005/FR-011 之外的缓存或序列化能力。"
test_plan:
  - "TC-005-1: Cache hit/miss/null-cache/GetOrLoad 防击穿。"
  - "TC-011-1: JSON Codec、自定义 Codec、Encode/Decode 错误。"
  - "TC-BR-004: TTL 默认、显式无过期和 jitter。"
  - "TC-BR-007: 错误脱敏与分类。"
depends_on:
  - "TASK-REDISX-000"
  - "TASK-REDISX-002"
estimated_effort: "1d"
priority: P0
status: pending
```

---

## Purpose

交付面向业务读路径的缓存客户端，同时保持 redisx 的基础设施边界：调用方通过 typed Options 和 Codec 注入策略，redisx 不读取配置中心、不暴露完整 Key、不承担业务缓存模型。

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
| --- | --- | --- |
| FR-005 | CacheClient cache-aside、null-cache、防击穿 | AC-005-1 |
| FR-011 | JSON 默认 Codec 与自定义 Codec SPI | AC-011-1 |
| BR-004 | TTL 默认策略、jitter 与无意永不过期防护 | AC-BR-004 |
| BR-007 | 错误分类与敏感信息脱敏 | AC-BR-007 |

## Scope

- 实现 `CacheClient.GetOrLoad`、`Set`、`Invalidate` 的最小公开契约。
- 支持默认 TTL、显式 no-expire、TTL jitter 和 null-cache 策略。
- 对同一进程内相同 Key 的 miss loader 进行合并，避免热点击穿。
- 覆盖 Codec encode/decode 失败、loader error、context cancellation 和错误脱敏。

## Non-Scope

- 不接入分布式 singleflight、跨进程锁或上层业务防护。
- 不把 observability、retry 或 circuit breaker 绑定到外部模块。
- 不改变 KeyBuilder、KV、Pipeline 或 Locker 的公开接口。

## Files

| File | Purpose |
| --- | --- |
| `cache.go` | CacheClient 公开 API 与 GetOrLoad 流程 |
| `cache_policy.go` | TTL、jitter、null-cache 策略 |
| `cache_test.go` | hit/miss/null-cache/Codec 错误测试 |
| `cache_concurrency_test.go` | 防击穿合并和并发测试 |
| `testutil_test.go` | Redis 测试夹具与断言工具 |

## Test Plan

| Test Case | Type | Description | Same-task test file |
| --- | --- | --- | --- |
| TC-005-1 | Unit/Integration | Cache hit、miss、loader error、null-cache、GetOrLoad 防击穿。 | `cache_test.go`, `cache_concurrency_test.go` |
| TC-011-1 | Unit | JSON Codec、自定义 Codec、Encode/Decode 错误。 | `cache_test.go` |
| TC-BR-004 | Unit/Integration | 默认 TTL、显式 no-expire 和 jitter 被区分。 | `cache_test.go` |
| TC-BR-007 | Unit/Static | 错误分类与脱敏不泄露完整 Key。 | `cache_test.go` |

## Implementation Notes

- 生产直接 import 限定为 stdlib、kernel 和 Redis client library。
- Cache 错误必须复用 module 级错误分类，不把 Redis 连接串、完整 Key 或凭据写入错误文本。
- 防击穿合并只承诺进程内行为，跨进程协调留给 Locker 或上层 adapter。

## Done Evidence

- `go test ./...` 通过。
- `rg -n "configx|observex|resiliencx|contracts" -- *.go` 未发现生产直接依赖。
- TC-005-1、TC-011-1、TC-BR-004、TC-BR-007 在同任务测试文件中有可追溯断言。
