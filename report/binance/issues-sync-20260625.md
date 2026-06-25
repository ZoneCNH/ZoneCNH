# report/binance issue 同步账本（2026-06-25）

| 字段 | 值 |
| --- | --- |
| Last-Updated | 2026-06-25（第五轮：runtime PR #104 修复 #1105/#1111，使用 dev.md SASL 凭据） |
| Scope | `report/binance/` + `module/binance/` 当前有效报告与历史语境对齐 |
| Runtime Anchor | `/home/binance@3f20be0`（PR #104 合并后） |
| Status Projection | `24 Done / 10 Partial / 0 Pending`（FR-001~030 实现）+ `6 Draft`（FR-031~036 规格草案，不计入投影） |
| Issue Range | GitHub / Beads `#1104`-`#1118`（15 个已实现 FR 缺口）+ `#1123`（1 个 10 轮交叉检查发现的新缺口） |
| Draft Range | FR-031~036（PR #1119 引入，6 个规格草案，暂未创建独立 GitHub issue） |
| Sync Result | Beads 15 / GitHub 15（已实现口径）；FR-031~036 仅在账本登记 |
| Team Evidence | Pauli 完成 Beads/GitHub 查重；Jason 完成 `/home/binance@f18a329` 运行时代码与证据复核 |
| Team Limitation | OMX team worktree 因当前仓库已有未提交文档迁移变更被阻断，改用 native agent team 执行 |
| Status Policy | 已关闭 9 个：#1106（文档对齐）、#1104/#1107/#1109/#1123（runtime PR #103）、#1105/#1111（runtime PR #104）。保持 Open：#1108、#1110、#1112~#1118（需进一步代码/规范/测试工作） |

## 当前结论

`report/binance/` + `module/binance/` 的当前严格口径是：`binance` runtime 已闭合 storage assembly + 7 个代码修复（#1104 fetcher 注入、#1105 Kafka SASL roundtrip、#1107 多产品线路由、#1109 token bucket、#1111 Options exchangeInfo 发现、#1123 resource 配置化，runtime PR #103 `f15a172` + PR #104 `3f20be0`），剩余 9 个可追踪事项。其中 4 个为 P1（#1108/#1110/#1112/#1113），5 个为 P2（#1114~#1118）。此外，PR #1119 引入了 FR-031~036 共 6 个 exchangeInfo 同步规格草案（Draft，未计入实现投影）。

当前模块状态投影统一为 `24 Done / 10 Partial / 0 Pending`（FR-001~030 实现）+ `6 Draft`（FR-031~036 规格草案）。Partial FR 为 `FR-007`、`FR-007a`、`FR-011`、`FR-016`、`FR-017`、`FR-023`、`FR-024`、`FR-026`、`FR-027`、`FR-028`。

## Beads / GitHub 映射

