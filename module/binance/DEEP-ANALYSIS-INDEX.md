# DEEP-ANALYSIS.md 分区索引

> 本文档是 `DEEP-ANALYSIS.md`（1029 行，~51KB）的导航索引，解决 P2-1 "Split oversized DEEP-ANALYSIS.md" 的可维护性问题。
>
> DEEP-ANALYSIS.md 已归档（2026-06-22），当前权威规范以 `SPEC.md` v3.5.0 + `TRACEABILITY.md` v3.5.0 为准。本索引仅供历史查阅导航。

---

## 分区概览

| 分区 | 行号 | 主题 | 当前状态 |
|------|------|------|----------|
| §0 | 11-16 | 分布式架构约束 | 已迁移至 `SPEC.md` §4 Goals + FR-011 |
| §1 | 17-76 | 当前架构评估 (v1.0.1 基线) | 历史参考；当前架构见 `SPEC.md` §2 |
| §2 | 78-156 | 目标架构设计 | 已落地到 `SPEC.md` §2 + `IMPLEMENTATION-PLAN.md` |
| §3 | 158-531 | 六模块集成详案 (natsx/redisx/postgresx/taosx/kafkax/ossx) | 已落地到 `SPEC.md` FR-003~FR-011 |
| §4 | 533-659 | Gin Web API 设计 | 已落地到 `SPEC.md` FR-007/FR-007a |
| §5 | 661-711 | 完整数据流 | 已落地到 `SPEC.md` Appendix C.2 |
| §6 | 713-780 | 目录结构变更 | 已落地到 `IMPLEMENTATION-PLAN.md` §4 |
| §7 | 782-866 | 配置设计 | 已落地到 `SPEC.md` §11 Config |
| §8 | 868-914 | 部署拓扑 | 已落地到 `IMPLEMENTATION-PLAN.md` |
| §9 | 916-962 | SPEC 升级路线图 | 已执行；当前 SPEC v3.5.0 |
| §10 | 964-976 | 风险与缓解 | 部分已解决；剩余跟踪见 `ARCHITECTURE-DRIFT-WATCHLIST.md` |
| §11 | 978-989 | 开放问题 | 部分已闭合；未闭合项见 `docs/report/binance/` 系列报告 |
| §12 + 附录 A/B | 991-1030 | 代码实态审计 + 差距总结 | 已迁移至 `docs/migrations/binance-v2-upgrade.md` |

---

## 快速跳转

- **想知道 v1→v2 架构为什么改？** 跳转 §1-§2 (行 17-156)
- **想知道 natsx/redisx/taosx 怎么集成？** 跳转 §3 (行 158-531)
- **想知道 API 设计？** 跳转 §4 (行 533-659)
- **想知道 v1 vs v2 vs 代码实际差距？** 跳转附录 A/B (行 991-1030)
- **想知道当前规范？** 直接读 `SPEC.md`，不要依赖本归档文件

---

## 维护说明

- 本索引随 DEEP-ANALYSIS.md 一同归档，不随 SPEC 演进更新
- 若 DEEP-ANALYSIS.md 行号因编辑漂移，同步更新本索引对应行号
- 新增分区时在本索引追加对应行
