# xlib-standard 规格索引

本目录汇总 `/home/xlib-standard/.worktree/*.md`、`/home/xlib-standard/docs/**` 和 `/home/zone/Downloads/xlib-standard/**` 的分析结果。

## 工件

- `MODULE-SPEC.md`：完整模块规格，作为本次整理后的主规格。
- `TRACEABILITY.md`：规格条款到来源文件的追溯表。
- `CONFLICT-LEDGER.md`：冲突、历史计划和最终取舍。
- `COVERAGE-MANIFEST.md`：输入文件清单与覆盖口径。
- `SPEC.md`、`DEEP-ANALYSIS.md`：历史分析工件，保留旧口径和问题背景，不作为当前主规格。

## 阅读规则

- 当前可执行主规格以 `MODULE-SPEC.md` 为准；`TRACEABILITY.md`、`CONFLICT-LEDGER.md` 和 `COVERAGE-MANIFEST.md` 是配套约束。
- `SPEC.md` 与 `DEEP-ANALYSIS.md` 中的 181 文件、17+ gates、66 gates、10 ADR 等数字均为历史口径，不得覆盖本次 154 文件覆盖口径。
- 下游采用、release-ready、远端 ruleset/CI 状态必须由下游仓库或远端证据证明；本目录只记录本地分析、要求和风险。
- `1000-pass` 只表示输入文件集合和清单稳定性检查，不表示每条语义经过 1000 次独立审查。

## 交付边界

- 本目录可作为本地规格整理包；只有 `git status`、commit、tag 或 release artifact 能证明它已经进入版本控制或发布边界。
- 未运行远端 API、CI artifact、ruleset export 或下游仓库验证前，不得声明 branch protection/ruleset enabled、release-ready 或 downstream adopted。
- 修改输入范围后，必须同时更新 `MODULE-SPEC.md`、`TRACEABILITY.md`、`CONFLICT-LEDGER.md` 和 `COVERAGE-MANIFEST.md`。

## 覆盖口径

本次输入共 154 个文件：

- `.worktree/*.md`：12 个。
- `/home/xlib-standard/docs/**`：121 个。
- `/home/zone/Downloads/xlib-standard/**`：21 个。

权威顺序：

1. `/home/xlib-standard/docs/standard/**` 与根级 `docs/*.md` 的当前标准条款。
2. `/home/xlib-standard/docs/testing/**`、`docs/l2/**`、`docs/evidence/**` 的领域补充。
3. `/home/xlib-standard/.worktree/*.md` 与 Downloads 中的计划、复盘、历史审查和迁移目标。
4. 当来源冲突时，以当前标准条款为可执行事实，以历史计划作为风险和迁移目标记录。
