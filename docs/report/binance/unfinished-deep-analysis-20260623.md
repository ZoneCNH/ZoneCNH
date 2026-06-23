# Binance 深度分析未完成项汇总（2026-06-23）

- [COMPUTED, HIGH] 分析范围：`docs/report/binance/deep-analysis-20260622.md`、`deep-analysis-20260622-v2.md`、`deep-analysis-20260622-v3.md`、`deep-analysis-20260622-v4.md`、`deep-analysis-20260622-v5-cleansing-processing-gaps.md`。
- [COMPUTED, HIGH] 目标：从 2026-06-22 系列深度分析报告中抽取仍标记为未启动、未归档、未闭合、待补充或需进入正式管线的事项。
- [COMPUTED, HIGH] 判定口径：后续版本已声明修复的 v1 P0/P1 文档对齐项不再列入当前未完成清单；v2 之后仍保留或新增的 runtime、证据、治理投影、数据生命周期、清洗处理和 gap 缺口列为未完成。
- [COMPUTED, HIGH] 限制：2026-06-23 已在 `/home/binance` `fix/binance-issues` 采集 L1/local evidence，证据 commit 为 `66f60b3945dce215f68ff833bbd336364d635ae8`；未执行 L2/L3/live/release/external integration 验证。
- [COMPUTED, HIGH] 2026-06-23 后续 PR #936 / SPEC v3.5.0 已将 FR-012~030 纳入正式 SPEC/TRACEABILITY；本报告中“数据生命周期候选仍未进入正式管线”的旧口径保留为 PR #910 前后的历史复盘，当前缺口转为实现、测试、证据和 release。GitHub #923-#931 仍由当前 closure ledger 管理。

---

## 一、结论摘要

- [COMPUTED, HIGH] v1 明确称自身是 PR #850 历史基线，并声明 P0/P1 文档对齐项已由 PR #852/#853 与 v2 复核闭合（`deep-analysis-20260622.md:9`）。
- [COMPUTED, HIGH] v2 原始报告明确给出仍未启动的 P2 项：PR-007 runtime、TC-020 evidence、`internal/cs` 删除（`deep-analysis-20260622-v2.md:59`-`61`）；当前 L1/local evidence 已闭合 `internal/cs` 边界与 TC-020 local gate，但未闭合 PR-007 分布式 runtime。
- [COMPUTED, HIGH] v3 明确指出当前主要缺口不是缺规则，而是规则未全部投影、检查和执行化，且 release 运行证据需重新采集（`deep-analysis-20260622-v3.md:16`-`19`）；当前仅补入 L1/local 证据，release 证据仍缺失。
- [COMPUTED, HIGH] v4 将未覆盖范围扩展到实时控制面、历史数据生命周期、同步对象、同步周期和周期数据（`deep-analysis-20260622-v4.md:24`-`33`、`56`-`68`、`72`-`110`）。
- [COMPUTED, HIGH] v5 将未覆盖范围扩展到数据清洗、处理契约和 gap 检测，并汇总累计未明确问题 36 条、建议新增 FR 不少于 18 条（`deep-analysis-20260622-v5-cleansing-processing-gaps.md:156`-`166`）。

---

## 二、P0 未完成项

