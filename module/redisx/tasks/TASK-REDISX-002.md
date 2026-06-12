# TASK-REDISX-002

> KV operations, Exists, Expire, TTL, context, and default TTL policy.

---

```yaml
task_id: TASK-REDISX-002
module: redisx
scope: "Implement Get/Set/Del/Exists/Expire/TTL with context-aware Redis calls, Codec use, ErrNotFound mapping, idempotent delete, and default TTL/jitter behavior."
spec_ref:
  - "module/redisx/SPEC.md#FR-003"
  - "module/redisx/SPEC.md#FR-004"
  - "module/redisx/SPEC.md#BR-003"
  - "module/redisx/SPEC.md#BR-004"
files:
  - "client.go"
  - "kv.go"
  - "ttl.go"
  - "kv_test.go"
  - "ttl_test.go"
acceptance_criteria:
  - "AC-003-1: Get/Set/Del cover existing keys, missing keys, Codec failures, context cancellation, and idempotent delete."
  - "AC-004-1: Exists/Expire/TTL/default TTL/jitter are implemented and tested without accidental no-expire cache writes."
  - "AC-BR-003: All Redis network operations in this task accept and honor context."
  - "AC-BR-004: TTL semantics distinguish explicit no-expire from default cache TTL."
non_scope:
  - "Do not implement CacheClient, Hash/List, Pub/Sub, Pipeline, Locker, Counter, RateLimitHelper, or Health."
  - "Do not introduce retry, circuit breaker, config, or observability dependencies."
  - "Do not accept raw string keys where a validated Key is required."
test_plan:
  - "TC-003-1: Unit/integration tests cover Set/Get/Del, ErrNotFound, Codec errors, and context cancellation."
  - "TC-004-1: Unit/integration tests cover Exists, Expire, TTL, default TTL, explicit no-expire, and jitter."
  - "TC-BR-003: Cancellation/deadline tests cover every network method touched by this task."
  - "TC-BR-004: TTL policy tests prove cache writes do not silently persist forever."
depends_on:
  - "TASK-REDISX-000"
  - "TASK-REDISX-001"
estimated_effort: "1d"
priority: P0
status: pending
```

---

## Purpose

Implement the core Redis KV and TTL surface used by later cache, counter, and health behavior.

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
| --- | --- | --- |
| FR-003 | KV Get/Set/Del | AC-003-1 |
| FR-004 | Exists/Expire 与默认 TTL 策略 | AC-004-1 |
| BR-003 | 所有网络操作尊重 context | AC-BR-003 |
| BR-004 | TTL 默认策略、jitter 与无意永不过期防护 | AC-BR-004 |

## Scope

- Implement context-aware `Get`, `Set`, `Del`, `Exists`, `Expire`, and `TTL`.
- Map Redis nil to `ErrNotFound`.
- Apply Codec and TTL policy consistently.
- Add focused unit and integration tests.

## Non-Scope

- Do not implement cache-aside orchestration or singleflight behavior.
- Do not implement Redis data structures beyond KV and TTL commands.
- Do not add high-level resilience or observability integrations.

## Files

| File | Responsibility |
| --- | --- |
| `client.go` | Redis client wrapper and shared command execution |
| `kv.go` | Get/Set/Del/Exists implementation |
| `ttl.go` | Expire/TTL/default TTL/jitter policy |
| `kv_test.go` | KV behavior and errors |
| `ttl_test.go` | TTL policy behavior |

## Test Plan

| Test Case | Type | Same-task test file |
| --- | --- | --- |
| TC-003-1 | Unit/Integration | `kv_test.go` |
| TC-004-1 | Unit/Integration | `ttl_test.go` |
| TC-BR-003 | Unit/Integration | `kv_test.go`, `ttl_test.go` |
| TC-BR-004 | Unit/Integration | `ttl_test.go` |

## Implementation Notes

- All public methods must accept `context.Context`.
- Preserve `Key.Pattern` in all diagnostic paths.
- Treat Redis missing-key responses as `ErrNotFound`, not as dependency failures.

## Done Evidence

- `go test ./...`
- context cancellation test output
- `git diff --check`
