# domain-macro v1.0.0 Implementation Plan

| 字段 | 值 |
| --- | --- |
| 模块 | `domain-macro` |
| 当前版本 | v0.1.0 |
| 目标版本 | v1.0.0 |
| 依赖顺序 | `decimalx` API freeze 后，与 `domain-market` / `domainx` 可并行 |
| 最后更新 | 2026-06-15 |

## 里程碑

| 里程碑 | 内容 | 退出条件 |
| --- | --- | --- |
| M0 SPEC / Precision ADR | 冻结 float64 迁移或 Decimal 采用路线 | ADR/SPEC 完成 |
| M1 MacroPoint / InformationSet | 时间、可见性、copy-on-write、不变量 | no-lookahead 测试通过 |
| M2 Revision / As-of | revision ordering、preliminary/confirmed、as-of 查询 | revision 测试通过 |
| M3 Provider DTO boundary | `yahoo_models` 迁出或 internal 化 | static boundary scan 通过 |
| M4 Release | docs、CI、migration、release manifest | tag v1.0.0 前门禁通过 |

## PR 类别

| 类别 | 目的 |
| --- | --- |
| docs-v1-contract | 明确 no-lookahead、revision、precision 和 DTO 边界 |
| api-v1-freeze | 冻结 MacroPoint、InformationSet、State/Regime API |
| invariant-tests | 覆盖 visibility、revision、copy-on-write、state validate |
| ci-release-gates | 加入 staticcheck/govulncheck/boundary/adoption gate |
| release-v1.0.0 | 发布 tag、release notes 与 manifest |
