# TASK-REDISX-004

> Hash/List 与 Pub/Sub 最小封装

---

```yaml
task_id: TASK-REDISX-004
module: redisx
scope: "实现 Hash/List 最小结构操作以及 Publish/Subscribe 生命周期语义。"
spec_ref:
  - "module/redisx/SPEC.md#FR-006"
  - "module/redisx/SPEC.md#FR-007"
  - "module/redisx/SPEC.md#BR-003"
files:
  - "structures.go"
  - "pubsub.go"
  - "structures_test.go"
  - "pubsub_test.go"
  - "testutil_test.go"
acceptance_criteria:
  - "AC-006-1: Hash/List 覆盖写入、读取、缺失、范围和 context 取消。"
  - "AC-007-1: Pub/Sub 覆盖发布、接收、取消、连接失败和资源释放。"
  - "AC-BR-003: 关键操作覆盖 context cancel/deadline 测试。"
non_scope:
  - "不编辑 module/redisx/SPEC.md、TRACEABILITY.md 或 goal.md。"
  - "不新增 configx、observex、resiliencx、contracts 或业务域模块的直接运行时依赖。"
  - "不实现完整 Redis 数据结构 API，仅实现 FR-006/FR-007 的最小封装。"
test_plan:
  - "TC-006-1: Hash/List 写入、读取、缺失和取消。"
  - "TC-007-1: Publish/Subscribe、取消、失败事件、资源释放。"
  - "TC-BR-003: 网络操作 context cancel/deadline。"
depends_on:
  - "TASK-REDISX-000"
  - "TASK-REDISX-001"
estimated_effort: "1d"
priority: P0
status: pending
```

---

## Purpose

补齐 Redis 结构化访问和订阅场景的最小稳定语义，使调用方无需直接操作底层 Redis client，同时所有网络调用仍受 context、KeyBuilder 与错误模型约束。

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
| --- | --- | --- |
| FR-006 | Hash/List 最小封装 | AC-006-1 |
| FR-007 | Pub/Sub Publish/Subscribe | AC-007-1 |
| BR-003 | 所有网络操作尊重 context | AC-BR-003 |

## Scope

- 实现 `HGet/HSet`、`LPush/LRange` 的最小语义。
- missing field/key 必须返回可识别状态或空结果，不把 Redis nil 混淆为未知错误。
- 实现 `Publish` 与 `Subscribe`，订阅必须响应 context cancellation 并释放资源。
- Pub/Sub 连接失败或重连失败通过错误事件路径表达。

## Non-Scope

- 不实现 stream、sorted set、set、scan 或事务语义。
- 不提供跨服务消息协议、schema registry 或业务事件模型。
- 不直接接入 observex/resiliencx；相关事件只通过本地 hook 暴露。

## Files

| File | Purpose |
| --- | --- |
| `structures.go` | Hash/List 公开 API |
| `pubsub.go` | Publish/Subscribe 与消息事件 |
| `structures_test.go` | Hash/List 行为和 context 测试 |
| `pubsub_test.go` | Pub/Sub 生命周期和失败路径测试 |
| `testutil_test.go` | Redis 测试夹具与取消辅助 |

## Test Plan

| Test Case | Type | Description | Same-task test file |
| --- | --- | --- | --- |
| TC-006-1 | Integration | Hash/List 写入、读取、缺失、范围和 context 取消。 | `structures_test.go` |
| TC-007-1 | Integration | Publish/Subscribe、取消、连接失败和资源释放。 | `pubsub_test.go` |
| TC-BR-003 | Unit/Integration | 网络操作尊重 context cancel/deadline。 | `structures_test.go`, `pubsub_test.go` |

## Implementation Notes

- 每个 Redis 调用必须接收调用方传入的 `context.Context`。
- Subscribe 返回的事件不得携带完整连接串或完整 Key。
- 测试必须验证取消后 goroutine、订阅和连接资源可释放。

## Done Evidence

- `go test ./...` 通过。
- TC-006-1、TC-007-1、TC-BR-003 均在同任务测试文件中实现。
- 生产代码没有新增禁止依赖。
