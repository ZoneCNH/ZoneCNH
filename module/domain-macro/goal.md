# domain-macro Goal

| 字段 | 值 |
| --- | --- |
| 模块 | `domain-macro` |
| 层级 | L2.5 领域共享 |
| 仓库 | <https://github.com/ZoneCNH/domain-macro> |
| 当前版本 | v0.1.0 |
| 目标版本 | v1.0.0 |
| 状态 | v1.0.0 执行计划待落地 |
| 计划来源 | `/home/zone/Downloads/0615/ZoneCNH-v1.0.0-goal-execution-plans/domain-macro-v1.0.0-goal-execution-plan.md` |
| 最后更新 | 2026-06-15 |

## 目标

`domain-macro` 定义可复现、无 look-ahead 的宏观数据领域模型和信息集。策略与回测只能看到在 DecisionTime 前已经 available 的宏观点，并能审计来源、修订、时效性与状态。

## 非目标

- 不实现 provider API client。
- 不提供预测、因子、资产配置或交易决策逻辑。
- 不在公共领域模型中泄漏外部 API 响应形态；`yahoo_models` 等 DTO 必须迁出或标记 internal。

## v1.0.0 成功标准

- `MacroPoint` 必须表达 ObservedAt、ReleasedAt、AvailableAt、RevisionVersion、IsPreliminary、Source。
- `MacroInformationSet` 必须 fail-closed，`AsOf(decisionTime)` 只能返回当时可见数据。
- 修订版本必须可排序且 `RevisionVersion >= 0`。
- `MacroState` / `MacroRegimeCard` 的枚举和校验语义稳定。
- 宏观数值精度必须通过 ADR 冻结：推荐迁移到 `decimalx.Decimal`，或保留 float64 仅作为派生值并增加 raw/decimal 字段。

## 当前阻塞

| 优先级 | 阻塞项 | 处理方向 |
| --- | --- | --- |
| P0 | 当前版本仍为 v0.1.0 | 补齐 v1 spec、traceability 与 release gate |
| P0 | `MacroPoint.Value` / `IndicatorValue.Value` 仍可能为 float64 | 通过精度 ADR 决定迁移策略 |
| P0 | `yahoo_models` 边界不清 | 迁出 provider DTO 或标记 internal |
| P1 | MacroState validate 与 copy-on-write 证据不足 | 增加 validator 与 information set 测试 |
