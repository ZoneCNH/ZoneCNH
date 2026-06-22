# Binance 模块深度分析报告 v3

- [COMPUTED, HIGH] 报告日期：2026-06-22
- [COMPUTED, HIGH] 分析范围：`module/binance/` 文档控制面，以及只读抽样核验的 `/home/binance` 运行仓库状态。
- [COMPUTED, HIGH] 目标问题：判断 `binance` 模块是否还需要补充、优化、迭代，以及是否需要建立独立的模块规则或模块标准规范。

## 结论

- [COMPUTED, HIGH] `module/binance/` 已经具备模块治理骨架：`RULES.md`、`NAMING.md`、`BOUNDARY-GATES.md`、`ARCHITECTURE-DRIFT-WATCHLIST.md`、`TRACEABILITY.md`、`ACCEPTANCE.md`、`FEATURES.md`、`IMPLEMENTATION-PLAN.md`、`CHANGELOG.md` 均存在。
- [INFERRED, HIGH] 当前主要缺口不是“缺少规则”，而是“已有规则没有被全部投影、检查和执行化”。
- [INFERRED, HIGH] 不建议立即另起一套平行的 `binance` 模块规则；应先修复现有规则与文档投影漂移，再考虑新增一个薄层 `STANDARD.md` 作为索引式标准入口。
- [COMPUTED, HIGH] 当前仍需要补充、优化和迭代，优先级最高的是版本元数据、4×4 主题矩阵、Kafka topic 命名、任务引用、状态口径和运行证据。
- [COMPUTED, HIGH] 当前不能宣称 `binance` 模块 release 完成；`TRACEABILITY.md` 记录实现进度为 `1/15 FR`、`7%`，`ACCEPTANCE.md` 的 Release DoD 仍为 Not Done。

## 关键证据

| 证据点 | 观察 | 影响 |
| --- | --- | --- |
| [COMPUTED, HIGH] 规则文件 | `module/binance/RULES.md` 已定义命名、4×4 矩阵、版本触发、状态一致性、归档隔离、验收同步、证据标签、PR 汇总、必备文档和边界门禁规则。 | [INFERRED, HIGH] 可以作为模块级规则基础，不需要从零新建规则体系。 |
| [COMPUTED, HIGH] 命名 SSOT | `module/binance/NAMING.md` 定义 4 条 product line：`spot`、`um_perp`、`cm_perp`、`options`；4 条 event type：`tick`、`trade`、`bar`、`depth`；NATS 和 Kafka 均要求 16 个组合。 | [INFERRED, HIGH] 后续所有 runtime mapping、SPEC、AC、server spec 都应以此为命名源。 |
| [COMPUTED, HIGH] README 元数据 | `module/binance/README.md:5` 仍写 `Spec-Version: v2.2.0 (root) / v2.1.1 (client) / v2.1.0 (server)`。 | [COMPUTED, HIGH] 这与当前根 `SPEC.md` 的 `v2.2.2` 不一致。 |
| [COMPUTED, HIGH] 根 SPEC 元数据 | `module/binance/SPEC.md:6` 当前为 `Spec-Version: v2.2.2`。 | [INFERRED, HIGH] README 的 root 版本投影应同步到 `v2.2.2`。 |
| [COMPUTED, HIGH] CHANGELOG | `module/binance/CHANGELOG.md` 已存在，且 `Doc-Version` 为 `v2.2.2`。 | [COMPUTED, HIGH] `CHANGELOG.md` 缺失问题已经被关闭。 |
| [COMPUTED, HIGH] RUNTIME-MAPPING 主题矩阵 | `RUNTIME-MAPPING.md` 的 NATS subject 抽样计数为 13 个唯一组合，而 `NAMING.md` 为 16 个组合。 | [COMPUTED, HIGH] `um_perp.trade`、`cm_perp.trade`、`options.trade` 在 runtime mapping 投影中缺失。 |
| [COMPUTED, HIGH] Kafka topic 漂移 | `NAMING.md` 规定 Kafka topic 为 `binance.{product_line}.{event_type}.v1`，但 `SPEC.md`、`ACCEPTANCE.md` 和 `RUNTIME-MAPPING.md` 仍出现 `binance.market.{product_line}.{event_type}` 或 `binance.market.ticks` 等旧式聚合 topic。 | [INFERRED, HIGH] Kafka topic 命名需要统一到 `NAMING.md`，否则实现、验收和文档会继续分叉。 |
| [COMPUTED, HIGH] 任务引用漂移 | `RULES.md` 引用了 `TASK-BINANCE-SERVER-014-kafkax-export.md` 和 `TASK-BINANCE-SERVER-016-ossx-archive.md`，实际任务文件名分别使用 `kafkax-dispatch` 与 `ossx-archiver`。 | [COMPUTED, HIGH] 规则中的任务引用需要修正。 |
| [COMPUTED, HIGH] 状态漂移 | `TRACEABILITY.md` 将部分边界测试标为 PASS；`ACCEPTANCE.md` 和 `FEATURES.md` 对部分 TC、BR 或 release 证据仍保留 Pending / Not Done 口径。 | [INFERRED, HIGH] 状态字段需要按“文档门禁通过”和“运行证据通过”分层表达。 |
| [COMPUTED, HIGH] 运行仓库状态 | `/home/binance` 当前存在大量未提交改动，包含 `cmd/`、`go.mod`、`internal/client`、`internal/server`、`internal/wire`、`tools` 等范围。 | [INFERRED, HIGH] 运行仓库仍处在实现整理期，不适合作为 release 完成证据。 |
| [COMPUTED, HIGH] 运行依赖抽样 | `/home/binance/go.mod` 抽样可见 `clickhousex`、`kafkax`、`natsx`、`ossx`、`taosx`、`gin` 等直接依赖。 | [INFERRED, MED] 依赖方向正在靠近文档要求，但仍需由运行仓库边界脚本和 CI 输出确认。 |

