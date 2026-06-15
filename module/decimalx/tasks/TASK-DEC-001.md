# TASK-DEC-001: decimal-immutable

| 字段 | 值 |
|------|-----|
| 模块 | decimalx |
| 目标版本 | v1.0.0 |
| 关联 FR | FR-DEC-001 |
| 关联 AC | AC-DEC-001 |
| 关联 TC | TC-DEC-001 |
| 状态 | Pending |

## 目标

`Decimal` 必须不可变，任何系数导出不得暴露内部可变状态。调用 `Coeff()` 或任何算术方法时，返回 `big.Int` 副本，receiver 不被修改。

## 验收标准

AC-DEC-001: 系数导出 copy，外部修改不影响原值。

## 实现要点

- `Decimal` struct 的 `coeff *big.Int` 字段不导出，外部无法直接访问
- `Coeff()` 必须返回 `*big.Int` 的深拷贝（`new(big.Int).Set(d.coeff)`）
- 所有算术方法（Add/Sub/Mul/Quo 等）返回新 `Decimal`，不修改 receiver
- 并发读取同一 `Decimal` 无 data race

## 测试要求

- TC-DEC-001: immutability/property 测试——`Coeff()` 返回 copy，修改 copy 不影响原 Decimal
- Race 测试：并发读取同一 Decimal/Money
- 单元测试：验证算术方法返回新值后原值不变
