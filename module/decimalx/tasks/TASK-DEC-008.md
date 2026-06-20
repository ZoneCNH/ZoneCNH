# TASK-DEC-008: 下游 adoption + release

| 字段 | 值 |
|------|-----|
| 模块 | decimalx |
| 目标版本 | v1.0.0 |
| 关联 FR | §5 下游门禁 + §22 Release DoD |
| 关联 AC | 全部 AC 闭环 |
| 关联 TC | TC-DEC-001 ~ TC-DEC-008 |
| 状态 | Pending |

## 目标

完成下游模块 adoption 检查和 v1.0.0 release 流程，确保所有消费方可编译采用。

## 验收标准

- `domain_market`、`domain_exchange`、`domain_macro`、`domainx` 可编译采用
- Version 更新为 v1.0.0
- CHANGELOG.md、MIGRATION.md、release manifest 齐全
- SPEC Approved 标记确认

## 实现要点

- 下游门禁：`GOWORK=off make adoption-check`
- 下游模块的公开价格、数量、金额、费率与名义价值字段不得使用 float64
- Release 检查：`GOWORK=off make release-check`
- API freeze review 通过，TRACEABILITY 中 Public API 项无 TBD
- 版本号从 v0.2.0 更新为 v1.0.0
- 文档齐全：CHANGELOG.md、MIGRATION.md

## 测试要求

- 下游模块 smoke 通过（domain_market、domain_exchange、domain_macro、domainx）
- 全部 Release DoD 检查项通过
- 版本号验证
