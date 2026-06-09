# TASK-KERNEL-003

> 注册表：模块注册、重复检测、nil 检查、并发安全

---

```yaml
task_id: TASK-KERNEL-003
module: kernel
scope: "实现模块注册表，支持注册、重复检测、nil 检查、并发安全"
spec_ref:
  - "module/kernel/SPEC.md#FR-001"
  - "module/kernel/SPEC.md#BR-009"
files:
  - "registry.go"
  - "registry_test.go"
acceptance_criteria:
  - "AC-NEW-16: Register(nil) 返回 ErrNilModule"
  - "AC-NEW-17: Register(同名模块) 返回 ErrAlreadyRegistered"
  - "AC-NEW-18: Register(新模块) 返回 nil，模块加入注册表"
  - "AC-NEW-19: App 已启动后 Register 返回 ErrAlreadyStarted"
  - "AC-NEW-20: 并发 Register 无 data race"
depends_on:
  - "TASK-KERNEL-001"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Files Likely to Change

- `registry.go` — 新建
- `registry_test.go` — 新建

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-001 | Register：注册、重复检测、nil 检查、已启动拒绝 | 4 个 WHEN/THEN 场景全部覆盖 |
| BR-009 | Deps 接口由消费方注入 | Register 只接受 Module 接口，不关心 Deps 具体实现 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| TC-008 | Unit | 重复注册：同名模块注册两次返回 ErrAlreadyRegistered |
| TC-015 | Unit | 并发 Register：多个 goroutine 同时注册不同模块，无 data race |
| — | Unit | nil 模块：Register(nil) 返回 ErrNilModule |
| — | Unit | 正常注册：Register 后可通过 name 查询到模块 |
| — | Unit | 已启动后注册：app started 后 Register 返回 ErrAlreadyStarted |

## Implementation Notes

- 注册表内部使用 `map[string]Module` 存储
- 读写操作均需加锁（`sync.RWMutex`）
- 模块名通过 `m.Name()` 获取，不存储额外的 name 字段
- 需要一个 `started` 标志位，由 lifecycle 层在 Run 完成后设置
- 注册表应提供 `get(name)` 和 `all()` 内部方法供 lifecycle 使用

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 定义 `registry` 结构体（map[string]Module + RWMutex + started 标志）和内部方法（get, all, setStarted） | `registry.go` | `go build ./...` 通过 |
| 2 | 实现 `Register` 方法：nil 检查 → 重复检测 → 已启动拒绝 → 写入 map | `registry.go` | `go test ./... -run TestRegister` 通过 |
| 3 | 实现 `App.Register` 委托到内部 registry | `kernel.go` | 接口方法调用链正确 |
| 4 | 编写并发测试：多 goroutine 同时注册，用 `-race` 验证无 data race | `registry_test.go` | `go test -race ./... -run TestConcurrentRegister` 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 锁粒度不当导致死锁 | Low | High | 只在 map 读写时加锁，不持锁调用外部方法 |
| 并发测试不充分 | Medium | Medium | 使用 sync.WaitGroup 确保所有 goroutine 同时触发 |