| 编号 | 未完成项                                                  | 当前证据                                                                                                                                                                                                                                      | 需要完成的闭环                                                                                                                          |
| ---- | --------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| P0-1 | [COMPUTED, HIGH] PR-007 runtime 仍是 release blocker。    | [COMPUTED, HIGH] v2 记录 runtime 13 个 FR 中 11 个仍为 Pending，TC-020 证据未归档，且 PR-007 是 A 等级唯一钥匙（`deep-analysis-20260622-v2.md:254`-`261`、`431`-`438`）。2026-06-23 L1/local evidence 只证明本地 boundary/smoke 健康，不闭合 PR-007a~g。 | [INFERRED, HIGH] 完成 PR-007a~g runtime 实施，闭合 standalone client、JetStream PubAck/ManualAck、durable storage/fanout/query 与 C/S 模块参考实现证据。 |
| P0-2 | [COMPUTED, HIGH] L1/local 运行证据已采集；L2/L3/release 证据仍缺失。 | [COMPUTED, HIGH] `/home/binance/release/evidence/binance/20260623/` 记录 SHA `66f60b3945dce215f68ff833bbd336364d635ae8`，`scripts/boundary-gates.sh` 10/10 PASS，`go build/test/race/vet`、`golangci-lint`、本地 smoke self-test PASS；未提供 live websocket、remote CI、release tag 或外部依赖集成证据。 | [INFERRED, HIGH] 补齐 L2/L3/live/release/external integration evidence，并将 release 声明与 TRACEABILITY/ACCEPTANCE/FEATURES 对齐。 |
| P0-3 | [COMPUTED, HIGH] 治理投影已由 PR #936 收敛；仍需防止历史报告误导当前状态。 | [COMPUTED, HIGH] v3 曾列出 `RULES.md`、`TRACEABILITY.md`、`CHANGELOG.md`、`RUNTIME-MAPPING.md` 等主动文档残留；PR #936 已将 SPEC/TRACEABILITY/CHANGELOG 等投影到 v3.5.0。 | [INFERRED, HIGH] 继续用 `check-binance-docs.sh` / `audit-status.py` 守门，避免历史报告被误当当前态。 |
| P0-4 | [COMPUTED, HIGH] 数据生命周期已进入正式提案；仍未进入 Spec -> Code 实现管线。 | [COMPUTED, HIGH] v3 曾指出 `DATA-LIFECYCLE.md` 只是 Discussion Draft；2026-06-23 已更新为 Formal Proposal / Runtime Pending，并通过 PR #936 / SPEC v3.5.0 / TRACEABILITY v3.5.0 登记 FR-012~FR-030。该投影不改变 runtime Done 状态。 | [INFERRED, HIGH] 将已登记的 FR-012~FR-030 推进到 Spec -> Review -> Matrix -> Tasks -> Plan -> Prompt -> Code 的实现/验证分支，并用 runtime/CI/release 证据关闭。 |

---

## 三、P1 未完成项：行情平台能力缺口

### 3.1 实时数据控制面

| 编号 | 未完成项                                       | 当前证据                                                                                                                                                            | 建议承载                                                                              |
| ---- | ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| P1-1 | [COMPUTED, HIGH] 同步对象选择规则缺失。        | [COMPUTED, HIGH] v4 R1 指出 `symbols.allow/deny` 空列表语义未定义；同步对象粒度、动态发现、配额、下线处理也未定义（`deep-analysis-20260622-v4.md:28`、`78`-`86`）。 | [INFERRED, HIGH] FR-012 Symbol Discovery & Filtering。                                |
| P1-2 | [COMPUTED, HIGH] 新合约动态发现缺失。          | [COMPUTED, HIGH] v4 R2 指出没有 FR 定义谁增量发现新 symbol（`deep-analysis-20260622-v4.md:29`）。                                                                   | [INFERRED, HIGH] exchangeInfo 周期拉取、instrument 事件、catalog 刷新。               |
| P1-3 | [COMPUTED, HIGH] K 线周期和深度档位未明确。    | [COMPUTED, HIGH] v4 R3/R4 指出 bar 订阅周期、spot/um_perp/cm_perp 深度档位未定义（`deep-analysis-20260622-v4.md:30`-`31`）。                                        | [INFERRED, HIGH] FR-014 Bar Interval Subscription Set 与 FR-015 Depth Snapshot Tier。 |
| P1-4 | [COMPUTED, HIGH] WS 重连策略与 REST 兜底缺失。 | [COMPUTED, HIGH] v4 R5/R6 指出没有重连退避曲线、最大窗口、最大尝试次数，也缺少 WS 断流期间 REST 补齐策略（`deep-analysis-20260622-v4.md:32`-`33`）。                | [INFERRED, HIGH] FR-013 WebSocket Connection Policy 与 REST fallback/gap fill 约束。  |

### 3.2 历史数据生命周期

