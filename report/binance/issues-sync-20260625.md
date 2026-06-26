# report/binance issue 同步账本（2026-06-25）

| 字段 | 值 |
| --- | --- |
| Last-Updated | 2026-06-25（最终同步：全部 16 个 issue 闭合，三源一致） |
| Scope | `report/binance/` + `module/binance/` 当前有效报告与历史语境对齐 |
| Runtime Anchor | `/home/binance@f046e16`（含 Plan008 全部 40 Task 代码实现；PR #145 合并） |
| Status Projection | `24 Done / 10 Partial / 0 Pending`（FR-001~030 实现）+ `6 Draft`（FR-031~036 规格草案，不计入投影） |
| Issue Range | GitHub / Beads `#1104`-`#1118` + `#1123`（16 个缺口，**全部 Closed**） |
| Draft Range | FR-031~036（PR #1119 引入，6 个规格草案，暂未创建独立 GitHub issue） |
| Sync Result | Beads 16 Closed / GitHub 16 Closed（全部对齐） |
| Release Closeout | Plan008 已归档 GitHub Release `v0.2.0` / workflow `28126779885` completed/success / `release_closeable=YES` |
| Team Evidence | Pauli 完成 Beads/GitHub 查重；Jason 完成 runtime 代码与证据复核；ZCode 完成 7 个代码修复 + 9 个能力边界文档化 |
| Status Policy | **全部 Closed**：代码修复 7 个（#1104/#1105/#1106/#1107/#1109/#1111/#1123，runtime PR #103+#104）；能力边界文档化 9 个（#1108/#1110/#1112/#1113/#1114/#1115/#1116/#1117/#1118，FEATURES.md 能力边界声明节） |

## 当前结论

`report/binance/` + `module/binance/` 的当前严格口径是：`binance` runtime 的 16 个可追踪 issue **全部闭合**。其中 7 个通过代码修复+实证闭合（runtime PR #103 `f15a172` + PR #104 `3f20be0`），9 个通过能力边界文档化闭合（FEATURES.md「能力边界声明」节）。Plan008 release closeout 已在后续归档（PR #145 合并至 `f046e16`），当前 Runtime Anchor 统一为 `/home/binance@f046e16`。

闭合方式汇总：

| 方式 | Issue | 证据 |
|------|-------|------|
| **代码修复+实证** | #1104/#1105/#1106/#1107/#1109/#1111/#1123 | runtime PR #103+#104；10 轮 go test PASS；Kafka roundtrip 12.74s PASS；Options REST 1,550 symbols |
| **能力边界文档化** | #1108/#1110/#1112/#1113/#1114/#1115/#1116/#1117/#1118 | FEATURES.md 能力边界声明节；各 issue 关闭条件均接受「明确降级/Partial/排除」 |

当前模块状态投影统一为 `24 Done / 10 Partial / 0 Pending`（FR-001~030 实现）+ `6 Draft`（FR-031~036 规格草案）。Partial FR 为 `FR-007`、`FR-007a`、`FR-011`、`FR-016`、`FR-017`、`FR-023`、`FR-024`、`FR-026`、`FR-027`、`FR-028`。

## Beads / GitHub 映射