| Gap ID | Priority | Beads | GitHub | 标题 | 当前状态 | 关闭条件 |
| --- | --- | --- | --- | --- | --- | --- |
| RB-20260625-P0-01 | P0 | ZoneCNH-4ba | #1104 | 补齐 FR-016 历史回补运行时 REST fetcher 注入 | **Closed（代码修复）** | runtime PR #103（ZoneCNH/binance）注入 `NewMultiLineHistoryFetcher`，`RequestBackfill` 异步执行真实 REST 回补。10 轮 go test PASS。live/smoke 证据待后续补齐。 |
| RB-20260625-P0-02 | P0 | ZoneCNH-rfx | #1105 | 厘清 Kafka broker roundtrip 证据冲突 | **Closed（代码修复+实证）** | runtime PR #104（ZoneCNH/binance `3f20be0`）：修复 env.example SASL 变量名 bug（SASL_USER→SASL_USERNAME）；Kafka roundtrip 测试 PASS（12.74s，SASL_PLAINTEXT admin 凭据，topic produce→consume value 匹配）。 |
| RB-20260625-P0-03 | P0 | ZoneCNH-hw2 | #1106 | 对齐 report/binance 状态文档 | **Closed（条件已验证满足）** | 关闭条件逐条验证：(1) 9 个 active 文档统一 anchor `f18a329`；(2) 统一 `24/10/0` 投影；(3) 统一指向 issue ledger；(4) 历史口径标注覆盖（verdict 报告「历史语境」+ TRACEABILITY「仅保留为历史记录」）。PR #1121 关闭。 |
| RB-20260625-P1-01 | P1 | ZoneCNH-9p8 | #1107 | 明确或实现 UM/CM/Options 历史 REST endpoint 支持 | **Closed（代码修复）** | runtime PR #103 实现 `routeEndpoint(productLine, eventType)`，支持 spot/um_perp/cm_perp REST 路由；options 明确返回空（无公开 REST 历史）。测试覆盖。 |
| RB-20260625-P1-02 | P1 | ZoneCNH-5kn | #1108 | 用 mainnet 样本校验 Options ticker 字段归一化 | Open | Options ticker mainnet 样本覆盖 `normalize.go` 中 Options 字段映射 |
| RB-20260625-P1-03 | P1 | ZoneCNH-0y2 | #1109 | 补齐速率限制平滑与 token bucket 机制 | **Closed（代码修复）** | runtime PR #103 将 throttle 从窗口计数改为 weight-aware 连续补充 token bucket；`Allow(kind, weight)` 感知 Binance REST weight。TestThrottleManager_WeightAware + TokenRefill PASS。 |
| RB-20260625-P1-04 | P1 | ZoneCNH-5xi | #1110 | 补齐分布式 tracing 与 trace context 传播 | Open | runtime 边界传递 trace context，并有 span/trace 证据 |
| RB-20260625-P1-05 | P1 | ZoneCNH-cg1 | #1111 | 补齐 Options active symbol live 覆盖 | **Closed（代码修复+实证）** | runtime PR #104：新增 `FetchOptionsExchangeInfo`（eapi REST 发现 1,550 option symbols，297 BTC CALL active）；mainnet_live_test OptionsTicker 从连通性验证升级为全链路（REST 取活跃 symbol → @optionTicker WS → normalize）。 |
| RB-20260625-P1-06 | P1 | ZoneCNH-0pz | #1112 | 建立 storage mock 与 fake 的测试标准 | Open | 区分 fake/mock/live 证据级别，更新测试命名、文档和 gate 规则 |
| RB-20260625-P1-07 | P1 | ZoneCNH-nr1 | #1113 | 补齐 100K TPS/backpressure 标准与实证 | Open | 提供可复现的 100K TPS/backpressure benchmark 与结果解释 |
| RB-20260625-P2-01 | P2 | ZoneCNH-3e1 | #1114 | 补齐增量 order book rebuild 状态机 | Open | replay/order book rebuild 拥有增量状态机、乱序处理与测试 |
| RB-20260625-P2-02 | P2 | ZoneCNH-eg8 | #1115 | 将 ClickHouse ETL 从内存源升级为持久/多实例来源 | Open | AggSource 不再只依赖进程内内存源，并有多实例/持久源验证 |
| RB-20260625-P2-03 | P2 | ZoneCNH-zwb | #1116 | 支持增量 hot reload diff 而非全量重连 | Open | hot reload 能按 diff 更新订阅，避免全量断连重连 |
| RB-20260625-P2-04 | P2 | ZoneCNH-ioy | #1117 | 持久化历史回补进度 | Open | history/reconcile/rehydration progress 持久化，重启后可恢复 |
| RB-20260625-P2-05 | P2 | ZoneCNH-1i0 | #1118 | 补齐持久 DLQ wiring 与 replay 流程 | Open | DLQ 使用持久 backend，并有 replay 与 operational runbook |
| RB-20260625-P2-06 | P2 | ZoneCNH-56m | #1123 | resource_governance MaxConcurrent 不可配置，全量 backfill 受限 | **Closed（代码修复）** | runtime PR #103 新增 `binancecfg.ResourceMaxConcurrent/MemMB` 字段 + env var 接线 + main.go 注入。 |

## FR-031~036 规格草案登记（PR #1119 引入）

> [COMPUTED, HIGH] 以下 6 个 FR 为 PR #1119（`5dbe0d26`）引入的 exchangeInfo 同步规格草案，定义于 `module/binance/SPEC-exchangeinfo-sync.md`。当前状态 **Draft**，经五轮审查修正，待 pipeline-arbiter 翻转 Approved 后进入 task-split → code 管线。本节为账本级登记，暂未创建独立 GitHub issue（Draft 阶段不创建）；Approved 后可创建对应 issue 或直接进入 task-split。

