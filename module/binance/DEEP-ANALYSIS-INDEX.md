# DEEP-ANALYSIS.md 分区索引

> 本文档是 `DEEP-ANALYSIS.md`（1029 行，~51KB）的导航索引，解决 P2-1 "Split oversized DEEP-ANALYSIS.md" 的可维护性问题。
>
> DEEP-ANALYSIS.md 已于 2026-06-22 拆分为两个归档文件。当前权威规范以 `SPEC.md` v3.5.0 + `TRACEABILITY.md` v3.5.0 为准。本索引仅供历史查阅导航。

---

## 拆分归档产物

| 归档文件 | 原 DEEP-ANALYSIS 章节 | 主题 |
|----------|----------------------|------|
| `DEEP-ANALYSIS-ARCHIVE-architecture.md` | §0-§2 + 附录A | 分布式架构约束、架构评估、目标架构设计、新旧对比 |
| `DEEP-ANALYSIS-ARCHIVE-operations.md` | §4-§11 + 附录B | API/数据流/配置/部署/路线图/风险/差距总结 |

## 分区概览

| 原分区 | 行号 | 主题 | 归档位置 | 活跃替代 |
|--------|------|------|----------|----------|
| §0 | 11-16 | 分布式架构约束 | ARCHIVE-architecture §0 | `SPEC.md` §4 Goals + FR-011 |
| §1 | 17-76 | 当前架构评估 (v1.0.1 基线) | ARCHIVE-architecture §1 | `SPEC.md` §2 |
| §2 | 78-156 | 目标架构设计 | ARCHIVE-architecture §2 | `SPEC.md` §2 + `IMPLEMENTATION-PLAN.md` |
| §3 | 158-531 | 六模块集成详案 | (已废弃) | `SPEC.md` FR-003~FR-011 |
| §4 | 533-659 | Gin Web API 设计 | ARCHIVE-operations §4 | `SPEC.md` FR-007/FR-007a |
| §5 | 661-711 | 完整数据流 | ARCHIVE-operations §5 | `SPEC.md` Appendix C.2 |
| §6 | 713-780 | 目录结构变更 | ARCHIVE-operations §6 | `IMPLEMENTATION-PLAN.md` §4 |
| §7 | 782-866 | 配置设计 | ARCHIVE-operations §7 | `SPEC.md` §11 Config |
| §8 | 868-914 | 部署拓扑 | ARCHIVE-operations §8 | `IMPLEMENTATION-PLAN.md` |
| §9 | 916-962 | SPEC 升级路线图 | ARCHIVE-operations §9 | 已执行；当前 SPEC v3.5.0 |
| §10 | 964-976 | 风险与缓解 | ARCHIVE-operations §10 | `BOUNDARY-GATES.md` |
| §11 | 978-989 | 开放问题 | ARCHIVE-operations §11 | `docs/report/binance/` 系列报告 |
| §12 + 附录 A/B | 991-1030 | 代码实态审计 + 差距总结 | ARCHIVE-operations 附录B | `docs/migrations/binance-v2-upgrade.md` |

---

## 快速跳转

- **想知道 v1→v2 架构为什么改？** `DEEP-ANALYSIS-ARCHIVE-architecture.md` §1-§2
- **想知道 API / 数据流 / 配置？** `DEEP-ANALYSIS-ARCHIVE-operations.md` §4-§7
- **想知道部署 / 路线图 / 风险？** `DEEP-ANALYSIS-ARCHIVE-operations.md` §8-§10
- **想知道 v1 vs v2 vs 代码实际差距？** `DEEP-ANALYSIS-ARCHIVE-operations.md` 附录B
- **想知道当前规范？** 直接读 `SPEC.md`，不要依赖本归档文件

---

## 维护说明

- 本索引随 DEEP-ANALYSIS.md 拆分归档一同生成（2026-06-23），不随 SPEC 演进更新
- 归档文件为历史快照，不修改；仅本索引可更新以反映新的归档结构
- 活跃替代位置以实际 SPEC / TRACEABILITY / ACCEPTANCE 为准