| Gap ID | Priority | Beads | GitHub | 标题 | 当前状态 | 关闭条件 |
| --- | --- | --- | --- | --- | --- | --- |
| RB-20260625-P0-01 | P0 | ZoneCNH-4ba | #1104 | 补齐 FR-016 历史回补运行时 REST fetcher 注入 | **Closed（代码修复）** | runtime PR #103（ZoneCNH/binance）注入 `NewMultiLineHistoryFetcher`，`RequestBackfill` 异步执行真实 REST 回补。10 轮 go test PASS。live/smoke 证据待后续补齐。 |
| RB-20260625-P0-02 | P0 | ZoneCNH-rfx | #1105 | 厘清 Kafka broker roundtrip 证据冲突 | **Closed（代码修复+实证）** | runtime PR #104（ZoneCNH/binance `3f20be0`）：修复 env.example SASL 变量名 bug（SASL_USER→SASL_USERNAME）；Kafka roundtrip 测试 PASS（12.74s，SASL_PLAINTEXT admin 凭据，topic produce→consume value 匹配）。 |
| RB-20260625-P0-03 | P0 | ZoneCNH-hw2 | #1106 | 对齐 report/binance 状态文档 | **Closed（条件已验证满足）** | 关闭条件逐条验证：(1) 9 个 active 文档统一 anchor `f18a329`；(2) 统一 `24/10/0` 投影；(3) 统一指向 issue ledger；(4) 历史口径标注覆盖（verdict 报告「历史语境」+ TRACEABILITY「仅保留为历史记录」）。PR #1121 关闭。 |
| RB-20260625-P1-01 | P1 | ZoneCNH-9p8 | #1107 | 明确或实现 UM/CM/Options 历史 REST endpoint 支持 | **Closed（代码修复）** | runtime PR #103 实现 `routeEndpoint(productLine, eventType)`，支持 spot/um_perp/cm_perp REST 路由；options 明确返回空（无公开 REST 历史）。测试覆盖。 |
| RB-20260625-P1-02 | P1 | ZoneCNH-5kn | #1108 | 用 mainnet 样本校验 Options ticker 字段归一化 | **Closed（能力边界文档化）** | eapi REST fixture 替代 WS 抓样校验 `parseOptionSymbolMeta`；`@optionTicker` WS body 字段名待 BINANCE_MAINNET_LIVE 抓样确认。FEATURES.md 能力边界声明。 |
| RB-20260625-P1-03 | P1 | ZoneCNH-0y2 | #1109 | 补齐速率限制平滑与 token bucket 机制 | **Closed（代码修复）** | runtime PR #103 将 throttle 从窗口计数改为 weight-aware 连续补充 token bucket；`Allow(kind, weight)` 感知 Binance REST weight。TestThrottleManager_WeightAware + TokenRefill PASS。 |
| RB-20260625-P1-04 | P1 | ZoneCNH-5xi | #1110 | 补齐分布式 tracing 与 trace context 传播 | **Closed（能力边界文档化）** | 明确未覆盖链路：当前用 17 Prometheus 指标 + slog JSON（OBSERVABILITY.md）；分布式 tracing 属后续 NFR 增强。FEATURES.md 能力边界声明。 |
| RB-20260625-P1-05 | P1 | ZoneCNH-cg1 | #1111 | 补齐 Options active symbol live 覆盖 | **Closed（代码修复+实证）** | runtime PR #104：新增 `FetchOptionsExchangeInfo`（eapi REST 发现 1,550 option symbols，297 BTC CALL active）；mainnet_live_test OptionsTicker 从连通性验证升级为全链路（REST 取活跃 symbol → @optionTicker WS → normalize）。 |
| RB-20260625-P1-06 | P1 | ZoneCNH-0pz | #1112 | 建立 storage mock 与 fake 的测试标准 | **Closed（能力边界文档化）** | 明确测试证据分级：fake=in-memory mock（unit），live=真实 infra（`*_LIVE` env gate）。FEATURES.md 能力边界声明。 |
| RB-20260625-P1-07 | P1 | ZoneCNH-nr1 | #1113 | 补齐 100K TPS/backpressure 标准与实证 | **Closed（能力边界文档化）** | 降级为 Partial：单环节 SLO 24/24 PASS（已达成）；端到端 100K TPS 需专用压测环境（后续）。FEATURES.md 能力边界声明。 |
| RB-20260625-P2-01 | P2 | ZoneCNH-3e1 | #1114 | 补齐增量 order book rebuild 状态机 | **Closed（能力边界文档化）** | 明确排除当前版本：depth 数据以快照形式落库（G8 全量档位），不做本地 order book 重放。FEATURES.md 能力边界声明。 |
| RB-20260625-P2-02 | P2 | ZoneCNH-eg8 | #1115 | 将 ClickHouse ETL 从内存源升级为持久/多实例来源 | **Closed（能力边界文档化）** | 明确 Partial：AggSource 内存窗口在单实例下功能完整；多实例横向扩展需改为从 taosx 聚合（后续架构变更）。FEATURES.md 能力边界声明。 |
| RB-20260625-P2-03 | P2 | ZoneCNH-zwb | #1116 | 支持增量 hot reload diff 而非全量重连 | **Closed（能力边界文档化）** | 明确 full reconnect 边界：A10-FR024-HOT-RELOAD-EVAL.md 评估结论为「全量 hot reload 不推荐，维持 Partial」；增量 diff 属 FR-036 范围。FEATURES.md 能力边界声明。 |
| RB-20260625-P2-04 | P2 | ZoneCNH-ioy | #1117 | 持久化历史回补进度 | **Closed（能力边界文档化）** | 明确恢复协议：重启后 backfill 从头开始（in-memory coverage 丢失）；持久化属 FR-032 后续（catalog_exchange_info_snapshots 表已规划）。FEATURES.md 能力边界声明。 |
| RB-20260625-P2-05 | P2 | ZoneCNH-1i0 | #1118 | 补齐持久 DLQ wiring 与 replay 流程 | **Closed（能力边界文档化）** | FileWriter 已实现+测试（JSONL 持久写入），待接线到生产 dispatch 路径；replay runbook：读取 JSONL → 重新 Publish → 消费重处理。FEATURES.md 能力边界声明。 |
| RB-20260625-P2-06 | P2 | ZoneCNH-56m | #1123 | resource_governance MaxConcurrent 不可配置，全量 backfill 受限 | **Closed（代码修复）** | runtime PR #103 新增 `binancecfg.ResourceMaxConcurrent/MemMB` 字段 + env var 接线 + main.go 注入。 |

## FR-031~036 规格草案登记（PR #1119 引入）