## 需要补充、优化、迭代

### P0：先修复治理漂移

- [COMPUTED, HIGH] 修正 `README.md` 版本摘要，把 root spec 版本从 `v2.2.0` 同步到当前 `v2.2.2`。
- [COMPUTED, HIGH] 修正 `RUNTIME-MAPPING.md` 的 NATS 4×4 矩阵，补齐 `um_perp.trade`、`cm_perp.trade`、`options.trade`。
- [COMPUTED, HIGH] 修正 Kafka topic 投影，把 `SPEC.md`、`ACCEPTANCE.md`、`RUNTIME-MAPPING.md` 中旧式 `binance.market.*` / 聚合 topic 收敛为 `NAMING.md` 的 `binance.{product_line}.{event_type}.v1`。
- [COMPUTED, HIGH] 修正 `RULES.md` 的任务文件名引用，使规则引用能被脚本或人工审查直接定位。
- [INFERRED, HIGH] 将 `TRACEABILITY.md`、`ACCEPTANCE.md`、`FEATURES.md` 的状态口径拆成至少两层：文档门禁状态和运行证据状态。

### P1：把规则变成可执行检查

- [INFERRED, HIGH] 新增或扩展文档一致性检查脚本，检查版本元数据、必备文档、任务引用、4×4 subject/topic 矩阵和状态词一致性。
- [INFERRED, HIGH] 将 `NAMING.md` 作为机器校验输入或结构化源，避免手工维护 16 个 NATS subject 与 16 个 Kafka topic 时继续漂移。
- [INFERRED, HIGH] 将 `RULES.md` 的 R1-R10 映射为可运行检查项，并在报告中输出 pass/fail 与失败文件位置。
- [INFERRED, MED] 给 docs repo 增加一个轻量命令，例如 `scripts/check-binance-docs.sh`，用于本仓库内的文档投影检查；运行仓库的 build/test/boundary gates 仍应留在 `/home/binance`。