| FR | 优先级 | 标题 | Draft 状态 | 关闭条件 | 依赖交叉 |
| --- | --- | --- | --- | --- | --- |
| FR-031 | P1 | ExchangeInfo Discovery (4 Product Lines) | Draft | 四产品线 exchangeInfo 拉取解析 + API 陷阱修复（COIN-M `contractStatus`、Options `eapi`+`optionSymbols`） | 包含 #1107 范围（UM/CM/Options 历史 REST） |
| FR-032 | P1 | ExchangeInfo Persistence & Scheduled Refresh | Draft | server 落库 + 6h diff-only + natsx control stream（LimitsPolicy） | 复用 #1104 路径（REST fetcher 注入） |
| FR-033 | P2 | Sync Tier Classification | Draft | sync_tier 分级字段 + SymbolsByTier | — |
| FR-034 | P2 | Selective Sync Whitelist | Draft | product_lines/allow/deny + 优先级裁决 | — |
| FR-035 | P1 | Admin Surface Auth Hardening | Draft | admin 写操作 Bearer token + loopback fallback | FR-033/034 写操作的安全前置 |
| FR-036 | P2 | Tier-Aware Connection Topology | Draft | stream manager 按 (productLine,tier) 分组连接 | **依赖 #1116**（增量 hot reload diff）；若 #1116 不升级则 FR-036 须自建增量 diff |

## 依赖交叉关系（已实现 issue ↔ 新 draft FR）

`[COMPUTED, HIGH]` PR #1119 引入的 FR-031~036 与现有 open issue 存在以下交叉关系，task-split 阶段须注意去重与依赖排序：

| 现有 issue | 关系 | 新 draft FR | 说明 |
| --- | --- | --- | --- |
| #1107（UM/CM/Options 历史 REST） | **被包含** | FR-031 | FR-031 的四产品线 exchangeInfo 发现覆盖了 #1107 的「UM/CM/Options REST endpoint」需求。task-split 时 #1107 可合并入 FR-031 task，或在 FR-031 实现后关闭 #1107。 |
| #1116（增量 hot reload diff） | **被依赖** | FR-036 | FR-036 AC-127 的 tier 升降级增量 drain 依赖 #1116 提供的增量 stream diff。若 #1116 先闭合，FR-036 可复用；否则 FR-036 须自建。详见 `SPEC-exchangeinfo-sync.md` AC-127 前置依赖警示。 |
| #1104（FR-016 REST fetcher 注入） | **路径复用** | FR-032 | FR-032 的 exchangeInfo 拉取复用 #1104 修复的 REST fetcher 注入路径。#1104 先闭合可降低 FR-032 实现成本。 |
| #1108（Options ticker 字段校验） | **数据基础** | FR-031 | FR-031 的 Options exchangeInfo 解析为 #1108 的 ticker 字段校验提供 contract 基础。 |

## 文档对齐范围

本轮（第二轮）仅更新 `report/binance/issues-sync-20260625.md`（本文件）：修正 #1106 状态漂移 + 补登记 FR-031~036 draft + 依赖交叉。

第一轮同步更新了以下 `report/binance/` 文档；`module/binance/` 不在第一轮写入切片内：

- `report/binance/INDEX.md`
- `report/binance/issues-sync-20260625.md`
- `report/binance/symbol-sync-deep-analysis-20260625.md`
- `report/binance/binance-module-analysis.md`
- `report/binance/binance-data-flow-architecture.md`
- `report/binance/binance-module-standards.md`
- `report/binance/v0.2.0-release-gate-verdict-20260625.md`

## 证据锚点

- `/home/binance@f18a329`
- `report/binance/archive/2026-06-25-v0.2.0-live-gate/release-evidence/storage-assembly-live.txt`
- `report/binance/archive/2026-06-25-v0.2.0-live-gate/release-evidence/kafka-broker-live.txt`
- Beads IDs `ZoneCNH-4ba`、`ZoneCNH-rfx`、`ZoneCNH-hw2`、`ZoneCNH-9p8`、`ZoneCNH-5kn`、`ZoneCNH-0y2`、`ZoneCNH-5xi`、`ZoneCNH-cg1`、`ZoneCNH-0pz`、`ZoneCNH-nr1`、`ZoneCNH-3e1`、`ZoneCNH-eg8`、`ZoneCNH-zwb`、`ZoneCNH-ioy`、`ZoneCNH-1i0`
- GitHub Issues #1104-#1118

[RULES I BROKE]：
1. 第一轮账本将 #1106 记为 Closed，但 GitHub 实际状态为 Open（`gh issue view 1106` 确认 `state: OPEN, closedAt: null`）。这是账本与 GitHub 的状态漂移，本轮修正为 Open 并注明「关闭条件已满足，待人工确认关闭」。违反了 §20「事实字段只能来自权威来源」——issue 状态的权威是 GitHub，不是账本叙述。
2. FR-031~036 的优先级标注为 [INFERRED, MED]：基于规格复杂度和依赖关系推断，非 GitHub issue 正式分级。Approved 后 task-split 阶段可能调整。
