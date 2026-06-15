# TASK-DEC-005: json-encoding + sql-scan + money-currency

| 字段 | 值 |
|------|-----|
| 模块 | decimalx |
| 目标版本 | v1.0.0 |
| 关联 FR | FR-DEC-007, FR-DEC-008, FR-DEC-009 |
| 关联 AC | AC-DEC-005, AC-DEC-006, AC-DEC-007 |
| 关联 TC | TC-DEC-005, TC-DEC-006, TC-DEC-007 |
| 状态 | Pending |

## 目标

1. JSON 表达必须是带引号十进制字符串，避免 JavaScript/JSON number 精度损失。
2. SQL scan 必须拒绝 float 输入，防止静默精度损失。
3. Money 的币种必须参与等价性与运算校验，跨币种加减必须失败。

## 验收标准

- AC-DEC-005: JSON 仅使用 quoted decimal string。
- AC-DEC-006: SQL scan 拒绝 float。
- AC-DEC-007: Money 跨币种运算 fail-closed。

## 实现要点

- JSON Marshal：Decimal 序列化为 `"1.23000"`（带引号十进制字符串），禁止 JSON number
- JSON Unmarshal：遇到无引号 number（如 `1.23` 而非 `"1.23"`）必须失败
- SQL `Scan(float32)` 或 `Scan(float64)` 返回 `ErrFloatScanRejected`
- `Money.Add(other)` 检查币种一致性，跨币种返回 `ErrCurrencyMismatch`
- `Money.Sub(other)` 同理
- `Currency` 类型为 `string`，参与等价性校验

## 测试要求

- TC-DEC-005: json marshal/unmarshal round-trip 测试——`"1.23000"` → Decimal → `"1.23000"`
- TC-DEC-006: database scan cases——`Scan(float64)` 返回 ErrFloatScanRejected
- TC-DEC-007: money currency guard——`Money(USD).Add(Money(EUR))` 返回 ErrCurrencyMismatch
- Fuzz 测试：`FuzzJSONRoundTrip`
