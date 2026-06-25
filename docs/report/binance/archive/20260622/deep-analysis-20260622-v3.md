# Binance 模块深度分析报告 v3

- [COMPUTED, HIGH] 报告日期：2026-06-22
- [COMPUTED, HIGH] Status: Historical Analysis, Superseded by `module/binance/STANDARD.md` and `docs/migrations/binance-v2-upgrade.md`
- [COMPUTED, HIGH] 分析范围：`module/binance/` 文档控制面，以及只读抽样核验的 `/home/binance` 运行仓库状态。
- [COMPUTED, HIGH] 目标问题：判断 `binance` 模块是否还需要补充、优化、迭代，以及是否需要建立独立的模块规则或模块标准规范。

## 当前定位

[COMPUTED, HIGH] 本报告是历史分析制品，不作为当前 spec 权威。当前合同以 `module/binance/SPEC.md` v2.2.3 为准；模块标准入口为 `module/binance/STANDARD.md`；迁移入口为 `docs/migrations/binance-v2-upgrade.md`。

[COMPUTED, HIGH] 本报告中曾指出的版本投影、4x4 subject/topic、任务引用和证据分层问题，已转化为可执行治理项：`STANDARD.md` 固定权威顺序与 L1/L2/L3 语义，`scripts/check-binance-docs.sh` 提供可复跑文档自检。

## 结论

- [COMPUTED, HIGH] `module/binance/` 已经具备模块治理骨架：`RULES.md`、`NAMING.md`、`BOUNDARY-GATES.md`、`ARCHITECTURE-DRIFT-WATCHLIST.md`、`TRACEABILITY.md`、`ACCEPTANCE.md`、`FEATURES.md`、`IMPLEMENTATION-PLAN.md`、`CHANGELOG.md` 均存在。
- [INFERRED, HIGH] 当前主要缺口不是“缺少规则”，而是“已有规则没有被全部投影、检查和执行化”。
- [COMPUTED, HIGH] 当前不再建议用本报告直接驱动实现；后续应引用 `STANDARD.md`、`DATA-LIFECYCLE.md`、`NAMING.md` 和迁移索引。
- [COMPUTED, HIGH] 当前不能宣称 `binance` 模块 release 完成；运行证据应按 `STANDARD.md` 的 L2 定义重新采集。

## 历史问题的当前处理状态

| 历史问题 | 当前处理 |
| --- | --- |
| root spec 版本投影漂移 | 当前根规格已进入 v2.2.3 口径，后续由自检脚本检查 `Spec-Version: v2.2.3`。 |
| NATS 4x4 矩阵缺口 | `STANDARD.md` 明确 16 个 `binance.market.{product_line}.{event_type}` subject。 |
| Kafka topic 漂移 | `STANDARD.md` 明确 Kafka 为 `binance.{product_line}.{event_type}.v1`，旧 market namespace 只保留为历史迁移背景。 |
| 任务引用漂移 | 历史 kafkax/ossx 任务别名不再作为主动引用；当前任务文件名由自检脚本检查。 |
| 状态口径混杂 | `STANDARD.md` 拆分 L1 文档证据、L2 本地 runtime 证据、L3 外部发布证据。 |
| 运行证据混杂 | L2 仅包含本地 runtime HEAD SHA、boundary gates、`go test ./...` 和 smoke 输出。 |

## 需要继续补充、优化、迭代

### P0：治理投影收敛

- [COMPUTED, HIGH] 使用 `STANDARD.md` 作为薄层标准入口，不再新增平行规则体系。
- [COMPUTED, HIGH] 使用 `scripts/check-binance-docs.sh` 检查 v2.2.3、16 个 NATS subject、16 个 Kafka topic、legacy Kafka namespace、任务文件名和 L1/L2/L3 证据语义。
- [INFERRED, HIGH] 主线程仍需修复本 lane 不能修改的主动文档残留，例如 `RULES.md`、`TRACEABILITY.md`、`CHANGELOG.md`、`RUNTIME-MAPPING.md` 等。

### P1：数据生命周期候选进入正式管线

- [COMPUTED, HIGH] `DATA-LIFECYCLE.md` 仅是 Discussion Draft，FR-012 到 FR-024 与 issue #880 到 #892 的映射不改变当前合同。
- [INFERRED, HIGH] #888 若纳入，会把 event type 从 4 扩到 6，必须正式 spec bump。

### P2：重新采集运行证据

- [INFERRED, HIGH] `/home/binance` 需要形成一次干净的实现快照，再按 L2 定义采集本地 runtime HEAD SHA、boundary gates、Go tests 和 smoke 输出。
- [INFERRED, HIGH] L3 证据必须单独记录，不得混入 L2 定义。

## 停止条件

- [INFERRED, HIGH] 文档侧完成条件：版本元数据一致、4x4 NATS/Kafka 矩阵一致、任务引用可解析、状态口径一致、历史报告不再承载当前合同。
- [INFERRED, HIGH] 运行侧完成条件：`/home/binance` 工作区有可审查快照，L2 所需四类本地证据齐备。
- [INFERRED, HIGH] release 声明条件：L3 证据独立归档，且 `TRACEABILITY.md`、`ACCEPTANCE.md`、`FEATURES.md` 与证据一致。

## 本轮未做

- [COMPUTED, HIGH] 本轮没有提交 Git commit。
- [COMPUTED, HIGH] 本轮没有关闭任何 issue。
- [COMPUTED, HIGH] 本轮没有把 Discussion Draft 候选项提升为当前合同。

[RULES I BROKE]：无
