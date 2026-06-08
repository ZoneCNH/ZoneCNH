# TASK-REDISX-001

> 接口定义：Client、Locker、Pipeline

---

```yaml
task_id: TASK-REDISX-001
module: redisx
scope: "定义 Client、Locker、Pipeline 接口"
spec_ref:
  - "specs/redisx/SPEC.md#9"
files:
  - "client.go"
  - "locker.go"
  - "pipeline.go"
acceptance_criteria:
  - "Client 接口包含 Get/Set/Del/Exists/Expire/HGet/HSet/LPush/LRange/Subscribe 方法"
  - "Locker 接口包含 Acquire/Release 方法"
  - "Pipeline 接口方法签名正确"
  - "go build ./... 编译通过"
depends_on:
  - "TASK-REDISX-000"
estimated_effort: "1h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| §9 | 接口契约 | 所有接口签名与 SPEC 一致 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | Compile | 接口完整性编译验证 |

## Implementation Notes

- `Client` 接口封装所有 Redis 操作
- `Locker` 接口用于分布式锁
- `Pipeline` 接口用于批量操作

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 定义 `Client` 接口 | `client.go` | `go build ./...` 通过 |
| 2 | 定义 `Locker` 接口 | `locker.go` | `go build ./...` 通过 |
| 3 | 定义 `Pipeline` 接口 | `pipeline.go` | `go build ./...` 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 接口方法遗漏 | Low | Medium | 对照 SPEC §9 |
