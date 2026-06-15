# TASK-MKT-007

> domainx boundary：与 domainx 枚举边界划清

---

```yaml
task_id: TASK-MKT-007
module: domain-market
version: v1.0.0
spec_ref:
  - "module/domain-market/SPEC.md#FR-MKT-014"
fr_ref: FR-MKT-007
ac_ref: AC-MKT-007
tc_ref: TC-MKT-007
status: pending
priority: P0
estimated_effort: "1.5h"
depends_on:
  - TASK-MKT-002
```

---

## 目标

与 domainx 重叠的订单枚举必须迁出或废弃，避免双 SSOT。

## 验收标准

- [ ] AC-MKT-007: 订单枚举与 domainx 单一归属
- [ ] Side 枚举在 domain-market 仅表达市场事件方向（保留）
- [ ] OrderType/OrderSide/OrderState 不存在于 domain-market
- [ ] 与 domainx 无执行枚举重复归属
- [ ] ADR 记录 Side 枚举归属决策

## 实现要点

- 审计 domain-market 中所有枚举定义
- 移除或废弃 OrderType/OrderSide/OrderState（归 domainx）
- Side 枚举保留：表达 Tick 的市场事件方向（aggressor side）
- 编写 ADR 记录枚举归属决策
- 如 domainx 已有对应枚举，添加 deprecated alias + MIGRATION 说明

## 测试要求

- TC-MKT-007: compile/adoption check
  - domain-market 编译无 OrderType/OrderSide/OrderState 引用
  - domainx adoption smoke: 使用 domainx 枚举的代码仍可编译
  - ADR 文档存在且内容完整
