# xlib_standard 分析索引

本目录是 `github.com/ZoneCNH/xlib_standard` 上游仓库在本仓库的 **本地分析快照**。汇总自 `.worktree/*.md`、`docs/**` 与外部规划文档的整理结果，作为本仓库（`ZoneCNH/ZoneCNH`）架构索引的一部分；它不是上游 SSOT，也不是可执行规格。

模块级文档 `goal.md` 和 `SPEC.md` 位于本目录根，定义 xlib_standard 的五类职责（标准事实源、Go Reference Template、Generator、Harness Gate、Evidence Runtime，引自 CONSTITUTION.md P2 / ARCHITECTURE.md）。分析快照文件（`ANALYSIS.md`、`FR-DETAIL.md` 等）是对上游仓库标准的本地整理，不替代模块级文档。

## 上游引用

| 字段            | 值                                                                                                                      |
| --------------- | ----------------------------------------------------------------------------------------------------------------------- |
| Upstream        | `github.com/ZoneCNH/xlib_standard`                                                                                      |
| Snapshot Date   | 2026-06-08（原始快照）/ 2026-06-12（文档对齐更新）                                                                      |
| Upstream Commit | `93753b30e6d01fb4a9b096acaa0d7d53a2fb231c`（= remote tag `v0.6.5`，tree `296e3b91…`，pinned 2026-06-08 04:59 +08:00）   |
| Upstream HEAD   | `09c9ec2`（tag `v1.0.0`，2026-06-12 文档-代码对齐基准）                                                                 |
| 本目录角色      | 上游规格的本地结构分析快照 + 可执行规格（goal.md + SPEC.md），**不是**上游 SSOT；任何冲突以上游 `docs/standard/**` 为准 |
| 本仓库角色      | 文档枢纽，承载分析结果与可执行规格，不承载实现源码                                                                      |

## 模块定位

`xlib_standard` 是本仓库的本地分析快照目录，同步自上游 `github.com/ZoneCNH/xlib_standard`。模块承担五类职责：

| 角色                  | 职责                               | 权威工件                  |
| --------------------- | ---------------------------------- | ------------------------- |
| Standard Source       | xlib 体系的文档规范与工程标准      | `goal.md`（标准定义）     |
| Go Reference Template | 可编译、可测试的 Go 基础库参考模板 | `SPEC.md`（可执行规格）   |
| Generator             | 模板渲染与独立 Go module 生成      | 上游 `render_template.sh` |
| Harness Gate          | CI 门禁与边界检查                  | 上游 `make ci`（17 gate） |
| Evidence Runtime      | release manifest 与发布证据生成    | 上游 `release_check.sh`   |

本目录分析快照的真实源是上游仓库的 `docs/standard/**`。当快照与上游冲突时，以上游当前标准为准。

## 当前权威工件

- `goal.md`：模块 1.0 Goal 定位与五角色定义。**模块级权威入口**。
- `SPEC.md`：后四类职责（Template / Generator / Gate / Evidence Runtime）的可执行规格。**代码级权威入口**。
- `ANALYSIS.md`：本地结构分析入口；只保留事实层级、关键数字、职责拆分和冲突总览，不声明可执行生命周期状态。
- `FR-DETAIL.md`：14 条 FR 的 SPEC.md 索引（2026-06-12 收缩自原 52 条占位 FR）。完整 WHEN/THEN 行为细节见 `SPEC.md` §7。
- `INDEX.md`：上游 SSOT 索引；列出 `docs/standard/` 27 个文件、9 个 Accepted ADR 与 `harness.yaml` gate section。
- `analysis/rules.md`：规则源、`BR-NNN` / `RULE-CORE-NNN`、Debt Governance 分析。
- `analysis/template.md`：Go 参考模板、公共 API、Generator 与边界场景分析。
- `analysis/runtime.md`：Harness、goalcli、Evidence Runtime 与 `xlib-TC-001..xlib-TC-017` 分析。
- `analysis/governance.md`：仓库治理、采纳状态机、远端治理边界与 TRUTH 同义引用表。
- `TRACEABILITY.md`：`ANALYSIS.md` 条款到来源文件的追溯表（章节级，非 rule 级）。FR 来源锚定 52/52；其中行级 49、file 1、validator-output 2，不等于语义验证完整。
- `CONFLICT-LEDGER.md`：同一 SSOT 内部硬冲突与取舍。
- `SNAPSHOT-BOUNDARY.md`：分析快照 vs 上游/远端/下游现实的边界条目。
- `COVERAGE-MANIFEST.md`：输入文件清单与覆盖口径（154 个文件，相对 `<upstream>/` 路径）。
- `REMOTE-EVIDENCE.md`：远端治理 pinned 证据（branch protection / rulesets / release object / CI runs，pinned 2026-06-08 05:15 +08:00）。