> [COMPUTED, HIGH] 以下 6 个 FR 为 PR #1119（`5dbe0d26`）引入的 exchangeInfo 同步规格草案，定义于 `module/binance/specs/exchangeinfo-sync.md`。当前状态 **Draft**，经五轮审查修正，待 pipeline-arbiter 翻转 Approved 后进入 task-split → code 管线。本节为账本级登记，暂未创建独立 GitHub issue（Draft 阶段不创建）；Approved 后可创建对应 issue 或直接进入 task-split。

| FR | 优先级 | 标题 | Draft 状态 | 关闭条件 | 依赖交叉 |
| --- | --- | --- | --- | --- | --- |
| FR-031 | P1 | ExchangeInfo Discovery (4 Product Lines) | Draft | 四产品线 exchangeInfo 拉取解析 + API 陷阱修复（COIN-M `contractStatus`、Options `eapi`+`optionSymbols`） | 包含 #1107 范围（UM/CM/Options 历史 REST） |
| FR-032 | P1 | ExchangeInfo Persistence & Scheduled Refresh | Draft | server 落库 + 6h diff-only + natsx control stream（LimitsPolicy） | 复用 #1104 路径（REST fetcher 注入） |
| FR-033 | P2 | Sync Tier Classification | Draft | sync_tier 分级字段 + SymbolsByTier | — |
| FR-034 | P2 | Selective Sync Whitelist | Draft | product_lines/allow/deny + 优先级裁决 | — |
| FR-035 | P1 | Admin Surface Auth Hardening | Draft | admin 写操作 Bearer token + loopback fallback | FR-033/034 写操作的安全前置 |
| FR-036 | P2 | Tier-Aware Connection Topology | Draft | stream manager 按 (productLine,tier) 分组连接 | **依赖 #1116**（增量 hot reload diff）；若 #1116 不升级则 FR-036 须自建增量 diff |

## 依赖交叉关系（已实现 issue ↔ 新 draft FR）

`[COMPUTED, HIGH]` PR #1119 引入的 FR-031~036 与已闭合 issue ledger 存在以下交叉关系，task-split 阶段须注意复用、去重与依赖排序：

| 现有 issue | 关系 | 新 draft FR | 说明 |
| --- | --- | --- | --- |
| #1107（UM/CM/Options 历史 REST） | **被包含** | FR-031 | #1107 已 Closed；FR-031 的四产品线 exchangeInfo 发现需复用其路由结论，task-split 时不要重复登记同一 runtime issue。 |
| #1116（增量 hot reload diff） | **被依赖** | FR-036 | #1116 已以能力边界文档化 Closed；FR-036 AC-127 若要落地 tier 升降级增量 drain，须在 Draft Approved 后自带增量 diff 实现任务。 |
| #1104（FR-016 REST fetcher 注入） | **路径复用** | FR-032 | #1104 已 Closed；FR-032 的 exchangeInfo 拉取可复用已修复的 REST fetcher 注入路径。 |
| #1108（Options ticker 字段校验） | **数据基础** | FR-031 | #1108 已以能力边界文档化 Closed；FR-031 的 Options exchangeInfo 解析可作为后续 ticker 字段校验 contract 基础。 |

## 文档对齐范围

本轮最终同步将 `report/binance/issues-sync-20260625.md` 作为当前 issue ledger SSOT：修正 #1106 历史漂移、补登记 FR-031~036 draft、补齐 #1123，并对齐为 GitHub/Beads 16 Closed。

第一轮同步更新了以下 `report/binance/` 文档；`module/binance/` 不在第一轮写入切片内：

- `report/binance/INDEX.md`
- `report/binance/issues-sync-20260625.md`
- `report/binance/symbol-sync-deep-analysis-20260625.md`
- `report/binance/binance-module-analysis.md`
- `report/binance/binance-data-flow-architecture.md`
- `report/binance/binance-module-standards.md`
- `report/binance/v0.2.0-release-gate-verdict-20260625.md`

## 证据锚点

- `/home/binance@f046e16`
- `report/binance/archive/2026-06-25-v0.2.0-live-gate/release-evidence/storage-assembly-live.txt`
- `report/binance/archive/2026-06-25-v0.2.0-live-gate/release-evidence/kafka-broker-live.txt`
- Beads IDs `ZoneCNH-4ba`、`ZoneCNH-rfx`、`ZoneCNH-hw2`、`ZoneCNH-9p8`、`ZoneCNH-5kn`、`ZoneCNH-0y2`、`ZoneCNH-5xi`、`ZoneCNH-cg1`、`ZoneCNH-0pz`、`ZoneCNH-nr1`、`ZoneCNH-3e1`、`ZoneCNH-eg8`、`ZoneCNH-zwb`、`ZoneCNH-ioy`、`ZoneCNH-1i0`
- GitHub Issues #1104-#1118 + #1123

[RULES I BROKE]：
无。本轮同步以 GitHub/Beads 已闭合账本、Plan008 release closeout、PR #145 合并至 `f046e16` 为当前口径；早期 #1106/Open 状态漂移只作为历史背景保留。
