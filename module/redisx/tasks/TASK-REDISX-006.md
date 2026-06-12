# TASK-REDISX-006

> Locker token owner 与 Lua guarded release

---

```yaml
task_id: TASK-REDISX-006
module: redisx
scope: "实现 Locker Acquire/Renew/Release，保证 holder token、TTL、续期和原子释放校验。"
spec_ref:
  - "module/redisx/SPEC.md#FR-009"
  - "module/redisx/SPEC.md#BR-005"
  - "module/redisx/SPEC.md#BR-007"
files:
  - "locker.go"
  - "lock_script.go"
  - "locker_test.go"
  - "lock_concurrency_test.go"
  - "testutil_test.go"
acceptance_criteria:
  - "AC-009-1: 锁竞争、TTL 到期、续期、误释放防护和 holder token 校验均通过。"
  - "AC-BR-005: token mismatch 时 Release 不删除锁。"
  - "AC-BR-007: 错误包装和 hook payload 不包含敏感值。"
non_scope:
  - "不编辑 module/redisx/SPEC.md、TRACEABILITY.md 或 goal.md。"
  - "不新增 configx、observex、resiliencx、contracts 或业务域模块的直接运行时依赖。"
  - "不实现 Redlock、多 Redis 节点仲裁或业务幂等协议。"
test_plan:
  - "TC-009-1: Lock acquire/renew/release、token mismatch、TTL。"
  - "TC-BR-005: Lock token owner 和 release guard。"
  - "TC-BR-007: 错误脱敏与分类。"
depends_on:
  - "TASK-REDISX-000"
  - "TASK-REDISX-001"
  - "TASK-REDISX-002"
estimated_effort: "1d"
priority: P0
status: pending
```

---

## Purpose

提供单 Redis 实例语义下的分布式锁基础能力，重点保证 holder token、TTL、续期和释放保护，而不是扩展为多节点一致性算法。

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
| --- | --- | --- |
| FR-009 | token owner 分布式锁 | AC-009-1 |
| BR-005 | Lock token owner、TTL、续期与释放校验 | AC-BR-005 |
| BR-007 | 错误分类与敏感信息脱敏 | AC-BR-007 |

## Scope

- 实现 `Locker.Acquire(ctx, key, token, ttl)`。
- 实现 `Locker.Renew(ctx, key, token, ttl)`。
- 实现 Lua guarded `Release(ctx, key, token)`，token mismatch 时不得删除锁。
- 覆盖竞争、TTL 到期、续期、context 取消和错误脱敏。

## Non-Scope

- 不实现 Redlock 或多 Redis quorum。
- 不保证业务操作幂等；业务幂等由调用方负责。
- 不引入 resiliencx 重试或熔断依赖。

## Files

| File | Purpose |
| --- | --- |
| `locker.go` | Locker API、Acquire/Renew/Release |
| `lock_script.go` | Lua guarded release/renew 脚本 |
| `locker_test.go` | TTL、续期和释放语义测试 |
| `lock_concurrency_test.go` | 竞争和 token mismatch 并发测试 |
| `testutil_test.go` | Redis 测试夹具 |

## Test Plan

| Test Case | Type | Description | Same-task test file |
| --- | --- | --- | --- |
| TC-009-1 | Concurrency/Integration | Lock acquire/renew/release、token mismatch、TTL。 | `locker_test.go`, `lock_concurrency_test.go` |
| TC-BR-005 | Concurrency | token mismatch 时 Release 不删除锁。 | `lock_concurrency_test.go` |
| TC-BR-007 | Unit/Static | 错误分类与脱敏不泄露完整 Key。 | `locker_test.go` |

## Implementation Notes

- Release 必须使用 Redis 端原子校验，不能用非原子 get-then-del。
- token 和 Key 不得写入日志、metrics label 或未脱敏错误。
- 续期只允许当前 holder token 成功。

## Done Evidence

- `go test ./...` 通过。
- TC-009-1、TC-BR-005、TC-BR-007 均有同任务测试证据。
- Lua release guard 有并发/误释放回归测试。
