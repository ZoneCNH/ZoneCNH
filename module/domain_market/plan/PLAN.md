# domain_market v1.0.0 Implementation Plan

| 字段 | 值 |
| --- | --- |
| 模块 | `domain_market` |
| 当前版本 | v0.1.0 |
| 目标版本 | v1.0.0 |
| 依赖顺序 | `decimalx` API freeze 后；`domain_exchange` 之前 |
| 最后更新 | 2026-06-16 |

## 里程碑

| 里程碑 | 内容 | 退出条件 |
| --- | --- | --- |
| M0 API freeze | 冻结 DataProvider 接口、MarketEventEnvelope、值对象字段签名、domainx 边界 ADR | SPEC Approved + 兼容测试清单完成 |
| M1 核心不变量 | Tick/Quote/Bar/OrderBook/Instrument/Funding/OpenInterest/LongShortRatio Validate 实现；decimalx 精度替换；domainx 枚举迁出 | TASK-MKT-001/002/004/005/007 全部完成，invalid cases 全覆盖 |
| M2 验证资产 | quality gate fail-closed；stale/future/recovered gate；fuzz/race/golden 测试；domain struct lint（禁止 tag、禁止 float64） | TASK-MKT-003 完成，quality gate 测试通过 |
| M3 下游采用 | DataProvider 返回纯领域模型；fake provider 可复用；domain_exchange adoption smoke 通过 | TASK-MKT-006 完成，静态边界扫描无 transport 泄漏 |
| M4 发布 | CHANGELOG、MIGRATION、release manifest、CI gate（staticcheck/govulncheck/race/adoption）、tag v1.0.0 | 所有 v1 门禁通过 |

## PR 类别

| 类别 | 目的 | 关联里程碑 |
| --- | --- | --- |
| docs-v1-contract | 补齐 SPEC、TRACEABILITY、MIGRATION、CHANGELOG | M0 |
| api-v1-freeze | 冻结 DataProvider 接口、值对象、MarketEventEnvelope 签名 | M0 |
| decimal-precision | 替换公开 float64 为 decimalx.Decimal | M1 |
| validator-impl | Tick/Quote/Bar/OrderBook/Instrument/Funding/OpenInterest/LongShortRatio Validate | M1 |
| domainx-boundary | 迁出 OrderType/OrderSide/OrderState，保留 Side | M1 |
| quality-gate-tests | fail-closed、stale/future/recovered gate 测试 | M2 |
| fuzz-race-golden | fuzz、race、golden 回归测试 | M2 |
| domain-lint | struct 禁止 transport tag、price/qty 禁止 float64 | M2 |
| provider-contract | DataProvider 返回纯领域模型、fake provider | M3 |
| adoption-smoke | domain_exchange adoption check | M3 |
| ci-release-gates | staticcheck/govulncheck/race/adoption gate | M4 |
| release-v1.0.0 | tag、release notes、manifest、CHANGELOG、MIGRATION | M4 |
