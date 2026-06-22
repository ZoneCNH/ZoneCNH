# docs/report/ 索引

> 报告区分为**权威报告**与**历史档案**两类。修复 S-6 报告区冗余膨胀（2026-06-22）。

## 权威报告（最新）

每份报告应在文件名注明日期（YYYYMMDD），并在内容首部声明分析对象与数据来源。

| 报告 | 日期 | 主题 | 综合评分 |
|---|---|---|:---:|
| [binance/governance-closure-20260623.md](./binance/governance-closure-20260623.md) | 2026-06-23 | binance governance closure review（#869 本地 runtime 证据闭合；#871/#893/#894/#895 文档治理收口；#896 部分满足） | — |
| [binance/commit-coverage-audit-20260623.md](./binance/commit-coverage-audit-20260623.md) | 2026-06-23 | binance #896 newest 50 preserve/stash candidate 本地覆盖审计 | — |
| [binance/goal-execution-plan-20260622.md](./binance/goal-execution-plan-20260622.md) | 2026-06-22 | binance Goal 执行方案（82→95 分目标，AC-1~AC-9，12 issue + FR-012~FR-024 分阶段验收） | 82→95 |
| [binance/iteration-plan-20260622.md](./binance/iteration-plan-20260622.md) | 2026-06-22 | binance 完整更新迭代方案（5 份报告 + 12 issues 收敛，27 项 backlog，7 阶段路线） | — |
| [fred/iteration-plan-20260622.md](./fred/iteration-plan-20260622.md) | 2026-06-22 | fred 完整更新迭代方案（4 份报告 + 7 模块文件收敛，29 项 backlog，7 阶段路线，68→80+ 分） | 68/100 (D+) |
| [fred/stage2-contracts-binding-20260622.md](./fred/stage2-contracts-binding-20260622.md) | 2026-06-22 | fred 阶段 2 产物：config mapping + API/Kafka/NATS/七介质契约 + domain_macro 绑定（发现 SPEC 模型与源码不一致） | — |
| [binance/deep-analysis-20260622-v4.md](./binance/deep-analysis-20260622-v4.md) | 2026-06-22 | binance 历史数据 vs 实时数据缺口（13 条建议 FR: FR-012~FR-024） | — |
| [binance/deep-analysis-20260622-v3.md](./binance/deep-analysis-20260622-v3.md) | 2026-06-22 | binance 治理漂移分析（命名 SSOT、Kafka topic、任务引用、状态口径） | — |
| [binance/business-types-coverage-20260622.md](./binance/business-types-coverage-20260622.md) | 2026-06-22 | binance 业务类型覆盖（Spot/合约/期权/订单簿）+ Options depth 缺口与命名漂移识别 | — |
| [binance/deep-analysis-20260622-v2.md](./binance/deep-analysis-20260622-v2.md) | 2026-06-22 | binance 模块修复链复盘与 runtime 阻断复核 | 82/100 (B+) |
| [branch-governance-audit-20260622.md](./branch-governance-audit-20260622.md) | 2026-06-22 | Git 分支治理、同步与工作树审计 | — |
| [architecture-structural-analysis-20260622.md](./architecture-structural-analysis-20260622.md) | 2026-06-22 | 架构深度分析与 P0 修复（entropy 迁移、4 占位移除） | 68/100 (C) |
| [architecture-deep-analysis-20260621-v2.md](./architecture-deep-analysis-20260621-v2.md) | 2026-06-21 | 跨文档版本一致性审计 v2 | 71/100 (B) |
| [architecture-structural-analysis-20260621.md](./architecture-structural-analysis-20260621.md) | 2026-06-21 | 早间结构性分析（v2 前身） | 68.6/100 (C) |
| [architecture-structural-repair-plan-20260621.md](./architecture-structural-repair-plan-20260621.md) | 2026-06-21 | 结构性修复计划 | — |
| [architecture-problem-analysis-20260620.md](./architecture-problem-analysis-20260620.md) | 2026-06-20 | 业务域实现度分析 | — |
| [repo-naming-unification-20260620.md](./repo-naming-unification-20260620.md) | 2026-06-20 | 仓库命名统一方案 | — |

