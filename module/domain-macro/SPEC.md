# domain-macro v1.0.0 Spec

- Status: Implemented
- Spec-Version: v1.0.0
- Module-Version: v1.0.0
- Layer: L2.5 领域共享
- Repository: https://github.com/ZoneCNH/domain-macro
- Release-Evidence: https://github.com/ZoneCNH/domain-macro/releases/tag/v1.0.0
- Last-Updated: 2026-06-15

## 1. 范围

`domain-macro` 定义宏观数据点、宏观状态、宏观信息集、修订版本和 no-lookahead 可见性规则。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | MacroPoint、MacroInformationSet、MacroState、MacroRegimeCard、revision/as-of/freshness 语义 |
| Depends on | `kernel`、`decimalx` 或精度 ADR 指定的数值边界 |
| Excludes | provider API client、forecasting、factor/allocation、external API DTO |
| Boundary with storage/provider | provider DTO 必须在 adapter/internal 层完成转换，公共领域模型只暴露宏观语义 |

## 3. 功能需求

| ID | 需求 |
| --- | --- |
| FR-MAC-001 | MacroPoint 必须表达 observed/released/available 三类时间。 |
| FR-MAC-002 | MacroPoint 必须记录 revision version、preliminary flag 和 source。 |
| FR-MAC-003 | `IsVisibleAt(decisionTime)` 必须 fail-closed，available time 缺失或晚于 decision time 时不可见。 |
| FR-MAC-004 | MacroInformationSet.AsOf 必须只返回 decision time 可见数据，并保持 copy-on-write。 |
| FR-MAC-005 | RevisionVersion 必须非负并可用于 deterministic revision ordering。 |
| FR-MAC-006 | MacroState / MacroRegimeCard 必须有稳定枚举和 validate 规则。 |
| FR-MAC-007 | 公共数值精度必须通过 ADR 冻结，推荐采用 `decimalx.Decimal`。 |

## 4. 非功能需求

- 回测安全：任何不可见数据默认拒绝，禁止 look-ahead。
- 可审计：来源、修订、初值/终值和 freshness 指标可追溯。
- 领域纯净：公共模型不包含 provider DTO 或 transport schema。

## 5. 发布门禁

| 门禁 | 要求 |
| --- | --- |
| No-lookahead | AsOf/IsVisibleAt fail-closed 测试覆盖。 |
| 精度 ADR | 明确 Decimal 迁移或 float64 兼容退出路线。 |
| DTO 边界 | `yahoo_models` 等 provider DTO 不在公共领域 API 泄漏。 |
| 修订门禁 | revision ordering 与 preliminary/confirmed 数据测试通过。 |