| 编号 | 未完成项                                                           | 当前证据                                                                                                                                                                                 | 建议承载                                                                                         |
| ---- | ------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| P1-5 | [COMPUTED, HIGH] 历史数据冷启动回填缺失。                          | [COMPUTED, HIGH] v4 指出 SPEC 只覆盖热数据到冷数据的归档退潮，不覆盖历史初始化回填、断流补齐、全量校验、冷数据回热（`deep-analysis-20260622-v4.md:39`-`55`）。                           | [INFERRED, HIGH] FR-016 Historical Backfill on Cold Start。                                      |
| P1-6 | [COMPUTED, HIGH] 回填窗口、来源和同步周期未定义。                  | [COMPUTED, HIGH] v4 H1-H4 指出冷启动起点、回填深度、回填数据源、增量同步周期均未明确（`deep-analysis-20260622-v4.md:56`-`64`）。                                                         | [INFERRED, HIGH] Backfill 窗口、REST/第三方来源选择、周期调度表。                                |
| P1-7 | [COMPUTED, HIGH] gap 检测、gap fill 优先级、回填幂等和限流未定义。 | [COMPUTED, HIGH] v4 H5-H9 指出 gap 检测算法、补齐优先级、REST/WS 幂等 key、冷数据回热、REST throttle 均未明确（`deep-analysis-20260622-v4.md:64`-`68`）。                                | [INFERRED, HIGH] FR-017、FR-018、FR-019、FR-022、FR-023。                                        |
| P1-8 | [COMPUTED, HIGH] Funding rate 与 Mark price 等周期数据缺失。       | [COMPUTED, HIGH] v4 周期 grep 表显示缺少 Funding rate / Mark price 等非事件性周期数据，且建议 event_type 从 4 扩展到 6（`deep-analysis-20260622-v4.md:103`-`110`、`140`-`142`、`183`）。 | [INFERRED, HIGH] FR-020 Funding Rate / Mark Price Stream，并同步更新 NAMING/RULES/TRACEABILITY。 |
| P1-8a | [COMPUTED, HIGH] 日级全量对账任务未定义。 | [COMPUTED, HIGH] v4 将 FR-021 Daily Reconciliation Job 列为建议 FR，要求每日 04:00 UTC 按 symbol x 1d 做 OHLCV 对账；v5 继续把 Reconciliation 判为未覆盖阶段（`deep-analysis-20260622-v4.md:141`、`166`；`deep-analysis-20260622-v5-cleansing-processing-gaps.md:154`）。 | [INFERRED, HIGH] FR-021 Daily Reconciliation Job，并同步定义对账阈值、告警表和调度周期。 |
| P1-8b | [COMPUTED, HIGH] 回填进度 API 与订阅热重载未显式列入闭环。 | [COMPUTED, HIGH] v4 将 FR-023 Backfill Progress API 与 FR-024 Symbol Subscription Hot Reload 列为 P2 可观测性与治理项（`deep-analysis-20260622-v4.md:148`-`149`、`196`）。 | [INFERRED, HIGH] FR-023 管理端覆盖率/任务查询 API 与 FR-024 白黑名单热重载、`symbols.changed` 事件、客户端无重启增减 stream。 |

### 3.3 数据清洗、处理与缺口检测

| 编号  | 未完成项                                                              | 当前证据                                                                                                                                                                                                               | 建议承载                                                                                       |
| ----- | --------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| P1-9  | [COMPUTED, HIGH] 数据清洗能力未定义。                                 | [COMPUTED, HIGH] v5 C1-C8 列出 price/qty 值域、spike detector、timestamp sanity、乱序、depth update_id、bar 自洽、symbol 归一化、质量计数均缺失（`deep-analysis-20260622-v5-cleansing-processing-gaps.md:52`-`64`）。  | [INFERRED, HIGH] FR-025 Quality Validation。                                                   |
| P1-10 | [COMPUTED, HIGH] 数据处理契约无 FR 锚定。                             | [COMPUTED, HIGH] v5 P1-P7 指出 enricher/aggregator 无 FR，多周期 bar、VWAP/TWAP、Mark Price、basis、bar 闭合、watermark/late event policy 未定义（`deep-analysis-20260622-v5-cleansing-processing-gaps.md:81`-`91`）。 | [INFERRED, HIGH] FR-026 Watermark & Late Event Policy 与 FR-027 Processing Pipeline Contract。 |
| P1-11 | [COMPUTED, HIGH] gap 检测只有字段记账，无检测、报告、修复、验证链路。 | [COMPUTED, HIGH] v5 指出 `last_seq` 已写入但没有 FR 定义谁检测 gap、何时检测、检测到怎么办；G1-G4 四类 gap 全部未覆盖（`deep-analysis-20260622-v5-cleansing-processing-gaps.md:97`-`129`）。                           | [INFERRED, HIGH] FR-028 Gap Detection Multi-Dimensional 与 FR-029 Data Coverage SLA。          |

---

## 四、P2 未完成项：治理与可维护性

