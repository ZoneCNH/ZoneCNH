# TASK-EXC-006

> MarketReader 边界：返回 domain_market 类型

---

```yaml
task_id: TASK-EXC-006
module: domain_exchange
scope: "确保 MarketReader 接口返回 domain_market 类型（Kline/Quote/OrderBook/Funding/OpenInterest/Tick），不重复定义行情模型"
spec_ref:
  - "module/domain_exchange/SPEC.md#FR-EXC-006"
  - "module/domain_exchange/SPEC.md#§9"
  - "module/domain_exchange/SPEC.md#§15"
files:
  - "exchange.go"
  - "boundary_test.go"
acceptance_criteria:
  - "AC-EXC-006: MarketReader.Klines 返回 []domainmarket.Bar"
  - "AC-EXC-006: MarketReader.TickerPrice 返回 domainmarket.Quote"
  - "AC-EXC-006: MarketReader.OrderBook 返回 domainmarket.OrderBook"
  - "AC-EXC-006: DerivativeReader/Funding/OpenInterest 返回 domain_market 类型"
  - "AC-EXC-006: 不存在本地重复定义的行情值对象"
depends_on:
  - "TASK-EXC-001"
estimated_effort: "1h"
priority: P1
status: pending
non_scope:
  - "不实现行情数据获取逻辑"
  - "不定义 domain_market 类型（仅引用）"
  - "不实现 Streamer（→TASK-EXC-005 fake exchange）"
```

---

## Non-scope

- 不实现行情数据获取逻辑
- 不定义 domain_market 类型（仅引用）
- 不实现 Streamer（→TASK-EXC-005 fake exchange）

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
| ----------- | ----------- | ------------------- |
| FR-EXC-006 | MarketReader 返回 domain_market 类型 | AC-EXC-006: 返回类型正确，无本地重复定义 |

## Test Plan

| Test Case | Type     | Description |
| --------- | -------- | ----------- |
| TC-EXC-006 | Boundary | type boundary scan: 确认 MarketReader 返回类型均为 domain_market 包 |

## Implementation Notes

- MarketReader 接口签名已在 TASK-EXC-001 中定义
- 本任务聚焦验证边界：确保不引入本地重复行情类型
- boundary_test.go 可用编译期检查或反射验证返回类型归属

## Implementation Plan

| Step | Description | Deliverables | Verification |
| ---- | ----------- | ------------ | ------------ |
| 1    | 验证 MarketReader/DerivativeReader 返回类型均为 domain_market | `boundary_test.go` | `go test ./...` 通过 |
| 2    | 扫描确认无本地重复行情值对象 | `boundary_test.go` | 无本地类型定义 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
| ---- | ----------- | ------ | ---------- |
| domain_market 接口变更导致编译失败 | Low | High | 依赖 domain_market v1.0.0 稳定版 |
