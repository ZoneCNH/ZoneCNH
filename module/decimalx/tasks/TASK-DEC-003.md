# TASK-DEC-003: string-output

| 字段 | 值 |
|------|-----|
| 模块 | decimalx |
| 目标版本 | v1.0.0 |
| 关联 FR | FR-DEC-003 |
| 关联 AC | AC-DEC-003 |
| 关联 TC | TC-DEC-003 |
| 状态 | Pending |

## 目标

字符串输出必须区分规范输出、固定精度输出与调试输出。三种输出格式语义明确、可预测。

## 验收标准

AC-DEC-003: String/Canonical/FixedString 输出稳定。

## 实现要点

- `String()` 保留 scale（如 `"1.23000"` scale=5 输出 `"1.23000"`）
- `CanonicalString()` 去除无意义 0（如 `"1.23000"` → `"1.23"`）
- `FixedString(scale)` 必须 exact 或返回 `ErrRoundingRequired`
- scale 为负数时输出正确（如 coeff=123, scale=-2 → `"12300"`）

## 测试要求

- TC-DEC-003: formatting golden 测试
- Table tests：正/负 scale、零值、大数、边界 precision
- Golden/snapshot：v1 freeze 公开行为写入 `testdata/v1/*.golden`
