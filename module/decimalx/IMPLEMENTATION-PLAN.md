# decimalx v1.0.0 Implementation Plan

| 字段 | 值 |
| --- | --- |
| 模块 | `decimalx` |
| 当前版本 | v0.2.0 |
| 目标版本 | v1.0.0 |
| 依赖顺序 | 第一优先级，其他 L2.5 模块采用前必须先冻结 |
| 最后更新 | 2026-06-15 |

## 里程碑

| 里程碑 | 内容 | 退出条件 |
| --- | --- | --- |
| M0 API freeze | 冻结 Decimal/Money/Currency API、错误类型、序列化语义 | SPEC 与兼容测试清单完成 |
| M1 核心不变量 | 不可变性、parse、format、exact arithmetic、rounding/context | 需求 FR-DEC-001..008 均有实现任务 |
| M2 验证资产 | golden、property/fuzz、race、benchmark、SQL/JSON 测试 | 失败用例可复现且纳入 CI |
| M3 下游采用 | 下游模块替换公开 float64 价格/数量/金额字段 | `domain-*` 与 `domainx` adoption smoke 通过 |
| M4 发布 | CHANGELOG、MIGRATION、release manifest、tag v1.0.0 | 所有 v1 门禁通过 |

## PR 类别

| 类别 | 目的 |
| --- | --- |
| docs-v1-contract | 明确 API freeze、边界与迁移说明 |
| api-v1-freeze | 冻结 Decimal/Money/Currency 公共契约 |
| invariant-tests | 补齐不可变、精度、rounding 与错误测试 |
| ci-release-gates | 加入 race/staticcheck/govulncheck/adoption gate |
| release-v1.0.0 | 发布 tag、release notes 与 manifest |