| 编号 | 未完成项                                                      | 当前证据                                                                                                                                                                       | 建议动作                                                                                     |
| ---- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------- |
| P2-1 | [COMPUTED, HIGH] `DEEP-ANALYSIS.md` 过大，仍需拆分。          | [COMPUTED, HIGH] v2 指出 `DEEP-ANALYSIS` 约 62KB 过大未处理，并把拆分列入剩余 +1 分项（`deep-analysis-20260622-v2.md:188`-`196`、`301`-`305`）。                               | [INFERRED, HIGH] 将历史长报告拆成 runtime、governance、data-lifecycle、evidence 等专题索引。 |
| P2-2 | [COMPUTED, HIGH] SPEC §4 分布式约束仍需上提。                 | [COMPUTED, HIGH] v2 将 SPEC §4 上提分布式约束列为剩余加分项（`deep-analysis-20260622-v2.md:301`-`305`）。                                                                      | [INFERRED, MED] 将 runtime 分布式协作约束从分析报告提升为 SPEC 主线合同。                    |
| P2-3 | [COMPUTED, HIGH] legacy `binance-market` 引用仍需压缩。       | [COMPUTED, HIGH] v2 指出 legacy `binance-market` 30+ 处未处理，并建议压缩到一处历史迁移说明（`deep-analysis-20260622-v2.md:188`-`196`、`306`、`397`-`398`）。                  | [INFERRED, HIGH] 保留单一历史迁移锚点，删除主动治理文档中的旧名漂移。                        |
| P2-4 | [COMPUTED, HIGH] 50 个 preserve/stash commit 覆盖矩阵未完成。 | [COMPUTED, HIGH] v2 指出新增 50 个 preserve/stash commit，需要覆盖审计且尚未生成 commit -> artifact 覆盖矩阵（`deep-analysis-20260622-v2.md:200`-`210`、`353`-`357`、`403`）。 | [INFERRED, HIGH] 建立 commit 覆盖矩阵，标注对应 spec、traceability、test 或明确废弃理由。    |
| P2-5 | [COMPUTED, HIGH] GateGuard/branch governance 流程仍有优化项。 | [COMPUTED, HIGH] v2 风险清单指出 GateGuard 的 PR 回滚和 branch governance 仍可能误判（`deep-analysis-20260622-v2.md:361`-`362`、`404`）。                                      | [INFERRED, MED] 将流程风险转为明确检查项或文档化例外。                                       |
| P2-6 | [COMPUTED, HIGH] v4/v5 治理影响台账已有正式提案落点，但实现证据仍缺失。 | [COMPUTED, HIGH] v4 估算新增 FR 13、AC ~30、TC ~20、BR 2、event_type 4 -> 6、新 taosx/postgresx 表和 Kafka topic；v5 累计扩大到 FR 18、AC ~45、TC ~32、BR 4、postgresx 表 5、metrics 8+（`deep-analysis-20260622-v4.md:177`-`187`；`deep-analysis-20260622-v5-cleansing-processing-gaps.md:184`-`191`）。2026-06-23 `DATA-LIFECYCLE.md` 已补 impact ledger。 | [INFERRED, HIGH] 保持 DATA-LIFECYCLE impact ledger 与 SPEC/TRACEABILITY/NAMING Pending 投影一致，并继续阻断 runtime Done 翻转，直到证据闭合。 |

---

## 五、建议落地顺序

1. [INFERRED, HIGH] 先闭合 runtime 主线：PR-007a~g、L2/L3/live/release evidence；`internal/cs` 边界已有本地证据，继续保留 boundary gate。
2. [INFERRED, HIGH] 用检查脚本持续守门治理投影：RULES/TRACEABILITY/CHANGELOG/RUNTIME-MAPPING/FEATURES/ACCEPTANCE 的状态口径和入口一致性。
3. [INFERRED, HIGH] 维护 v4/v5 的 FR-012~FR-030 `module/binance/DATA-LIFECYCLE.md` 正式提案，并继续将 runtime Done 翻转阻断在证据门禁前。
4. [INFERRED, HIGH] FR-012~FR-030 已完成登记；下一步进入 Spec -> Matrix -> Tasks -> Plan -> Prompt -> Code 管线，按 event_type 是否扩展决定 MINOR 或 MAJOR bump。
5. [INFERRED, MED] 最后处理文档维护项：拆分长报告、压缩 legacy 名称、补 commit 覆盖矩阵、优化 GateGuard 流程说明。

---

## 六、不再列为当前未完成的事项