## 子目录

| 路径 | 说明 |
|---|---|
| [`binance/`](./binance/) | binance 模块深度分析与治理报告（governance-closure / commit-coverage 为 2026-06-23 收口证据；v2 评分权威；v3 治理漂移；v4 历史/实时缺口；iteration-plan 为收敛迭代方案；goal-execution-plan 为 82→95 执行路线；v1 保留 PR #850 基线） |
| [`fred/`](./fred/) | fred 模块深度分析（deep-analysis P0/P1 排序；data-issues 历史/实时/同步/清洗/缺口；ms_brain 下游契约；structural-score 68/42 分账本；iteration-plan 为收敛迭代方案） |
| [`goal/`](./goal/) | Goal 文档分析（2026-06-09 收尾，含 ISSUE-LEDGER 与 README） |
| [`archive/`](./archive/) | 历史档案区（已收敛的过程草稿） |
| [`archive/xlib-20260608/`](./archive/xlib-20260608/) | xlib_standard 2026-06-08 单日多次产出（0341/0446/0459/0513/0530/0602 六个时间戳版本 + score-team），共 12 文件，已归档 |

## 命名约定

- **权威报告**：`<topic>-<YYYYMMDD>[-v<N>].md`，保留在 `docs/report/` 根目录
- **过程草稿**：单日多版本或后续被合并的中间产物，归入 `archive/<topic>-<YYYYMMDD>/`
- **修订版本**：以 `-v2`、`-v3` 后缀区分；旧版若已被新版完全覆盖，移入 `archive/`

## 维护原则

1. 每份报告必须可独立阅读（含分析范围、数据来源、证据标签）
2. 同一主题在同一日内产出 2 份以上时，应汇总为单份并将中间稿归档
3. archive/ 内容不可删除——保留作历史复盘依据，但不出现在主索引中
4. 本文件每次新增/归档报告时同步更新

## 变更历史

| 日期 | 变更 |
|---|---|
| 2026-06-23 | 新增 binance governance closure 与 commit coverage audit 索引；补 `docs/report/binance/` 子目录索引入口 |
| 2026-06-23 | 新增 `binance/goal-execution-plan-20260622.md`：补回 Goal 执行路线，记录 AC-1~AC-9、本地已关闭 issue 与外部门禁缺口 |
| 2026-06-22 | 新增 `binance/iteration-plan-20260622.md`：5 份报告 + 12 issues 收敛为 27 项 backlog + 7 阶段路线；补索引 v3/v4 条目 |
| 2026-06-22 | 新增 `fred/iteration-plan-20260622.md`：4 份报告 + 7 模块文件收敛为 29 项 backlog + 7 阶段路线；补 `fred/` 子目录条目 |
| 2026-06-22 | 新增 `fred/stage2-contracts-binding-20260622.md`：阶段 2 产物（config mapping + API/Kafka/NATS/七介质契约 + domain_macro 绑定，发现 SPEC §9 模型与 domain-macro v0.1.0 源码不一致） |
| 2026-06-22 | 新增 binance 深度分析 v3（治理漂移）+ v4（历史/实时数据缺口，13 条建议 FR-012~024）via PR #877 |
| 2026-06-22 | 新增 `binance/business-types-coverage-20260622.md`：业务类型覆盖深度分析 + Options depth 缺口（HIGH）+ 命名漂移（HIGH，3 套命名击穿 5 条管线）+ Runtime 核对建议（6 项 gh 命令清单） |
| 2026-06-22 | 新增 binance 深度分析 v1/v2（`binance/deep-analysis-20260622.md`、`binance/deep-analysis-20260622-v2.md`）+ 后续 P0/P1 修复（PR #852/#853）；评分 68→82 |
| 2026-06-22 | 创建 INDEX；归档 `xlib/` 13 文件至 `archive/xlib-20260608/`；区分权威报告与历史档案 |
