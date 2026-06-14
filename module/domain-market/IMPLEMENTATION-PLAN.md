# domain-market v1.0.0 Implementation Plan

| 字段 | 值 |
| --- | --- |
| 模块 | `domain-market` |
| 当前版本 | v0.1.0 |
| 目标版本 | v1.0.0 |
| 依赖顺序 | `decimalx` API freeze 后；`domain-exchange` 之前 |
| 最后更新 | 2026-06-15 |

## 里程碑

| 里程碑 | 内容 | 退出条件 |
| --- | --- | --- |
| M0 Scope / ADR | 固化 market vs domainx 边界、精度策略和 provider 纯净边界 | ADR/SPEC 完成 |
| M1 Validators | Tick/Quote/Bar/OrderBook/Instrument 验证器 | invalid cases 全覆盖 |
| M2 Quality gate | dirty/stale/time-invalid fail-closed | quality gate 测试通过 |
| M3 Provider contract | DataProvider/HistoricalBarsRequest 返回纯领域模型 | 静态边界扫描无 transport 泄漏 |
| M4 Release gates | CI、docs、migration、release manifest | tag v1.0.0 前门禁通过 |

## PR 类别

| 类别 | 目的 |
| --- | --- |
| docs-v1-contract | 补齐 SPEC、TRACEABILITY、MIGRATION、CHANGELOG |
| api-v1-freeze | 冻结行情值对象、质量门禁和 provider contract |
| invariant-tests | 覆盖价格、数量、时间、质量和边界不变量 |
| ci-release-gates | 加入 staticcheck/govulncheck/adoption/boundary scan |
| release-v1.0.0 | 发布 tag、release notes 与 manifest |
