# TASK-DEC-002: parse-grammar

| 字段 | 值 |
|------|-----|
| 模块 | decimalx |
| 目标版本 | v1.0.0 |
| 关联 FR | FR-DEC-002 |
| 关联 AC | AC-DEC-002 |
| 关联 TC | TC-DEC-002 |
| 状态 | Pending |

## 目标

Parse 必须采用稳定语法，仅接受普通十进制字符串；拒绝空白、指数记法和非规范格式。

## 验收标准

AC-DEC-002: whitespace/exponent/非法格式均拒绝。

## 实现要点

- `Parse(s string)` 仅接受普通十进制格式（如 `"123.45"`、`"-0.003"`）
- 拒绝：空字符串、空格、指数记法（`1e3`）、`+1` 前缀、`NaN`、`Inf`
- 边界：`".1"` 和 `"1."` 按 grammar 规则处理（拒绝或按明确规则接受）
- `DefaultLimits` 限制 precision/scale 上限，超出拒绝
- 返回 `ErrParseFailed` 或 `ErrScaleOverflow`/`ErrPrecisionOverflow`

## 测试要求

- TC-DEC-002: parse golden/fuzz 测试
- Table tests：空串、指数、空白、非法 scale、边界 precision
- Fuzz 测试：`FuzzParseRoundTrip`——随机合法输入 round-trip 一致
- Edge cases：`".1"`、`"1."`、`"+1"`、`"1e3"`、`"NaN"`、`"Inf"` 均须拒绝或按 grammar 规则处理
