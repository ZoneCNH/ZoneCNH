# report/ 索引

> 报告区分为**权威报告**与**历史档案**两类。修复 S-6 报告区冗余膨胀（2026-06-22）。

## 权威报告（最新）

每份报告应在文件名注明日期（YYYYMMDD），并在内容首部声明分析对象与数据来源。

| 报告 | 日期 | 主题 | 综合评分 |
|---|---|---|:---:|
| [solid-adaptation-20260703.md](./solid-adaptation-20260703.md) | 2026-07-03 | SOLID 规则适配分析与处置账本（外部模板 vs 宪法/编码规范逐条比对：70% 重叠 / 15% 冲突 / 15% 增量；Mock 契约一致性 + 依赖注入细则并入 go-coding-standards） | — |
| [audit-issues-20260625.md](./audit-issues-20260625.md) | 2026-06-25 | 架构审计 10 项 issue 状态总表（9 closed + 1 long-term open，PR #1098 修复落地） | — |
| [fred/iteration-plan-20260622.md](./fred/iteration-plan-20260622.md) | 2026-06-22 | fred 完整更新迭代方案（4 份报告 + 7 模块文件收敛，29 项 backlog，7 阶段路线，68→80+ 分） | 68/100 (D+) |
| [branch-governance-audit-20260622.md](./branch-governance-audit-20260622.md) | 2026-06-22 | Git 分支治理、同步与工作树审计 | — |
| [repo-naming-unification-20260620.md](./repo-naming-unification-20260620.md) | 2026-06-20 | 仓库命名统一方案 | — |

## 子目录

| 路径 | 说明 |
|---|---|
| [`binance/`](./binance/) | binance 模块深度分析（v2 评分权威；v3 治理漂移；v4 历史/实时缺口；iteration-plan 为收敛迭代方案；v1 保留 PR #850 基线） |
| [`fred/`](./fred/) | fred 模块深度分析（deep-analysis P0/P1 排序；data-issues 历史/实时/同步/清洗/缺口；ms_brain 下游契约；structural-score 68/42 分账本；iteration-plan 为收敛迭代方案） |
| [`goal/`](./goal/) | Goal 文档分析（2026-06-09 收尾，含 ISSUE-LEDGER 与 README） |
| [`archive/`](./archive/) | 历史档案区（已收敛的过程草稿） |
| [`archive/solid-template-20260703/`](./archive/solid-template-20260703/) | 外部通用 Go 量化 SOLID 规则模板原稿（未落地草案，已由 `solid-adaptation-20260703.md` 逐条处置后归档） |
| [`archive/xlib-20260608/`](./archive/xlib-20260608/) | xlib_standard 2026-06-08 单日多次产出（0341/0446/0459/0513/0530/0602 六个时间戳版本 + score-team），共 12 文件，已归档 |

## 命名约定

- **权威报告**：`<topic>-<YYYYMMDD>[-v<N>].md`，保留在 `report/` 根目录
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
| 2026-07-03 | 新增 `solid-adaptation-20260703.md`：SOLID 模板逐条处置账本；原模板归档至 `archive/solid-template-20260703/`；采纳项（Mock 契约一致性、依赖注入、接口稳定性、禁类型断言分支、读写/流式分离）同 PR 并入 `docs/standards/go-coding-standards.md` §6/§11 |
| 2026-06-25 | 新增 `architecture-structural-analysis-20260625-v1.md`：架构深度分析 v1（Supersedes 0622-v2；audit 52/52 PASS；综合 72/B；含 5 项短期修复落地：P1-1 事实层 verified_against 刷新+CI cron、P0-2 五模块 §8 Evidence 投影、P1-2 LIFECYCLE 主态+后缀补态、P1-3 AC ID 规范核实已完成、P2-1 核实取消） |
| 2026-06-23 | 新增 `binance/deep-analysis-20260622-backlog.md`：5 份深度分析（v1~v5）未完成项汇总，20 类问题逐条回核，11 已解决 / 9 剩余；新发现 STATUS/ARCHITECTURE spec 版本落后（v3.3.0 vs v3.4.0） |
| 2026-06-23 | 更新 `binance/github-issues-923-931-closure-ledger-20260623.md`：记录 #923-#931 已全部处于 GitHub Closed 状态，同时明确 issue tracking closure 不替代 runtime/release evidence |
| 2026-06-22 | 新增 `binance/goal-execution-plan-20260622.md`：Goal 执行方案（82→95 分，9 AC，7 阶段 × 26 issues，遵循 docs/goal/02-goal-standard.md） |
| 2026-06-22 | 新增 `binance/iteration-plan-20260622.md`：5 份报告 + 8 issues 收敛为 27 项 backlog + 7 阶段路线；补索引 v3/v4 条目 |
| 2026-06-22 | 新增 `fred/iteration-plan-20260622.md`：4 份报告 + 7 模块文件收敛为 29 项 backlog + 7 阶段路线；补 `fred/` 子目录条目 |
| 2026-06-22 | 新增 binance 深度分析 v3（治理漂移）+ v4（历史/实时数据缺口，13 条建议 FR-012~024）via PR #877 |
| 2026-06-22 | 新增 `binance/business-types-coverage-20260622.md`：业务类型覆盖深度分析 + Options depth 缺口（HIGH）+ 命名漂移（HIGH，3 套命名击穿 5 条管线）+ Runtime 核对建议（6 项 gh 命令清单） |
| 2026-06-22 | 新增 binance 深度分析 v1/v2（`binance/deep-analysis-20260622.md`、`binance/deep-analysis-20260622-v2.md`）+ 后续 P0/P1 修复（PR #852/#853）；评分 68→82 |
| 2026-06-22 | 创建 INDEX；归档 `xlib/` 13 文件至 `archive/xlib-20260608/`；区分权威报告与历史档案 |
