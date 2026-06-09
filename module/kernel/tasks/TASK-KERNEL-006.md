# TASK-KERNEL-006

> 健康检查：HealthStatus、ModuleHealth、幂等无副作用

---

```yaml
task_id: TASK-KERNEL-006
module: kernel
scope: "实现 ModuleHealth 方法，查询已注册模块的 HealthStatus，幂等无副作用"
spec_ref:
  - "module/kernel/SPEC.md#FR-004"
  - "module/kernel/SPEC.md#BR-005"
files:
  - "health.go"
  - "health_test.go"
acceptance_criteria:
  - "AC-005: ModuleHealth 多次调用返回相同结果，不触发副作用"
  - "AC-NEW-34: ModuleHealth(\"unknown\") 返回 ErrModuleNotFound"
  - "AC-NEW-35: Running 模块返回正确 HealthStatus"
  - "AC-NEW-36: 未 Run 时 ModuleHealth 返回 HealthStatus{Ready: false, Live: false}"
depends_on:
  - "TASK-KERNEL-001"
  - "TASK-KERNEL-003"
estimated_effort: "1.5h"
priority: P0
status: pending
```

---

## Files Likely to Change

- `health.go` — 新建
- `health_test.go` — 新建

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-004 | ModuleHealth：查询已注册/未注册模块健康状态 | 2 个 WHEN/THEN 场景 |
| BR-005 | Health(ctx) 必须幂等、无副作用 | 多次调用返回相同结果 |

## Non-scope

- 不实现启动/停止逻辑（→ TASK-KERNEL-004, 005）
- 不实现依赖图（→ TASK-KERNEL-002）
- 不实现注册表（→ TASK-KERNEL-003）

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| TC-007 | Unit | 模块未找到：ModuleHealth("unknown") 返回 ErrModuleNotFound |
| TC-009 | Unit | 模块健康查询：Running 模块返回正确 HealthStatus 且无副作用 |
| TC-013 | Unit | Health before Run：返回 HealthStatus{Ready: false, Live: false} |
| — | Unit | 幂等性：连续调用 3 次 ModuleHealth 返回相同结果 |

## Implementation Notes

- ModuleHealth 内部从 registry 获取模块，调用其 `Health(ctx)` 方法
- 未运行状态下不调用模块的 Health 方法，直接返回默认值
- 使用 `errors.Is` 判断 ErrModuleNotFound
- HealthStatus 是值类型，返回副本

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 ModuleHealth 方法：从 registry 获取模块，未运行返回默认 HealthStatus | `health.go` | TC-013 通过 |
| 2 | 实现运行中查询：调用模块的 Health(ctx) 方法，返回结果副本 | `health.go` | TC-009 通过 |
| 3 | 实现 ErrModuleNotFound：模块名不在 registry 中返回错误 | `health.go` | TC-007 通过 |
| 4 | 编写幂等性测试：连续调用 3 次返回相同结果 | `health_test.go` | `go test ./... -run TestHealthIdempotent` 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Health 方法有副作用 | Low | High | SPEC BR-005 要求幂等无副作用，用测试验证 |
| 未运行时调用模块 Health | Low | Medium | 先检查 app 状态再决定是否调用 |