- [COMPUTED, HIGH] v1 的版本漂移、状态冲突、AC 锚点缺失、server SPEC 不一致等 P0/P1 文档对齐项已由 v2 声明修复或复核，因此本报告不重复列入未完成项（`deep-analysis-20260622.md:9`；`deep-analysis-20260622-v2.md:47`-`61`、`188`-`196`）。
- [COMPUTED, HIGH] v3 将自身定位为历史问题已经转化为治理项后的复核报告，因此本报告仅继承其仍需补充的治理投影、数据生命周期和运行证据要求（`deep-analysis-20260622-v3.md:3`-`19`、`32`-`54`）。
- [COMPUTED, HIGH] `internal/cs` runtime blocker 不再列为当前未完成项：`/home/binance` SHA `66f60b3945dce215f68ff833bbd336364d635ae8` 证明当前 runtime 无 `internal/cs`，且 boundary gate §5 PASS。

---

## 七、验收口径

- [INFERRED, HIGH] 文档闭环：主动治理文档中不存在互相冲突的状态、版本、任务引用和 4x4 NATS/Kafka 口径。
- [INFERRED, HIGH] runtime 闭环：当前已有 runtime HEAD SHA、boundary gates、Go tests、smoke 本地证据；仍需 L2/L3/live/release、remote CI、standalone client、JetStream PubAck/ManualAck、durable storage/fanout/query。
- [INFERRED, HIGH] 数据生命周期闭环：Formal Proposal 已建立，FR-012~FR-030 已正式登记；验收焦点是 implementation/test/evidence/release closure。
- [INFERRED, HIGH] 治理闭环：legacy 名称、长报告、preserve/stash commit 和 GateGuard 流程风险均有明确保留、删除或迁移记录。
- [INFERRED, HIGH] 运维闭环：FR-021/FR-023/FR-024 的对账、回填可观测性和订阅热重载进入同一数据生命周期提案。
- [INFERRED, HIGH] 影响台账闭环：v4/v5 新增 FR/AC/TC/BR、表、topic、metric 和版本 bump 均可追溯。

---

## 八、十轮复核结果（2026-06-23）

| 轮次 | 检查切面 | 结果 |
| --- | --- | --- |
| 1 | [COMPUTED, HIGH] 源文件覆盖 | [COMPUTED, HIGH] 覆盖 5 个 `deep-analysis-20260622*` 源报告：v1、v2、v3、v4、v5。 |
| 2 | [COMPUTED, HIGH] P0 阻塞项 | [COMPUTED, HIGH] PR-007 runtime blocker、L2/L3/release 证据缺口、governance projection、DATA-LIFECYCLE 均已覆盖；`internal/cs` 已转入“不再列为当前未完成”。 |
| 3 | [COMPUTED, HIGH] v1 过时项过滤 | [COMPUTED, HIGH] v1 trade/orderbook compatibility 等已被后续报告标记为过时，未被误列为当前未完成项。 |
| 4 | [COMPUTED, HIGH] v4 realtime FR 覆盖 | [COMPUTED, HIGH] FR-012、FR-013、FR-014、FR-015 已覆盖。 |
| 5 | [COMPUTED, HIGH] v4 historical FR 覆盖 | [COMPUTED, HIGH] 发现遗漏：FR-021、FR-023、FR-024 未显式列入；已补 P1-8a 与 P1-8b。 |
| 6 | [COMPUTED, HIGH] v4 funding / mark price 覆盖 | [COMPUTED, HIGH] FR-020 已覆盖。 |
| 7 | [COMPUTED, HIGH] v5 cleansing / processing / gap 覆盖 | [COMPUTED, HIGH] FR-025、FR-026、FR-027、FR-028、FR-029 已覆盖。 |
| 8 | [COMPUTED, HIGH] governance impact ledger | [COMPUTED, HIGH] 发现遗漏：v4/v5 的 FR/AC/TC/BR、表、topic、metric、版本 bump 影响台账未展开；已补 P2-6。 |
| 9 | [COMPUTED, HIGH] 执行顺序 | [COMPUTED, HIGH] P0 -> P1 -> P2 顺序仍成立；新增 P1-8a/P1-8b 不改变前置依赖。 |
| 10 | [COMPUTED, HIGH] 验收口径 | [COMPUTED, HIGH] 已补对账、回填可观测性、订阅热重载与治理影响台账验收口径。 |

- [COMPUTED, HIGH] 本轮结论：原汇总没有遗漏 P0 主线，但遗漏 3 个 v4 显式治理/运维承载项（FR-021、FR-023、FR-024）和 1 个 v4/v5 累计治理影响台账；已在本报告补齐。

[RULES I BROKE]：无
