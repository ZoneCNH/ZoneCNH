# TASK-EXC-005

> Registry 线程安全与 fake exchange

---

```yaml
task_id: TASK-EXC-005
module: domain-exchange
scope: "实现线程安全的 Registry，支持 Exchange 注册/查询/列表，支持 fake exchange 注入"
spec_ref:
  - "module/domain-exchange/SPEC.md#FR-EXC-005"
  - "module/domain-exchange/SPEC.md#BR-EXC-006"
  - "module/domain-exchange/SPEC.md#§16"
files:
  - "registry.go"
  - "registry_test.go"
  - "fake/exchange.go"
acceptance_criteria:
  - "AC-EXC-005: Registry 并发注册/查询安全"
  - "AC-EXC-005: 重复注册返回错误，不允许覆盖"
  - "AC-EXC-005: 列表排序 deterministic"
  - "AC-EXC-005: fake exchange 支持脚本化响应、延迟、错误、乱序 stream、partial fill"
depends_on:
  - "TASK-EXC-001"
  - "TASK-EXC-003"
  - "TASK-EXC-004"
estimated_effort: "2h"
priority: P1
status: pending
non_scope:
  - "不实现运行时动态卸载 exchange"
  - "不实现 real adapter（binance/okx）"
```

---

## Non-scope

- 不实现运行时动态卸载 exchange
- 不实现 real adapter（binance/okx）

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
| ----------- | ----------- | ------------------- |
| FR-EXC-005 | Registry 线程安全并支持 fake exchange | AC-EXC-005: 并发安全，deterministic，fake exchange 完整 |
| BR-EXC-006 | Registry 重复注册返回错误 | AC-EXC-005: 重复注册返回错误 |

## Test Plan

| Test Case | Type    | Description |
| --------- | ------- | ----------- |
| TC-EXC-005 | Race    | Registry 并发注册安全且 deterministic |

## Implementation Notes

- Registry 使用 sync.RWMutex 保护内部 map
- fake exchange 支持脚本化响应，覆盖成功、拒单、限频、partial fill、stream close
- 列表返回按 venue name 排序

## Implementation Plan

| Step | Description | Deliverables | Verification |
| ---- | ----------- | ------------ | ------------ |
| 1    | 实现 Registry 注册/查询/列表 | `registry.go` | `go build ./...` 通过 |
| 2    | 实现 fake exchange | `fake/exchange.go` | `go build ./...` 通过 |
| 3    | 并发测试和 deterministic 测试 | `registry_test.go` | `go test -race ./...` 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
| ---- | ----------- | ------ | ---------- |
| 并发竞争条件遗漏 | Medium | High | `go test -race` + count=100 |
