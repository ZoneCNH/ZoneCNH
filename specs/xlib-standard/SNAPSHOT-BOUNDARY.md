# xlib-standard 快照边界账本

本文件收纳“本地分析快照 vs 上游/远端/下游现实”的边界条目。它们不是同一 SSOT 内部硬冲突，因此不再放入 `CONFLICT-LEDGER.md`。

- Snapshot-Date: 2026-06-08
- Upstream-Commit: `93753b30e6d01fb4a9b096acaa0d7d53a2fb231c` (v0.6.5)
- Analysis-Version: v3.1.0

| # | 边界条目 | 口径 |
|---:|----------|------|
| B-01 | strict-config 迁移目标 vs 当前路径现实 | `.config/xlib` 是迁移目标；当前上游仍有 `.agent/**`、`.xlib/**`、registry、policy 和 evidence ledger。 |
| B-02 | adoption proof vs downstream sync plan | 同步计划、patch-only、registry 记录不得升级为 adopted；需要下游 commit、gate output、proof schema 和 rollback。 |
| B-03 | L2 readiness vs release | T3 才是首个 release-allowed 阶段；T0/T1/T2 不等于可发布。 |
| B-04 | 远端治理证明 | 本地 Markdown 不能证明 branch protection、ruleset、required checks 或 release object 当前启用。 |
| B-05 | v1.0.0 状态 | Downloads 中 v1.0.0 checklist 是目标/计划，不是本地已发布事实。 |
| B-06 | 154 文件整理口径 vs 181 文件旧分析口径 | 当前快照以 154 文件为准；181 文件仅为历史分析背景。 |
| B-07 | gate 口径 | 66 个 harness.yaml 条目是当前索引口径；旧 Required family 说法只作历史背景。 |
| B-08 | 1000-pass 语义边界 | `1000-pass` 只证明输入文件集合和清单稳定，不证明逐条语义审查完成。 |
| B-09 | 整理完成 vs 版本控制/发布交付 | 本地文件存在不等于已提交、已发布或被下游采用。 |
| B-10 | 条款级追溯 vs 逐规则证明账本 | `TRACEABILITY.md` 是条款级来源矩阵，不是 rule-level proof ledger。 |
| B-11 | 本机绝对路径清单 vs 可移植 source bundle | `COVERAGE-MANIFEST.md` 的本机路径需要 source pack、路径映射或重新生成才能跨环境复现。 |

## 使用规则

- 本仓库只记录本地分析、追溯锚点和 pinned 远端证据。
- 任何 release-ready、adopted、remote-enabled 结论必须回到上游 artifact、GitHub API、CI artifact 或下游仓库证据。
- 当本文件与上游当前 `docs/standard/**` 冲突时，以上游为准并刷新快照。
