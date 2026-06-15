# TASK-DEC-006: error-identity

| 字段 | 值 |
|------|-----|
| 模块 | decimalx |
| 目标版本 | v1.0.0 |
| 关联 FR | FR-DEC-010 |
| 关联 AC | AC-DEC-008 |
| 关联 TC | TC-DEC-008 |
| 状态 | Pending |

## 目标

公开错误必须可用 `errors.Is` 识别并保持兼容。typed errors 可识别，错误码可被 transport 层映射。

## 验收标准

AC-DEC-008: typed errors 支持 errors.Is。

## 实现要点

- 所有公开错误定义为 typed error（如 `ErrParseFailed`、`ErrScaleOverflow` 等）
- 错误类型支持 `errors.Is` 和 `errors.As`
- 错误码可被 transport 层映射
- 错误类型只可追加，不可删除或改语义（v1 兼容性承诺）

## 测试要求

- TC-DEC-008: error compatibility 测试
- 验证每个 typed error 可通过 `errors.Is` 识别
- 验证 `errors.As` 可提取错误详情
- API 兼容测试：错误类型不变性
