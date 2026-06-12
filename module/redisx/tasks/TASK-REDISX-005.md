# TASK-REDISX-005

> Pipeline 有序非原子批量执行

---

```yaml
task_id: TASK-REDISX-005
module: redisx
scope: "实现 Pipeline 命令队列、单次批量提交、有序结果和部分错误诊断。"
spec_ref:
  - "module/redisx/SPEC.md#FR-008"
  - "module/redisx/SPEC.md#BR-006"
  - "module/redisx/SPEC.md#BR-003"
files:
  - "pipeline.go"
  - "pipeline_result.go"
  - "pipeline_test.go"
  - "pipeline_context_test.go"
  - "testutil_test.go"
acceptance_criteria:
  - "AC-008-1: Pipeline 覆盖有序结果、部分错误、context 取消和非原子语义文档。"
  - "AC-BR-006: 文档和测试覆盖非原子与部分错误。"
  - "AC-BR-003: 关键操作覆盖 context cancel/deadline 测试。"
non_scope:
  - "不编辑 module/redisx/SPEC.md、TRACEABILITY.md 或 goal.md。"
  - "不新增 configx、observex、resiliencx、contracts 或业务域模块的直接运行时依赖。"
  - "不实现 Redis transaction/watch/multi 的原子事务封装。"
test_plan:
  - "TC-008-1: Pipeline 有序结果、部分错误、非原子语义。"
  - "TC-BR-006: Pipeline 部分失败与非原子语义。"
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

为高频 Redis 调用提供非原子的批量提交能力，并用稳定结果结构保留排队顺序、成功结果和第一个错误，避免调用方误以为 Pipeline 具备事务语义。

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
| --- | --- | --- |
| FR-008 | Pipeline 有序批量执行 | AC-008-1 |
| BR-006 | Pipeline 有序、非原子、部分错误可诊断 | AC-BR-006 |
| BR-003 | 所有网络操作尊重 context | AC-BR-003 |

## Scope

- 实现 Pipeline 创建、命令排队和 `Exec(ctx)`。
- `Exec` 返回与排队顺序一致的结果集合。
- 当部分命令失败时，保留成功结果并返回第一个可分类错误。
- 文档和测试明确 Pipeline 非原子，不替代事务。

## Non-Scope

- 不实现 Lua 脚本批处理、事务、watch/multi 或跨 key 原子性。
- 不改变 KV、Cache、Locker 的公开接口。
- 不引入业务批处理协议。

## Files

| File | Purpose |
| --- | --- |
| `pipeline.go` | Pipeline API、命令排队和 Exec |
| `pipeline_result.go` | 有序结果与错误结构 |
| `pipeline_test.go` | 有序、部分错误和非原子语义测试 |
| `pipeline_context_test.go` | context cancel/deadline 测试 |
| `testutil_test.go` | Redis 测试夹具 |

## Test Plan

| Test Case | Type | Description | Same-task test file |
| --- | --- | --- | --- |
| TC-008-1 | Integration | Pipeline 有序结果、部分错误、非原子语义。 | `pipeline_test.go` |
| TC-BR-006 | Integration | 部分失败返回有序结果和第一个错误。 | `pipeline_test.go` |
| TC-BR-003 | Unit/Integration | Exec 尊重 context cancel/deadline。 | `pipeline_context_test.go` |

## Implementation Notes

- Pipeline 错误必须复用 redisx 错误分类。
- 文档注释必须写明非原子语义，避免调用方误用作事务。
- 结果结构不得泄露完整 Key。

## Done Evidence

- `go test ./...` 通过。
- TC-008-1、TC-BR-006、TC-BR-003 可追溯到同任务测试文件。
- Pipeline 文档包含非原子声明。
