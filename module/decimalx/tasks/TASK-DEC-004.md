# TASK-DEC-004: arithmetic-exact + arithmetic-rounding

| 字段 | 值 |
|------|-----|
| 模块 | decimalx |
| 目标版本 | v1.0.0 |
| 关联 FR | FR-DEC-004, FR-DEC-005, FR-DEC-006 |
| 关联 AC | AC-DEC-004 |
| 关联 TC | TC-DEC-004, TC-DEC-005 |
| 状态 | Pending |

## 目标

加减乘必须精确，无舍入；除法、量化和舍入必须显式携带 rounding/context 参数。零值 Context 对非精确商不得静默四舍五入。

## 验收标准

AC-DEC-004: 精确运算与显式 rounding/context。

## 实现要点

- `Add/Sub/Mul` 结果精确，无舍入，无精度损失
- `QuoExact(other)` 要求商为终止小数，否则返回 `ErrNonTerminating`
- `QuoScale(other, scale, rounding)` 必须显式携带 scale 和 Rounding 参数
- `Quantize(scale, rounding)` 和 `Rescale(scale, rounding)` 必须显式携带 Rounding
- 三种 rounding mode 语义锁定：`RoundDown`、`RoundHalfEven`、`RoundHalfUp`
- 零值 Context 不得静默截断非精确商
- `ErrDivZero` 在除数为零时返回

## 测试要求

- TC-DEC-004: arithmetic/property 测试
- TC-DEC-005: `QuoExact(1,3)` 返回 ErrNonTerminating
- 单元测试：Add/Sub 精确性；QuoExact 非终止拒绝；QuoScale rounding
- Fuzz 测试：`FuzzAddSubInvariant`、`FuzzQuantizeRescale`
- Benchmark：Add、Mul、QuoScale
