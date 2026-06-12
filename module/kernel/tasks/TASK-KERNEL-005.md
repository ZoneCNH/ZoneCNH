# TASK-KERNEL-005

> lifecycx 子包：组件生命周期管理

---

```yaml
task_id: TASK-KERNEL-005
module: kernel
scope: "实现 lifecycx 子包：Component 接口、Manager 有序启动/逆序停止/失败回滚"
spec_ref:
  - "module/kernel/SPEC.md#FR-001"
  - "module/kernel/SPEC.md#BR-001"
  - "module/kernel/SPEC.md#BR-002"
  - "module/kernel/SPEC.md#BR-003"
  - "module/kernel/SPEC.md#9.1"
files:
  - "lifecycx/lifecycx.go"
  - "lifecycx/lifecycx_test.go"
  - "lifecycx/example_test.go"
acceptance_criteria:
  - "AC-001: Manager.Start 按序启动，失败回滚，Manager.Stop 幂等"
  - "AC-002: 启动失败时 errors.Join 包含所有已启动 Component 的 Stop 错误"
  - "AC-LIFECYCX-01: Manager.Start 无 Component 时返回 nil"
  - "AC-LIFECYCX-02: Manager.Stop 未 started 时返回 nil（幂等）"
  - "AC-LIFECYCX-03: Manager.Components() 返回防御性拷贝"
  - "AC-LIFECYCX-04: go test -race -count=1 ./lifecycx/... 通过"
depends_on:
  - "TASK-KERNEL-000"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Files Likely to Change

- `lifecycx/lifecycx.go` — 新建（Component/Starter/Stopper/Manager）
- `lifecycx/lifecycx_test.go` — 新建
- `lifecycx/example_test.go` — 新建

## Requirements Covered

> Spec TC: TC-001, TC-002, TC-003

| Requirement | Description |
|---|---|
| FR-001 | 组件生命周期管理 |
| BR-001 | 启动顺序为注册顺序，停止顺序为启动逆序 |
| BR-002 | 启动失败必须回滚已启动的 Component |
| BR-003 | 未 started 时 Stop 必须幂等返回 nil |

## Non-scope

- 不包含依赖图/拓扑排序
- 不包含 DI 容器
- 不包含热注册/动态添加

## Test Plan

| TC | Type | Description |
|----|------|-------------|
| TC-001 | Unit | 正常启停：A.Start→B.Start→B.Stop→A.Stop |
| TC-002 | Unit | 启动失败回滚：B.Start 失败→A.Stop→errors.Join |
| TC-003 | Unit | 未启动时 Stop：返回 nil |

## Implementation Notes

- Manager 内部持有 `[]Component` 切片（防御性拷贝）
- Start 按注册顺序，第 k 个失败时逆序 Stop 前 k-1 个
- Stop 按注册逆序，errors.Join 聚合