### P2：补齐运行证据链

- [COMPUTED, HIGH] `IMPLEMENTATION-PLAN.md` 仍要求运行仓库通过 boundary script、go.mod direct dependency gate、runtime tests、lint 或 CI 证据后才可声明 release。
- [INFERRED, HIGH] `/home/binance` 需要形成一次干净的实现快照，再运行 `scripts/boundary-gates.sh`、Go 测试、lint、smoke 或最小集成测试。
- [INFERRED, HIGH] 运行证据产生后，再回填 `TRACEABILITY.md`、`ACCEPTANCE.md`、`FEATURES.md` 和 `CHANGELOG.md`，避免文档先行宣称实现完成。

## 是否需要建立 binance 模块规则或标准规范

- [INFERRED, HIGH] 需要模块标准，但不需要再建一套与 `RULES.md`、`NAMING.md`、`BOUNDARY-GATES.md` 平行的规则体系。
- [INFERRED, HIGH] 更合适的做法是把现有文件分工固定下来：`RULES.md` 管规则，`NAMING.md` 管命名 SSOT，`BOUNDARY-GATES.md` 管运行边界门禁，`ARCHITECTURE-DRIFT-WATCHLIST.md` 管架构漂移观察，`TRACEABILITY.md` 管 FR/BR/NFR/TC/AC 追踪，`ACCEPTANCE.md` 管验收状态，`FEATURES.md` 管功能投影，`IMPLEMENTATION-PLAN.md` 管执行顺序，`CHANGELOG.md` 管版本变更。
- [INFERRED, MED] 如果需要一个“模块标准规范”入口，建议新增 `module/binance/STANDARD.md`，但内容应是索引和强制优先级，不应复制各文件细节。
- [INFERRED, MED] `STANDARD.md` 的建议结构为：权威顺序、命名标准、边界标准、文档同步标准、验收标准、证据标准、禁止事项、检查命令。
- [INFERRED, HIGH] 在当前漂移未修复前，不建议先写完整长篇标准；新增标准会增加又一个需要同步的投影面。

## 建议迭代路线

1. [COMPUTED, HIGH] 关闭 P0 文档漂移：README 版本、RUNTIME-MAPPING 4×4、Kafka topic、RULES 任务引用、状态口径。
2. [INFERRED, HIGH] 增加 docs repo 的 `binance` 文档一致性检查脚本，先覆盖最容易漂移的机器可检字段。
3. [INFERRED, HIGH] 在 `/home/binance` 整理运行实现，拿到 boundary gates、test、lint、smoke 的真实输出。
4. [INFERRED, HIGH] 根据运行证据回填 `TRACEABILITY.md` 和 `ACCEPTANCE.md`，只把有证据的 FR/TC/AC 标为 Done/PASS。
5. [INFERRED, MED] 漂移关闭后，再新增薄层 `STANDARD.md` 作为模块标准入口。

## 停止条件

- [INFERRED, HIGH] 文档侧完成条件：版本元数据一致、4×4 NATS/Kafka 矩阵一致、任务引用可解析、状态口径一致、CHANGELOG 记录本轮变化。
- [INFERRED, HIGH] 运行侧完成条件：`/home/binance` 工作区有可审查快照，boundary gates、Go tests、lint 或 CI、smoke 测试输出可追溯。
- [INFERRED, HIGH] release 声明条件：`TRACEABILITY.md`、`ACCEPTANCE.md`、`FEATURES.md` 与运行证据一致，且 Release DoD 不再是 Not Done。

## 本轮未做

- [COMPUTED, HIGH] 本轮没有修改 `module/binance/` 现有治理文件。
- [COMPUTED, HIGH] 本轮没有运行 `/home/binance` 的测试、lint 或 boundary gates；只进行了文档侧分析和运行仓库只读抽样。
- [COMPUTED, HIGH] 本轮没有提交 Git commit。

[RULES I BROKE]：无
