# TASK-RESILIENCX-005

> Bulkhead 实现：并发控制

---

```yaml
task_id: TASK-RESILIENCX-005
module: resiliencx
scope: "实现 Bulkhead 接口，支持并发数限制和等待队列"
spec_ref:
  - "module/resiliencx/SPEC.md#FR-004"
  - "module/resiliencx/SPEC.md#BR-004"
files:
  - "bulkhead.go"
  - "bulkhead_impl.go"
  - "bulkhead_test.go"
acceptance_criteria:
  - "并发数 < max_concurrent 时执行 fn"
  - "并发数满时等待空位或 ctx 超时"
  - "超时返回 ErrBulkheadFull"
  - "Available() 返回当前可用槽位"
depends_on:
  - "TASK-RESILIENCX-001"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-004 | Bulkhead：并发限制 + 等待 + 超时 | 2 个 WHEN/THEN 场景 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| §7.4-1 | Unit | 并发数 < max：执行成功 |
| §7.4-2 | Unit | 并发数满：等待空位 |
| §7.4-3 | Unit | 超时：返回 ErrBulkheadFull |
| — | Unit | Available() 返回正确值 |

## Implementation Notes

- 使用带缓冲的 channel 作为信号量
- `Execute` 获取信号量 → 执行 fn → 释放信号量
- `Available` 返回 `cap(ch) - len(ch)`

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `bulkheadImpl`（sem chan struct{}, max int） | `bulkhead_impl.go` | `go build ./...` 通过 |
| 2 | 实现 `Execute`：select 获取信号量 → fn → 释放 | `bulkhead_impl.go` | §7.4-1, §7.4-2 通过 |
| 3 | 实现 `Available` 和超时逻辑 | `bulkhead_impl.go` | §7.4-3 通过 |
| 4 | 并发安全验证 | `bulkhead_test.go` | `go test -race ./... -run TestBulkhead` 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 信号量泄漏 | Low | High | defer 释放 |
