# xlib-standard 规格索引

本目录是 `github.com/ZoneCNH/xlib-standard` 上游仓库在本仓库的 **本地分析快照**。汇总自 `.worktree/*.md`、`docs/**` 与外部规划文档的整理结果，作为本仓库（`ZoneCNH/ZoneCNH`）架构索引的一部分。

## 上游引用

| 字段 | 值 |
|------|----|
| Upstream | `github.com/ZoneCNH/xlib-standard` |
| Snapshot Date | 2026-06-07 |
| Upstream Commit | `93753b30e6d01fb4a9b096acaa0d7d53a2fb231c`（= remote tag `v0.6.5`，tree `296e3b91…`，pinned 2026-06-08 04:59 +08:00） |
| 本目录角色 | 上游规格的本地分析快照，**不是**上游 SSOT；任何冲突以上游 `docs/standard/**` 为准 |
| 本仓库角色 | 文档枢纽，仅承载分析结果，不承载实现源码 |

## 当前权威工件

- `SPEC.md`：**当前可执行主规格**（v2.0.1, Status: Review；52 FR、104 WHEN/THEN、10 EC、17 TC、7 BR、17 AC；23 节按 `SPEC-TEMPLATE.md` 对齐；TRACEABILITY 来源覆盖 100%，证�
��类型按 `line` / `file` / `validator-output` 分层），与追溯表、冲突账本和
覆盖清单共同约束。进入 Approved 的前置条件见 SPEC.md 顶部"状态说明"与 `docs/report/xlib-standard-structural-deep-analysis-20260608-0446.md`。
- `TRACEABILITY.md`：`SPEC.md` 条款到来源文件的追溯表（章节级，非 rule 级）。
- `CONFLICT-LEDGER.md`：冲突、历史计划和最终取舍。
- `COVERAGE-MANIFEST.md`：输入文件清单与覆盖口径（154 个文件，相对 `<upstream>/` 路径）。
- `REMOTE-EVIDENCE.md`：远端治理真证据（branch protection / rulesets / release object / CI runs，pinned 2026-06-08 05:15 +08:00）。

## 已归档工件

原 `archive/` 目录的历史文件已迁移至 `docs/report/`，不再位于本目录下：

- `docs/report/xlib-standard-module-spec-archived.md`：历史 20 节整理工件。
- `docs/report/xlib-standard-deep-analysis-archived.md`：181 文件旧口径深度分析。
- 归档工件 **不得** 作为当前规格、追溯、冲突取舍或门禁事实引用，仅供溯源比对。

## 阅读规则

- 当前可执行主规格以 `SPEC.md` 为准；结构一致性检查聚焦 FR 连续性、WHEN/THEN 子句、追溯完整性和冲突账本取舍。
- `TRACEABILITY.md` 是条款级来源矩阵，不是逐规则证明账本；需要内容级复现时必须提供 source pack、digest/tree sha 或重新生成覆盖清单。
- 下游采用、release-ready、远端 ruleset/CI 状态必须由下游仓库或远端证据证明；本目录只记录本地分析、要求和风险。
- `1000-pass` 只表示输入文件集合和清单稳定性检查，不表示每条语义经过 1000 次独立审查。
- 本目录所有结论都是分析快照，不能替代上游真源。当上游 `docs/standard/**` 与本快照冲突时，以上游为准并同步更新本目录。

## 交付边界

- 本目录可作为本地规格整理包；只有 `git status`、commit、tag 或 release artifact 能证明它已经进入版本控制或发布边界。
- 未运行远端 API、CI artifact、ruleset export 或下游仓库验证前，不得声明 branch protection/ruleset enabled、release-ready 或 downstream adopted。
- 覆盖清单使用相对上游仓库根的路径；跨机器复现仍需要 source pack、digest 或重新生成覆盖清单。
- 修改输入范围后，必须同时更新 `SPEC.md`、`TRACEABILITY.md`、`CONFLICT-LEDGER.md` 和 `COVERAGE-MANIFEST.md`；归档工件不再随主规格更新。

## 覆盖口径

本次输入共 154 个文件：

- `.worktree/*.md`：12 个。
- `<upstream-root>/docs/**`：121 个。
- `<external-downloads>/**`：21 个。

权威顺序：

1. `<upstream-root>/docs/standard/**` 与根级 `docs/*.md` 的当前标准条款。
2. `<upstream-root>/docs/testing/**`、`docs/l2/**`、`docs/evidence/**` 的领域补充。
3. `<upstream-root>/.worktree/*.md` 与 Downloads 中的计划、复盘、历史审查和迁移目标。
4. 当来源冲突时，以当前标准条款为可执行事实，以历史计划作为风险和迁移目标记录。
