# TASK-MKT-002

> tick/quote/bar/orderbook validate：核心行情对象校验

---

```yaml
task_id: TASK-MKT-002
module: domain_market
version: v1.0.0
spec_ref:
  - "module/domain_market/SPEC.md#FR-MKT-002"
  - "module/domain_market/SPEC.md#FR-MKT-003"
  - "module/domain_market/SPEC.md#FR-MKT-004"
  - "module/domain_market/SPEC.md#FR-MKT-005"
fr_ref: FR-MKT-002
ac_ref: AC-MKT-002
tc_ref: TC-MKT-002
acceptance_criteria:
  - "AC-MKT-002: 核心行情对象验证 symbol/time/price/qty"
status: pending
priority: P0
estimated_effort: "3h"
depends_on:
  - TASK-MKT-001
```

---

## 目标

Tick、Quote、Bar、OrderBook 必须校验 symbol、timestamp、价格/数量边界和 bid/ask 关系。

## 验收标准

- [ ] AC-MKT-002: 核心行情对象验证 symbol/time/price/qty
- [ ] Tick Validate: Symbol/Venue/Price/Qty/Timestamp/Side/Quality 合法
- [ ] Quote Validate: bid/ask 非负，ask >= bid，timestamp 必填
- [ ] Bar Validate: High >= max(Open,Close,Low)，Low <= min(Open,Close,High)，OpenTime < CloseTime，Volume/Turnover 非负
- [ ] OrderBook Validate: Bids 价格降序，Asks 价格升序，bid < ask，数量非负，seq 连续

## 实现要点

- 为 Tick/Quote/Bar/OrderBook 各实现 `Validate() error` 方法
- 校验逻辑覆盖 SPEC §7 FR-MKT-002..005 的 WHEN/THEN 条件
- 错误返回 SPEC §12 定义的 sentinel error（ErrInvalidSymbol 等）
- 边界条件处理见 SPEC §13 Edge Cases

## 测试要求

- TC-MKT-002: validator table tests — 每个 Validate 方法的 valid/invalid case
- 覆盖 SPEC §13 列出的边界场景：
  - Bar 的 High 恰好等于 Open
  - OrderBook 无 Bid 或无 Ask（单边挂空）
  - Tick 的 Price 为零
  - 同一 Symbol 同一 Timestamp 收到多个 Tick
