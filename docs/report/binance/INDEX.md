# docs/report/binance/ 索引

> 本目录保存 binance 模块治理、深度分析、执行计划与证据报告。runtime 完成度声明必须来自 fresh `/home/binance` 命令证据，不能由文档报告替代。

## 当前报告

| 报告 | 日期 | 用途 | 状态 |
|---|---|---|---|
| [governance-closure-20260623.md](./governance-closure-20260623.md) | 2026-06-23 | #869/#871/#893/#894/#895/#896 收口审计 | #869 本地 runtime 证据闭合；文档治理项收口 |
| [commit-coverage-audit-20260623.md](./commit-coverage-audit-20260623.md) | 2026-06-23 | #896 newest 50 preserve/stash/backup/WIP candidate 本地覆盖矩阵 | 部分满足；需 PR/head 元数据 |
| [goal-execution-plan-20260622.md](./goal-execution-plan-20260622.md) | 2026-06-22 | binance Goal 执行路线与 AC-1~AC-9 验收计划 | 82→95 目标路线 |
| [iteration-plan-20260622.md](./iteration-plan-20260622.md) | 2026-06-22 | 5 份报告 + 12 issues 收敛为 backlog 与阶段路线 | 当前迭代计划 |
| [deep-analysis-20260622-v5-cleansing-processing-gaps.md](./deep-analysis-20260622-v5-cleansing-processing-gaps.md) | 2026-06-22 | 清洗与处理链路缺口分析 | 当前专题分析 |
| [deep-analysis-20260622-v4.md](./deep-analysis-20260622-v4.md) | 2026-06-22 | 历史数据 vs 实时数据缺口 | 当前专题分析 |
| [deep-analysis-20260622-v3.md](./deep-analysis-20260622-v3.md) | 2026-06-22 | 治理漂移分析 | 当前专题分析 |
| [deep-analysis-20260622-v2.md](./deep-analysis-20260622-v2.md) | 2026-06-22 | 修复链复盘与 runtime 阻断复核 | 82/100 |
| [deep-analysis-20260622.md](./deep-analysis-20260622.md) | 2026-06-22 | PR #850 基线分析 | 历史基线 |
| [business-types-coverage-20260622.md](./business-types-coverage-20260622.md) | 2026-06-22 | Spot/合约/期权/订单簿覆盖分析 | 当前专题分析 |

## 维护规则

1. 新增 binance 报告时同步更新本文件和 `docs/report/INDEX.md`。
2. 报告可以引用 runtime 命令输出，但不能把文档推断写成 runtime PASS。
3. 历史分析保留可追溯性；当前权威状态优先看 `module/binance/STANDARD.md`、`SPEC.md`、`TRACEABILITY.md` 与 fresh runtime evidence。
