# TASK-MKT-001

> decimal-precision：公开金融字段使用 decimalx.Decimal

---

```yaml
task_id: TASK-MKT-001
module: domain_market
version: v1.0.0
spec_ref:
  - "module/domain_market/SPEC.md#FR-MKT-001"
fr_ref: FR-MKT-001
ac_ref: AC-MKT-001
tc_ref: TC-MKT-001
acceptance_criteria:
  - "AC-MKT-001: public 金融字段采用 decimalx.Decimal"
status: pending
priority: P0
estimated_effort: "1h"
```

---

## 目标

确保所有公开价格、数量、成交量、金额、费率字段使用 `decimalx.Decimal` 或值对象，Public API 禁止 `float64`。

## 验收标准

- [ ] AC-MKT-001: public 金融字段采用 `decimalx.Decimal`
- [ ] compile check: `go build ./...` 通过
- [ ] lint check: 价格/数量字段无 `float64`

## 实现要点

- 审计所有 domain struct 中 Price/Qty/Volume/Turnover/Rate/Value 字段类型
- 替换 `float64` 为 `decimalx.Price`、`decimalx.Qty`、`decimalx.Decimal`
- Public API 返回值不得包含 `float64` 金融字段
- 内部计算若需 float64 转换，仅在 private 方法中执行

## 测试要求

- TC-MKT-001: compile check + lint 扫描确认无 public float64 金融字段
- table test: 构造含 decimal 字段的值对象，验证赋值与取值正确
