# TASK-REDISX-003

> Client 实现：HGet/HSet/LPush/LRange

---

```yaml
task_id: TASK-REDISX-003
module: redisx
scope: "实现 Client 接口的 Hash 和 List 操作（FR-006、FR-007）"
spec_ref:
  - "module/redisx/SPEC.md#FR-006"
  - "module/redisx/SPEC.md#FR-007"
files:
  - "client_impl.go"
  - "client_impl_test.go"
acceptance_criteria:
  - "HGet/HSet 操作 Hash 字段正确"
  - "LPush/LRange 操作 List 正确"
depends_on:
  - "TASK-REDISX-002"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-006 | HGet/HSet：Hash 操作 | 字段读写正确 |
| FR-007 | LPush/LRange：List 操作 | 列表读写正确 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | Unit | HSet 后 HGet 返回正确值 |
| — | Unit | LPush 后 LRange 返回正确列表 |

## Implementation Notes

- Hash 和 List 操作直接包装 redis 命令

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `HGet`/`HSet` | `client_impl.go` | Hash 测试通过 |
| 2 | 实现 `LPush`/`LRange` | `client_impl.go` | List 测试通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 无 | Low | Low | — |
