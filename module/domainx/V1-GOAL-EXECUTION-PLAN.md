# domainx v1.0.0 Goal Execution Alignment

| 字段 | 值 |
| --- | --- |
| 模块 | `domainx` |
| 层级 | L2.5 领域共享 |
| 仓库 | <https://github.com/ZoneCNH/domainx> |
| 目标版本 | v1.0.0 |
| 状态 | 已有 `goal.md` / `SPEC.md` / `TRACEABILITY.md`，本页补充外部执行计划对齐 |
| 计划来源 | `/home/zone/Downloads/0615/ZoneCNH-v1.0.0-goal-execution-plans/domainx-v1.0.0-goal-execution-plan.md` |
| 最后更新 | 2026-06-15 |

## v1.0.0 边界

`domainx` 是交易域共享模型 SSOT，拥有 `Order`、`Trade`、`Position`、`Portfolio`、`ExecutionReport`、`OrderSide`、`OrderType` 与 `OrderState`。`domain_exchange` 只能通过 SPI request/response、兼容 alias 或返回 `domainx` 类型来表达交易所交互结果，不应形成第二套订单生命周期模型。

## 与现有文档的对齐要求

- 现有 `SPEC.md` 和 `TRACEABILITY.md` 保持为权威模块规格与追溯基线。
- v1.0.0 公共模型应优先收口到 Order / Trade / Position / Portfolio / ExecutionReport。
- Fill、Exposure 等概念如需成为 v1 public API，必须先更新 SPEC 与 TRACEABILITY；否则仅能作为内部或后续版本候选。
- 金融数值字段应采用 `decimalx.Decimal` 或等价值对象，避免 public `float64`。

## 依赖顺序

| 顺序 | 依赖 | 说明 |
| --- | --- | --- |
| 1 | `decimalx` | 交易价格、数量、名义金额、费用等数值语义依赖 Decimal/Money。 |
| 2 | `domain_market` | 行情语义与 trade side 边界需先明确。 |
| 3 | `domain_exchange` | 交易所 SPI 应采用 `domainx` 订单与执行报告类型。 |

## 里程碑

| 里程碑 | 内容 | 退出条件 |
| --- | --- | --- |
| M0 Boundary ADR | 冻结 domainx vs domain_exchange/domain_market 边界 | ADR 与 SPEC 差异关闭 |
| M1 Public model freeze | Order/Trade/Position/Portfolio/ExecutionReport API 冻结 | 兼容测试和示例完成 |
| M2 Invariants | 订单状态机、成交归属、持仓方向、组合聚合不变量 | invariant tests 完成 |
| M3 Adoption | `domain_exchange` 返回或兼容 `domainx` 类型 | downstream smoke 通过 |
| M4 Release | CHANGELOG、MIGRATION、release manifest、tag v1.0.0 | 所有门禁通过 |