## 历史与归档工件

原 `archive/` 目录的历史文件已迁移至 `report/`，旧 `SPEC.md` 23 节整理稿只保留归档说明；这些历史内容不再作为当前分析、lint 或 independent review verdict 的入口：

- `SPEC.md`（旧 23 节整理稿）：已于 2026-06-12 去归档化恢复为可执行规格，当前权威入口见 `SPEC.md`（后四角色）和 `goal.md`（第一角色）。此条仅保留供溯源比对。
- `report/xlib_standard-module-spec-archived.md`：历史 20 节整理工件。
- `report/xlib_standard-deep-analysis-archived.md`：181 文件旧口径深度分析。
- 历史工件 **不得** 作为当前分析、追溯、冲突取舍或门禁事实引用，仅供溯源比对。

## 阅读规则

- `goal.md` 是本目录模块级权威定位文档，定义 xlib_standard 五类职责（引自 CONSTITUTION.md P2 / ARCHITECTURE.md）。
- `SPEC.md` 是本目录模块级可执行交付规格，覆盖后四类职责的 FR / AC / TC。
- `ANALYSIS.md` 是本仓库分析入口；真正可执行标准位于上游 `docs/standard/**`、`docs/*.md`、`.agent/harness/harness.yaml` 与相关 runtime artifact。
- `INDEX.md` 只索引上游裁决标准位置，不在本仓库声明 gate / No-Go / DoD 已通过。
- `TRACEABILITY.md` 是条款级来源矩阵，不是逐规则证明账本；需要内容级复现时必须提供 source pack、digest/tree sha 或重新生成覆盖清单。
- 下游采用、release-ready、远端 ruleset/CI 状态必须由下游仓库或远端证据证明；本目录只记录本地分析、要求和风险。
- `1000-pass` 只表示输入文件集合和清单稳定性检查，不表示每条语义经过 1000 次独立审查。
- 本目录所有结论都是分析快照，不能替代上游真源。当上游 `docs/standard/**` 与本快照冲突时，以上游为准并同步更新本目录。
- **三级阅读规则**：
  1. 需要理解模块身份与标准定义 → 先读 `goal.md`
  2. 需要实现/验证可执行交付物 → 读 `SPEC.md`
  3. 需要了解分析快照结构 → 读 `ANALYSIS.md` 和 `INDEX.md`

## 事实边界

- 本目录是可执行规格与分析快照的混合体。`goal.md` 和 `SPEC.md` 是当前模块的权威规格定义，其余分析文件是本地快照。只有 `git status`、commit、tag 或 release artifact 能证明它已经进入版本控制或发布边界。
- 未运行远端 API、CI artifact、ruleset export 或下游仓库验证前，不得声明 branch protection/ruleset enabled、release-ready 或 downstream adopted。
- 覆盖清单使用相对上游仓库根的路径；跨机器复现仍需要 source pack、digest 或重新生成覆盖清单。
- 快照边界条目统一见 `SNAPSHOT-BOUNDARY.md`；不要把边界条目误读为同一 SSOT 内部硬冲突。
- 修改输入范围后，必须同时更新 `ANALYSIS.md`、`INDEX.md`、`TRACEABILITY.md`、`CONFLICT-LEDGER.md`、`SNAPSHOT-BOUNDARY.md` 和 `COVERAGE-MANIFEST.md`；归档工件不再随当前分析更新。

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
