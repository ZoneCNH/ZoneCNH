# TASK-MKT-004

> instrument validate：交易品种标识与精度校验

---

```yaml
task_id: TASK-MKT-004
module: domain_market
version: v1.0.0
spec_ref:
  - "module/domain_market/SPEC.md#FR-MKT-006"
fr_ref: FR-MKT-004
ac_ref: AC-MKT-004
tc_ref: TC-MKT-004
acceptance_criteria:
  - "AC-MKT-004: Instrument 精度与状态语义稳定"
status: pending
priority: P0
estimated_effort: "1.5h"
depends_on:
  - TASK-MKT-001
```

---

## 目标

Instrument 必须表达交易品种标识、市场类型、价格/数量精度和可交易状态。

## 验收标准

- [ ] AC-MKT-004: Instrument 精度与状态语义稳定
- [ ] Instrument.Validate: PriceTick/QtyStep/MinQty/MinNotional > 0
- [ ] InstrumentStatus 枚举值完整（Active/Suspended/Delisted 等）
- [ ] Symbol/Venue/BaseAsset/QuoteAsset 非空校验

## 实现要点

- 为 Instrument 实现 `Validate() error`
- PriceTick/QtyStep/MinQty/MinNotional 使用 decimalx.Decimal，校验正值
- InstrumentStatus 枚举定义（Active/Suspended/Delisted/PreMarket 等）
- Symbol 格式校验规则

## 测试要求

- TC-MKT-004: instrument invariant tests
  - 合法 Instrument 构造成功
  - PriceTick=0 或 MinQty<0 返回错误
  - InstrumentStatus 未知值返回错误
  - Symbol 为空返回 ErrInvalidSymbol
