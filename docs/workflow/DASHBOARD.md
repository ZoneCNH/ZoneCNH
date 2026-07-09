# 管线健康度仪表盘

> 生成时间: 2026-06-27T01:05:46Z
> 数据源: `.foundationx/status/index.json` (21 模块) + `.omc/state/pipeline/` (23 有评分数据)

## 总览

| 指标 | 值 |
|------|----|
| FoundationX 注册模块 | 21 |
| Pipeline 有评分数据 | 23 |
| Pipeline 全 6 阶段仲裁 | 20 |
| FoundationX factory 达标 | 20 |

## FoundationX 成熟度分布

| 维度 | 达标模块 | 比例 |
|------|---------|------|
| spec | 21/21 | ███████████████ 100% |
| impl | 21/21 | ███████████████ 100% |
| release | 21/21 | ███████████████ 100% |
| live | 7/21 | ▒▒▒▒▒░░░░░░░░░░ 33% |
| ci | 21/21 | ███████████████ 100% |
| adopt | 6/21 | ▒▒▒▒░░░░░░░░░░░ 29% |
| soak | 0/21 | ░░░░░░░░░░░░░░░ 0% |
| factory | 20/21 | ▓▓▓▓▓▓▓▓▓▓▓▓▓▓░ 95% |

## 模块管线进度

| 模块 | Maturity | Pipeline 进度 | 仲裁 | CI Pool |
|------|----------|-------------|------|---------|
| alertx | ░░░░░░ 0/8 | 🟡🟡🟡🟡🟡⬜ SMTaPlPrC | 5/5 pass | `sre/foundation-l1` |
| binance | ░░░░░░ 0/8 | 🔴⬜⬜⬜⬜⬜ SMTaPlPrC | — | `sre/market` |
| bootstrap | ▓▓▓░░░ 5/8 🏭 | ⬜⬜⬜⬜⬜⬜ SMTaPlPrC | — | `sre/foundation-l1` |
| clickhousex | ▓▓▓▓░░ 6/8 🏭 | 🟡🟡🟡🟡🟡🟡 SMTaPlPrC | 6/6 pass | `sre/storage-heavy` |
| configx | ▓▓▓▓░░ 6/8 🏭 | 🟡🟡🟡🟡🟡🟡 SMTaPlPrC | 6/6 pass | `sre/foundation-l1` |
| contracts | ▓▓▓▓░░ 6/8 🏭 | 🟢🟢🟢🟢🟢🟢 SMTaPlPrC | 2/6 pass | `sre/contracts` |
| domainx | ▓▓▓░░░ 5/8 🏭 | 🟡🟡🟡🟡🟡🟡 SMTaPlPrC | 6/6 pass | `sre/contracts` |
| goal | ░░░░░░ 0/8 | ⬜🔴⬜⬜⬜⬜ SMTaPlPrC | — | - |
| kafkax | ▓▓▓▓░░ 6/8 🏭 | 🟡🟡🟡🟡🟡🟡 SMTaPlPrC | 6/6 pass | `sre/storage-heavy` |
| kernel | ▓▓▓▓░░ 6/8 🏭 | 🟡🟡🟢🟡🟡🟡 SMTaPlPrC | 6/6 pass | `sre/foundation-l0` |
| natsx | ▓▓▓▓░░ 6/8 🏭 | 🟡🟡🟡🟡🟡🟡 SMTaPlPrC | 6/6 pass | `sre/storage-light` |
| observex | ▓▓▓▓░░ 6/8 🏭 | 🟡🟡🟡🟡🟡🟡 SMTaPlPrC | 6/6 pass | `sre/foundation-l1` |
| ossx | ▓▓▓▓░░ 6/8 🏭 | 🟡🟡🟡🟡🟡🟡 SMTaPlPrC | 6/6 pass | `sre/storage-light` |
| postgresx | ▓▓▓▓░░ 6/8 🏭 | 🟡🟡🟡🟡🟡🟡 SMTaPlPrC | 6/6 pass | `sre/storage-heavy` |
| redisx | ▓▓▓▓░░ 6/8 🏭 | 🟡🟡🟡🟡🟡🟡 SMTaPlPrC | 6/6 pass | `sre/storage-light` |
| resiliencx | ▓▓▓▓░░ 6/8 🏭 | 🟡🟡🟡🟡🟡🟡 SMTaPlPrC | 6/6 pass | `sre/foundation-l1` |
| schedulex | ▓▓▓▓░░ 6/8 🏭 | 🟡🟡🟡🟡🟡🟡 SMTaPlPrC | 6/6 pass | `sre/foundation-l1` |
| taosx | ▓▓▓▓░░ 6/8 🏭 | 🟡🟡🟡🟡🟡🟡 SMTaPlPrC | 6/6 pass | `sre/storage-heavy` |
| testkitx | ▓▓▓░░░ 4/8 🏭 | 🟡🟡🟡🟡🟡🟡 SMTaPlPrC | 6/6 pass | `sre/foundation-l1` |
| transportx | ▓▓▓░░░ 5/8 🏭 | 🟡🟡🟡🟡🟡🟡 SMTaPlPrC | 6/6 pass | `sre/contracts` |
| xlib_evidence | ▓▓▓░░░ 5/8 🏭 | 🟡🟡🟡🟡🟡🟡 SMTaPlPrC | 6/6 pass | `sre/governance` |
| xlib_harness | ▓▓▓░░░ 5/8 🏭 | 🟡🟡🟡🟡🟡🟡 SMTaPlPrC | 6/6 pass | `sre/governance` |
| xlib_standard | ▓▓▓░░░ 5/8 🏭 | 🟡🟡🟡🟡🟢🟡 SMTaPlPrC | 6/6 pass | `sre/governance` |
| xlibgate | ▓▓▓░░░ 5/8 🏭 | 🟡🟡🟡🟡🟡🟡 SMTaPlPrC | 6/6 pass | `sre/governance` |

> **图例**: 🟢 四源齐全 🔴 部分 🟡 2源 ⬜ 无 | 🏭 Factory 达标

---
*自动生成于 2026-06-27T01:05:46Z，数据源更新频率：随 CI pipeline 运行*