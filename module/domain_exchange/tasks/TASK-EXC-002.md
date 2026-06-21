# TASK-EXC-002

> 下单/撤单/查询请求：idempotency、client id、venue、instrument

---

```yaml
task_id: TASK-EXC-002
module: domain_exchange
scope: "定义 PlaceOrderRequest、CancelOrderRequest、QueryOrderRequest 请求类型，包含 Validate()、ClientID、idempotency 语义"
spec_ref:
  - "module/domain_exchange/SPEC.md#FR-EXC-002"
  - "module/domain_exchange/SPEC.md#§10"
  - "module/domain_exchange/SPEC.md#BR-EXC-002"
  - "module/domain_exchange/SPEC.md#BR-EXC-004"
files:
  - "request.go"
  - "request_test.go"
acceptance_criteria:
  - "AC-EXC-002: PlaceOrderRequest 包含 Symbol/Side/Type/Qty/Price/ClientID/Venee 字段"
  - "AC-EXC-002: PlaceOrderRequest.Validate() 拒绝空 ClientID（prod/paper 模式）"
  - "AC-EXC-002: CancelOrderRequest 和 QueryOrderRequest 统一建模"
  - "AC-EXC-002: 所有 price/qty 使用 decimalx.Decimal"
depends_on:
  - "TASK-EXC-001"
estimated_effort: "2h"
priority: P0
status: pending
non_scope:
  - "不实现 Exchange 接口方法（仅请求类型）"
  - "不实现 ExchangeError 分类（→TASK-EXC-003）"
  - "不实现 retry 逻辑（→TASK-EXC-003）"
```

---

## Non-scope

- 不实现 Exchange 接口方法（仅请求类型）
- 不实现 ExchangeError 分类（→TASK-EXC-003）
- 不实现 retry 逻辑（→TASK-EXC-003）

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
| ----------- | ----------- | ------------------- |
| FR-EXC-002 | 下单/撤单/查询请求包含 idempotency/client/venue/instrument | AC-EXC-002: 请求类型完整，Validate() 拒绝空 ClientID |
| BR-EXC-002 | prod/paper 下单必须有 ClientID | AC-EXC-002: Validate() 拒绝空 ClientID |
| BR-EXC-004 | 所有 price/qty/balance 使用 decimalx.Decimal | AC-EXC-002: Qty/Price 字段类型正确 |

## Test Plan

| Test Case | Type    | Description |
| --------- | ------- | ----------- |
| TC-EXC-002 | Unit    | PlaceOrderRequest 缺少 ClientID → Validate() 失败 |

## Implementation Notes

- 请求类型与 SPEC §10 Data Model 一致
- Validate() 在 prod/paper 模式下强制 ClientID 非空
- backtest 模式可自动生成 ClientID 但必须可复现

## Implementation Plan

| Step | Description | Deliverables | Verification |
| ---- | ----------- | ------------ | ------------ |
| 1    | 定义 PlaceOrderRequest 和 Validate() | `request.go` | `go build ./...` 通过 |
| 2    | 定义 CancelOrderRequest 和 QueryOrderRequest | `request.go` | `go build ./...` 通过 |
| 3    | 请求验证单元测试 | `request_test.go` | `go test ./...` 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
| ---- | ----------- | ------ | ---------- |
| Validate 规则与实际交易所约束不一致 | Low | Medium | 参照 SPEC §13 Edge Cases |
