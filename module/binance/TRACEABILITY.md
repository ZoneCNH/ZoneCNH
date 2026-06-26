# module/binance TRACEABILITY

> 追溯矩阵 — 确保 FR/BR → AC → TC → Task → Status 闭环可追溯。
>
> 规范来源：`docs/governance/TRACEABILITY.md`

- Module-Version: v3.7.1
- Last-Updated: 2026-06-26
- Spec-Reference: `module/binance/SPEC.md` v3.7.1
- Runtime-Anchor: `/home/binance@f046e16`（含 Plan008 全部 40 Task 代码实现；PR #145 合并）

---

## §1 FR 追溯表

> **v3.1.0 历史变更摘要**：FR-006 拆分为 6a(taosx)/6b(postgresx)/6c(redisx cache)/6d(ossx)；FR-007 扩展 analytics API(7a)；新增 FR-010（clickhousex OLAP 存储）、FR-011（分布式协调锁）；v3.1.0 继续登记 FR-012~FR-024，覆盖 realtime control、historical lifecycle、event governance、release evidence 与 runtime hot reload；subject 命名统一 `um_perp`/`cm_perp`；Error 码扩展至 BNC-013；Performance Budget 扩展至 20 项。

> **v3.2.0 历史变更摘要**：fold DATA-LIFECYCLE §7 候选 FR 进 SPEC/TRACEABILITY/NAMING——新增 FR-025（Backfill Throttle & Priority）、FR-026（Daily Reconciliation Job）、FR-027（Cold Data Rehydration）、FR-028（Backfill Progress API）；NAMING §2.1 补 bar 订阅周期集、§3.1 补 control subjects（`instruments.changed`/`symbols.changed`）；SPEC §9 补 FR-015 depth 档位表 + control subjects；AC 扩展至 098、TC 扩展至 046。FR-025~028 全部 Pending（runtime 仓未实现）。

> **v3.3.0 历史变更摘要**：版本号统一治理——字段名收敛为 `Spec-Version`（仅 SPEC）/ `Module-Version`（治理文档）/ `Runtime-Version`（SPEC runtime 版本）；废弃 `Doc-Version`/`Matrix-Version`/`Version` 异名；顶层 Module-Version 对齐 root SPEC；server/TRACEABILITY 补建版本字段；R6 扩展为全量版本统一规则 + check-binance-docs.sh 增项。

> **v3.5.1 历史变更摘要 (2026-06-24)**：FR 实现状态从「1 Done / 29 Pending」刷新为「22 Done / 8 Partial / 0 Pending」，对齐 runtime HEAD `8290dc9`（PR #73 之后的真实代码状态）。22 个 Done FR 拥有非 stub 生产代码路径；8 个 Partial 各有明确缺口（FR-002 缺少碰撞测试 / FR-004 NakWithDelay 代码已有但集成验证缺 / FR-008 kafka broker e2e 缺 / FR-016/017 history fetcher 仍为 stub / FR-023 远程 CI 缺 / FR-024 仅 symbol catalog reload / FR-026 daily job 缺 / FR-030 options normalize 分支缺）。BR-004 提升为 Partial（natsx NakWithDelay + DLQ deadletter 包已实现）。SHA 统一为 `8290dc9`。该段仅保留为历史记录；当前有效状态以 Runtime-Anchor `/home/binance@f18a329` 与 Issue-Ledger `../../report/binance/issues-sync-20260625.md` 为准。

> **v3.6.0 历史变更摘要 (2026-06-25，已被 v3.6.1 覆盖)**：FR 实现状态曾从「22 Done / 8 Partial」刷新为「19 Done / 11 Partial」，对齐 runtime HEAD `e02b190`（Plan007 A1~A10 + B1~B8 执行后的阶段性状态）。本次刷新引入 **main.go 装配级证据标准**：FR 标 Done 必须同时满足「writer/代码存在」**且**「`cmd/binance-server/main.go` 装配真实实例」。据此：
> - **上调 6 项**（Plan007 闭合）：FR-002（A4 跨产品线碰撞断言）、FR-004（A3 NakWithDelay(5s)+MaxDeliver=5+deadletter）、FR-008（main 真实装配 kafkax 生产默认 dispatcher）、FR-025（80/20 throttle runtime 装配）、FR-030（A7 options rawPassThrough 兜底）、FR-016 实质升级（A1 真实 REST 替换 stub，但 runtime 未注入 fetcher 仍保持 Partial）。
> - **下调 9 项**（main.go 装配断层）：FR-005/006a/006b/006c/006d/007/007a/010/011 — writer/store/lock 代码完整存在，但 `cmd/binance-server/main.go` 用 `bootstrap.Spec{Stores: bootstrap.None}`、`NewMemoryIdempotencyStore`（非 RedisStore）、`StorageWriter=nil`、`PostAcceptHooks=nil`、`EnableMarketAPI` 未设，导致这些 FR 在运行时**永不执行**。下调依据见 `report/binance/production-readiness-assessment-20260625.md` §4.1 G0（存储装配断层）。
> - **BR-004** 由 Partial 提升为 Done（A3 NakWithDelay+DLQ 已实现并经本地 NATS JetStream gated 测试验证）。
> - SHA 统一为 `e02b190`。该段仅保留为历史记录；当前有效状态以 Runtime-Anchor `/home/binance@f18a329` 与 Issue-Ledger `../../report/binance/issues-sync-20260625.md` 为准。

> **v3.7.1 变更摘要 (2026-06-26)**：对齐 SPEC.md v3.7.1——FR-021 IndexPrice 作为 mark_price 字段承载（非独立 event_type，与运行时一致）；FR-025 限流拆分对齐 cold_start/repair 命名；FR-019 MaxConcurrent 对齐运行时 5→4；FR-016 错误码更新 BNC-017/018；TC-043~049 已登记至 SPEC.md §16（TC 总数十进制闭合 61→65）；§12 错误码表补充 BNC-017/018；Appendix D 弃用声明更新 30→38 FR / 104→130 AC；FR-031~036 Draft 交叉引用新增至 SPEC.md §7。PR #1189 合并。本轮不改变 FR 实现状态投影。

> **v3.6.1 变更摘要 (2026-06-25)**：基于 Runtime-Anchor `/home/binance@f18a329` 与 Issue-Ledger `../../report/binance/issues-sync-20260625.md`，当前 FR 状态投影为 **24 Done / 10 Partial / 0 Pending**。Partial FR: FR-007, FR-007a, FR-011, FR-016, FR-017, FR-023, FR-024, FR-026, FR-027, FR-028。
> - GitHub #1104~#1118 与后续 Plan008 issues 已同步闭合；Release closeout 已由 `../../plans/binance/008-issues-sync-report.md` 归档为 `release_closeable=YES`；remaining Partial FR 继续按 FR-specific acceptance evidence 单独治理。
> - 本次撤回历史 `28 Done / 2 Partial` 当前口径；该口径仅作为已撤回历史记录，不再作为当前状态。
> - 状态模型为 Done/Partial/Pending 三态：Done 表示 runtime anchor 下代码、装配与证据闭合；Partial 表示代码、子链路或局部证据存在但 runtime 注入、持久化、外部 E2E/live evidence、FR-specific acceptance evidence 或产品线覆盖未闭合；Pending 表示仅规格登记。当前有效基线无 Pending FR。
>
> **v3.6.0 历史变更摘要 (2026-06-25，已被 v3.6.1 覆盖)**：历史 `28 Done / 2 Partial / 0 Pending` 口径来自 `fix/binance-production-readiness` 分支上的阶段性投影；当前 issue-ledger 已将其撤回为历史记录，不能作为现行状态或关闭依据。

> **2026-06-23 历史证据刷新（round 2）**：本地 runtime evidence 已归档至 `/home/binance/release/evidence/binance/20260623/`；证据提交 `71e2a6e8bb5591c43e8a2ebfff8c7645bf030786`；boundary gates 重新运行 10/10 PASS，`go build`/`go vet`/`go test` 全部 PASS，全部 9 个 issue 分支已合并至 origin/main；GitHub #923~#931 已关闭并登记至 `report/binance/github-issues-923-931-closure-ledger-20260623.md`；该关闭仅表示 issue tracking closure，不关闭 release、remote CI、live websocket、外部集成与 L2 功能 FR。该段仅保留为历史记录；当前有效状态以 Runtime-Anchor `/home/binance@f18a329` 与 Issue-Ledger `../../report/binance/issues-sync-20260625.md` 为准。

> **2026-06-24 历史本地 readiness 刷新**：worker lane 在 `/home/binance` runtime HEAD `dd3332d3452f4eaa8146563bdb82caf577a3d4c1`（保留既有 dirty readiness 变更，未提交）上完成本地验证：`bash -n scripts/runtime-release-evidence.sh scripts/boundary-gates.sh scripts/readiness-audit.sh` PASS，`make fmt-check boundary-gates build test vet readiness-audit` PASS（boundary gates `13 passed, 0 failed`），`go test ./... -race -count=1` PASS，`git diff --check` PASS；同时修正 `scripts/runtime-release-evidence.sh` 的 external-gate ledger 文案，避免后续证据刷新回退为 `MISSING_RUNTIME_ADAPTER`。该证据只更新 FR-009/BR 边界与本地 build/readiness 追溯，不关闭完整 JetStream TC-004/TC-006、真实 external storage IO / fanout / query API、remote CI、release tag 或 FR-012~030。该段仅保留为历史记录；当前有效状态以 Runtime-Anchor `/home/binance@f18a329` 与 Issue-Ledger `../../report/binance/issues-sync-20260625.md` 为准。

> **2026-06-24 历史 gated JetStream 子集刷新**：`BINANCE_NATSX_INTEGRATION=1 go test ./internal/server/consumer -run TestNATSXIntegrationJetStreamSemantics -count=1 -v` 与 100 次重复 gated loop PASS；真实本地 NATS JetStream 已证明 accepted PubAck、duplicate PubAck、Ack 后不重投、immediate Nak 到 `MaxDeliver=5` 后停止。TC-004/TC-006 继续 Pending：独立 client/server 进程、`NakWithDelay(5s)`、dead-letter/parking 与完整 live 链路仍未闭合。该段仅保留为历史记录；当前有效状态以 Runtime-Anchor `/home/binance@f18a329` 与 Issue-Ledger `../../report/binance/issues-sync-20260625.md` 为准。

> **2026-06-24 历史 kafkax fanout 本地子集刷新**：目标 server 测试、`go test ./cmd/binance-server ./internal/server -count=1`、`go test ./...`、`go vet ./...`、`./scripts/boundary-gates.sh` 与 `plan006_task_4_7_repeat_checks=100` PASS；本地 adapter 已验证 topic/key 和 strict handoff `BNC-008` before durable/Ack。FR-008 仍未 Done：真实 Kafka broker e2e、production topic/ACL、release evidence 未闭合。该段仅保留为历史记录；当前有效状态以 Runtime-Anchor `/home/binance@f18a329` 与 Issue-Ledger `../../report/binance/issues-sync-20260625.md` 为准。

> **状态模型说明**：FR 表的"实现状态"列采用 Done/Partial/Pending 三态模型；当前状态以 Runtime-Anchor `/home/binance@f046e16` 与 Issue-Ledger `../../report/binance/issues-sync-20260625.md` 为准。Partial FR 固定为 FR-007、FR-007a、FR-011、FR-016、FR-017、FR-023、FR-024、FR-026、FR-027、FR-028。Pending FR 固定为 FR-037~044（v3.7.0 新增）+ FR-031~036（Draft，不计入 v3.7.0 基线投影）。当前有效基线：**24 Done / 10 Partial / 10 Pending**。
| FR ID | 功能需求 | AC | TC ID(s) | Task | 实现状态 |
|-------|----------|-----|----------|------|----------|
| FR-001 | Product-Line Support：Client 可独立采集 Spot / USDⓈ-M / COIN-M / Options 四产品线 | AC-001 ~ AC-003 | TC-001 | TASK-BINANCE-ROOT-001, CLIENT-001 | Done |
| FR-002 | Instrument Identity：四产品线 canonical instrument identity 跨 product_line 不碰撞 | AC-004 ~ AC-006 | TC-002, TC-003 | TASK-BINANCE-ROOT-002, CLIENT-004 | Done |
| FR-003 | natsx Communication：Client/Server 通过 natsx JetStream **网络**通信，禁止共享进程或内存 | AC-007 ~ AC-010 | TC-004, TC-005 | CLIENT-014, SERVER-010 | Done |
| FR-004 | At-Least-Once Delivery：JetStream durable consumer + ManualAck 确保消息不丢失 | AC-011 ~ AC-013 | TC-006 | CLIENT-014, SERVER-010 | Done |
| FR-005 | Idempotent Acceptance：redisx SetNX 确保相同消息最多写入 taosx 一次（72h TTL） | AC-014 ~ AC-016 | TC-007, TC-008 | SERVER-011 | Done |
| FR-006a | Full-Stack Storage / taosx Time-Series：WriteBatch 写入 tick/bar/depth 到超级表子表 | AC-017 ~ AC-018 | TC-009 | SERVER-012 | Done |
| FR-006b | postgresx Metadata：幂等 upsert instrument catalog + 审计日志 | AC-019 ~ AC-020 | TC-010 | SERVER-012 | Done |
| FR-006c | redisx Hot Cache：最新 tick/bar/depth 热缓存（60s/5s TTL），失败降级 | AC-036 ~ AC-037 | TC-023 | SERVER-013 | Done |
| FR-006d | ossx Archival：定时将 taosx 过期数据归档到 OSS，ETag 校验后删热 | AC-026 ~ AC-028 | TC-016, TC-017 | SERVER-016 | Done |
| FR-007 | Gin Market API：/api/v1/market/* REST 接口，redisx 热缓存 + taosx 回退 | AC-021 ~ AC-025 | TC-012 ~ TC-015 | SERVER-015 | Partial |
| FR-007a | clickhousex Analytics API：/api/v1/analytics/* OLAP 查询（vwap/top-movers/correlation） | AC-038 ~ AC-040 | TC-024 | SERVER-015 | Partial |
| FR-008 | kafkax Broadcast：将 accepted facts 广播到 `binance.{product_line}.{event_type}.v1` Kafka topic | AC-029 ~ AC-031 | TC-018, TC-019 | SERVER-014 | Done |
| FR-009 | Boundary Enforcement：CI gate 阻断 client/server 跨界、运行时共享包回流、go.mod 合规 | AC-032 ~ AC-035 | TC-020 ~ TC-022 | SERVER-008 | Done |
| FR-010 | clickhousex OLAP Storage：定时 ETL 聚合 taosx→clickhousex，为 analytics API 提供 OLAP 查询 | AC-041 ~ AC-044 | TC-025, TC-026 | SERVER-017 | Done |
| FR-011 | Distributed Coordinator Lock：redisx SetNX 分布式锁，coordinator HA 选举 + lease 续期 | AC-045 ~ AC-047 | TC-027, TC-028 | SERVER-013 | Partial |
| FR-012 | Stream Session Lifecycle：active stream registry 支持运行中增删订阅且不重启进程 | AC-048 ~ AC-050 | TC-029 | CLIENT-015 | Done |
| FR-013 | Exchange Reliability Controls：retry budget、rate-limit、clock skew 与 exchange disconnect 策略可观测 | AC-051 ~ AC-053 | TC-030 | CLIENT-016 | Done |
| FR-014 | Runtime Stream Observability：admin/metrics 暴露 stream state、lag、unhealthy reason | AC-054 ~ AC-056 | TC-031 | CLIENT-017 | Done |
| FR-015 | Runtime Pause/Resume/Drain：operator 可暂停、恢复与 drain 订阅且有审计记录 | AC-057 ~ AC-059 | TC-032 | CLIENT-018 | Done |
| FR-016 | Historical Backfill Planner：backfill window、cursor、overlap validation 与恢复语义 | AC-060 ~ AC-062 | TC-033 | SERVER-018 | Partial |
| FR-017 | Gap Detection and Replay：检测 ingest gap 并生成可幂等 replay job | AC-063 ~ AC-065 | TC-034 | SERVER-019 | Partial |
| FR-018 | Archive Manifest and Restore：归档 manifest、restore、retention delete 可审计 | AC-066 ~ AC-068 | TC-035 | SERVER-020 | Done |
| FR-019 | Backfill Resource Governance：全局与单 instrument 资源限额、取消与 cursor 恢复 | AC-069 ~ AC-071 | TC-036 | SERVER-021 | Done |
| FR-020 | Funding Rate Event Support：funding_rate 事件 mapping、存储、查询与广播一致 | AC-072 ~ AC-074 | TC-037 | SERVER-022 | Done |
| FR-021 | Mark and Index Price Support：单一 mark_price 事件承载 IndexPrice 字段，topic 与存储不与 last/bid/ask 混淆 | AC-075 ~ AC-077 | TC-038 | SERVER-023 | Done |
| FR-022 | Event-Type Governance Matrix：R2 120-cell matrix 锁定 event/product/governance 覆盖面 | AC-078 ~ AC-080 | TC-039 | ROOT-008 | Done |
| FR-023 | Release Evidence Bundle：local/CI/live/release evidence 分层归档且不可互相替代 | AC-081 ~ AC-083 | TC-040, TC-041 | ROOT-009 | Partial |
| FR-024 | Runtime Config Hot Reload：`POST /api/v1/admin/symbols/reload` 重载目录并应用 stream diff | AC-084 ~ AC-086 | TC-042 | CLIENT-019 | Partial |
| FR-025 | Backfill Throttle & Priority：token bucket weight 限流 + 80/20 配额 + trade>bar>tick 优先级 | AC-087 ~ AC-089 | TC-043 | SERVER-022 | Done |
| FR-026 | Daily Reconciliation Job：04:00 UTC 对账 taosx vs Binance klines + tolerance 0.01% + alerts 表 | AC-090 ~ AC-092 | TC-044 | SERVER-023 | Partial |
| FR-027 | Cold Data Rehydration：OSS→taosx 回热 24h TTL + 202 job_id + 轮询 | AC-093 ~ AC-095 | TC-045 | SERVER-024 | Partial |
| FR-028 | Backfill Progress API：jobs 列表 + coverage 时间戳 + 诊断字段 | AC-096 ~ AC-098 | TC-046 | SERVER-025 | Partial |
| FR-029 | Data Quality & Freshness SLA：端到端 event_time→persist 延迟上限 + schema 漂移检测 + stale alert | AC-099 ~ AC-101 | TC-047 | ROOT-010 | Done |
| FR-030 | Options Chain Raw Field Pass-through：option chain 原始字段（strike/expiry/option_type/mark/IV）透传至下游，Greeks 派生归分析域 | AC-102 ~ AC-104 | TC-048, TC-049 | CLIENT-020 | Done |
| FR-031 | ExchangeInfo Discovery (4 Product Lines)：client 实现 spot/um/cm/options 四产品线 exchangeInfo 拉取解析，修复 API 陷阱（COIN-M `contractStatus`、Options `eapi`+`optionSymbols`） | AC-105 ~ AC-108 | TC-050, TC-051 | — | Draft（不计入当前投影） |
| FR-032 | ExchangeInfo Persistence & Scheduled Refresh：server 消费 `instruments.changed` 落库 postgresx；client 6h 定时刷新 diff-only 发布；DB schema 扩展 | AC-109 ~ AC-112 | TC-052, TC-053 | — | Draft（不计入当前投影） |
| FR-033 | Sync Tier Classification：`sync_tier ∈ {L1_core,L2_extended,L3_full,disabled}` 分级；tier 决定采集流类型 + backfill 优先级 | AC-113 ~ AC-116 | TC-054, TC-055 | — | Draft（不计入当前投影） |
| FR-034 | Selective Sync Whitelist：实现 `product_lines`/`symbols.allow`/`symbols.deny`；优先级 deny>allow>tier；运行时热更新 | AC-117 ~ AC-120 | TC-056, TC-057 | — | Draft（不计入当前投影） |
| FR-035 | Admin Surface Auth Hardening：client `AdminServer` 写操作鉴权（Bearer token / loopback fallback）；FR-033/034 写操作的安全前置 | AC-121 ~ AC-124 | TC-059, TC-060, TC-061, TC-062 | — | Draft（不计入当前投影） |
| FR-036 | Tier-Aware Connection Topology：stream manager 按 (productLine,tier) 分组 WS 连接；`StreamsForProductLineTier` 按 productLine 分化（options 仅 optionTicker）；连接分批 + 升降级 drain + options 到期峰值平滑 | AC-125 ~ AC-128 | TC-063, TC-064, TC-065, TC-066, TC-067 | — | Draft（不计入当前投影） |
| FR-037 | Release Safety Net：feature flag 机制（`XGO_BINANCE_FEATURE_{name}`）+ canary 部署 + 健康门禁 + 自动回滚 runbook（S26） | AC-105 ~ AC-107 | TC-050, TC-062 | — | Pending |
| FR-038 | taosx Data Retention Lifecycle：DB 级 KEEP 365 + 定时 DELETE trade/tick(30d)/bar(90d) + OSS ETag 前置校验 + 删除审计（G6/S1/S2） | AC-108 ~ AC-111 | TC-051, TC-052 | — | Pending |
| FR-039 | Distributed Tracing (OpenTelemetry)：SDK 埋点 + W3C traceparent header 传播 NATS/Kafka + slog trace_id 关联 + 采样率可配（S28） | AC-112 ~ AC-114 | TC-053, TC-063 | — | Pending |
| FR-040 | Resource Quota & Isolation：per-consumer-group Kafka 配额 + per-product-line WS 连接池隔离 + per-caller API 限流 + CH 查询超时（S29） | AC-115 ~ AC-118 | TC-054, TC-055, TC-064 | — | Pending |
| FR-041 | Audit Log Completeness：admin 写操作审计 + 数据生命周期审计 + append-only + ≥1 年保留 + OSS 归档（S30/S33） | AC-119 ~ AC-121 | TC-056, TC-057, TC-065 | — | Pending |
| FR-042 | Schema Version Compatibility Policy：MAJOR terminal reject (BNC-014) + MINOR 向后兼容 + 兼容矩阵 + 升级顺序（S27） | AC-122 ~ AC-124 | TC-058 | — | Pending |
| FR-043 | Cost Observability：存储容量/带宽 per-product-line Prometheus 指标 + 成本告警（S31） | AC-125 ~ AC-127 | TC-059 | — | Pending |
| FR-044 | Data Compliance & Destruction：data_classification 标注 + 合规保留期 + 销毁证明 certificate_of_destruction（S32） | AC-128 ~ AC-130 | TC-060, TC-061 | — | Pending |

> [COMPUTED, HIGH] **FR-031~036 规格草案（2026-06-25，第三轮结构性审查后）**：定义于 [`SPEC-exchangeinfo-sync.md`](SPEC-exchangeinfo-sync.md)。第三轮审查发现 3 个 P0 结构性问题并修正：(1) FR-033 原含「tier→连接拓扑」与 connector 单连接模型冲突，拆出 FR-036；(2) `StreamsForTier` 未按 productLine 分化（options 无 depth/bookTicker），改为 `StreamsForProductLineTier`；(3) control stream retention WorkQueue 在 multi-server 下丢消息，改 LimitsPolicy。另修 2 个 P1：diff Updated/SpecUpdated 分离、options 到期峰值 BR-012。当前为 **Draft（不计入 v3.6.1 状态投影）**，不参与当前 `24 Done / 10 Partial / 0 Pending` 统计。FR-035 是 FR-033/034 写操作的安全前置；FR-036 依赖 FR-033 且涉及 connector 架构重构，建议前置 ADR。

> 状态口径（v3.6.1，Runtime-Anchor `/home/binance@f18a329`）：FR 表实现状态采用 Done/Partial/Pending 三态模型。当前统计 **24 Done / 10 Partial / 0 Pending**（34 行当前有效基线口径），Partial 固定为 FR-007、FR-007a、FR-011、FR-016、FR-017、FR-023、FR-024、FR-026、FR-027、FR-028。
>
> - **10 个 Partial 的保守保留原因**：#1104/#1107/#1109 覆盖 FR-016 historical runtime fetcher、产品线 REST endpoint 与 rate-limit smoothing；#1112/#1115 覆盖 FR-007/FR-007a/FR-011 的存储证据与 ClickHouse ETL 持久化；#1105/#1113 覆盖 FR-023 Kafka broker 与 100K TPS/backpressure evidence；#1116 覆盖 FR-024 增量 hot reload diff；#1117 覆盖 FR-017/FR-026/FR-027/FR-028 持久化 progress/history/reconcile/rehydration；#1118 覆盖持久化 DLQ wiring/replay。上述 issue ledger 已闭合；FR projection 仍保守保留为 Partial，不因 release gate 闭合自动升格。
> - **Issue closure policy**：GitHub #1104~#1118 与后续 Plan008 issues 已同步闭合；Release closeout 已由 `../../plans/binance/008-issues-sync-report.md` 归档为 `release_closeable=YES`；剩余风险以 FR projection 的 `10 Partial` 表达。
>
> 历史：v3.5.1（HEAD `8290dc9`）统计为 22 Done / 8 Partial；v3.6.0 的 `28 Done / 2 Partial` 仅保留为已撤回历史口径。FR-009/BR Done 的 2026-06-23 round 2 本地 runtime 证据见 `BOUNDARY-GATES.md` 与 `/home/binance/release/evidence/binance/20260623/`（证据提交 `71e2a6e8bb5591c43e8a2ebfff8c7645bf030786`）。该状态不关闭真实 Kafka broker e2e、远程 release CI、live websocket、合约/期权 testnet 凭据或外部集成证据。

---

## §2 BR 追溯表

| BR ID | 业务规则 | 验证方式 | Task | 实现状态 |
|-------|----------|----------|------|----------|
| BR-001 | No binance-market：禁止在 active architecture 中引用 `binance-market` | CI Gate: BOUNDARY-GATES.md §2 | TASK-BINANCE-ROOT-000 | Done |
| BR-002 | Client Must Not Import Server Internals | CI Gate: BOUNDARY-GATES.md §3 | CLIENT-014, SERVER-010 | Done |
| BR-003 | Server Must Not Import Client Internals | CI Gate: BOUNDARY-GATES.md §4 | SERVER-010 | Done |
| BR-004 | natsx ManualAck — 全链路写入成功（redisx+taosx+postgresx+kafkax handoff）后才 Ack；失败 NakWithDelay | TC-006: 处理失败→NakWithDelay 集成测试 | SERVER-010 | Done |
| BR-005 | No Runtime Shared Package：禁止运行时共享包回流；禁止 C/S 同进程运行 | CI Gate: BOUNDARY-GATES.md §5, §6 | SERVER-008 | Done |
| BR-006 | Server Owns Binance Storage：market_data 禁止直连 binance 的 taosx/postgresx/redisx/ossx | CI Gate: BOUNDARY-GATES.md §7 | SERVER-012 ~ SERVER-016 | Done |
| BR-007 | No Domain Ownership：模块不得定义 canonical domain semantics SSOT，必须引用 `domain_market` | CI Gate: BOUNDARY-GATES.md §9 | TASK-BINANCE-ROOT-004 | Done |
| BR-008 | Wire Contract Externality：不得定义自己的 proto，接口协议通过 natsx subject + JSON envelope | CI Gate: BOUNDARY-GATES.md §8 | SERVER-010, CLIENT-014 | Done |
| BR-009 | go.mod Dependency Compliance：natsx/redisx/postgresx/taosx/clickhousex/kafkax/ossx/gin 必须保持 direct 依赖 | CI Gate: BOUNDARY-GATES.md §11 | SERVER-015, SERVER-016 | Done |

---

## §3 NFR 追溯表

| NFR ID | 非功能需求 | 来源 (SPEC §) | 验证方式 |
|--------|------------|---------------|----------|
| NFR-001 | Client event normalization 延迟 P99 < 1ms | §17 Performance Budget | `go test -bench BenchmarkNormalize` |
| NFR-002 | Canonical mapping 延迟 P99 < 100μs | §17 | `go test -bench BenchmarkCanonicalMapping` |
| NFR-003 | natsx Publish 延迟 P99 < 10ms（含 JetStream PubAck 往返） | §17 | integration test |
| NFR-004 | Server consumer process (validate→store) 延迟 P99 < 50ms | §17 | integration test |
| NFR-005 | redisx SetNX 幂等检查 P99 < 1ms | §17 | `go test -bench BenchmarkIdempotencyCheck` |
| NFR-006 | redisx hot cache read P99 < 0.5ms | §17 | `go test -bench BenchmarkRedisCacheRead` |
| NFR-007 | taosx WriteBatch 吞吐量 ≥ 100,000 TPS | §17 | `go test -bench BenchmarkTaosWriteBatch` |
| NFR-008 | postgresx UpsertSymbol 延迟 P99 < 5ms | §17 | `go test -bench BenchmarkPgUpsert` |
| NFR-009 | clickhousex InsertBatch (50000 rows) 延迟 P99 < 500ms | §17 | integration test |
| NFR-010 | clickhousex analytics Query 延迟 P99 < 2s | §17 | integration test |
| NFR-011 | kafkax Send (async) 延迟 P99 < 5ms | §17 | integration test |
| NFR-012 | ossx Upload (100MB) 吞吐量 ≥ 50 MB/s | §17 | integration test |
| NFR-013 | Gin API /api/v1/market/ticks (redisx hit) P99 < 5ms | §17 | httptest benchmark |
| NFR-014 | Gin API /api/v1/analytics/vwap (clickhousex) P99 < 2s | §17 | httptest benchmark |
| NFR-015 | Gin API /api/v1/instruments (postgresx) P99 < 20ms | §17 | httptest benchmark |
| NFR-016 | Client restart recovery < 10s | §17 | integration test |
| NFR-017 | 各组件 Prometheus metrics 正确暴露（consumer lag/taosx TPS/API p99/dispatch errors） | §18 Observability | metrics endpoint |
| NFR-018 | 所有日志含 product_line + symbol + subject | §18 | 日志级别检查 |
| NFR-019 | API Key / Secret 从环境变量读取，不硬编码 | §19 Security | CI: `gitleaks detect --no-git` |
| NFR-020 | Secrets 不出现于 log、debug、admin 端点输出 | §19 | secret redaction test |

---

## §4 TC→FR 反向追溯

| TC ID | 覆盖 FR(s) | 覆盖 BR(s) | 测试类型 | 状态 |
|-------|------------|------------|----------|------|
| TC-001 | FR-001 | — | 集成（Binance testnet） | Pending |
| TC-002 | FR-002 | BR-007 | 单元（product_line identity） | Pending |
| TC-003 | FR-002 | BR-007 | 单元（cross product_line 不碰撞） | Pending |
| TC-004 | FR-003 | BR-005 | 集成（client natsx Publish，server 独立进程接收；2026-06-24 gated local PubAck duplicate 子集已验证，独立进程/live 链路仍缺） | Pending |
| TC-005 | FR-003 | BR-002, BR-003 | CI gate（跨进程边界检查；BR 边界证据由 TC-020/021/022 承载，FR-003 集成仍需独立进程 publish/consume 证据） | Pending |
| TC-006 | FR-004 | BR-004 | 集成（JetStream ManualAck：成功→Ack，失败→NakWithDelay；2026-06-24 gated Ack/no-redelivery + immediate Nak MaxDeliver 子集已验证，`NakWithDelay`/dead-letter 仍缺） | Pending |
| TC-007 | FR-005 | — | 单元（SetNX 首次→新消息；重复→跳过） | Pending |
| TC-008 | FR-005 | — | 单元（Redis 不可达→error→NakWithDelay） | Pending |
| TC-009 | FR-006a | BR-006 | 单元（taosx WriteTick + WriteBatch） | Pending |
| TC-010 | FR-006b | BR-006 | 单元（postgresx UpsertSymbol 幂等） | Pending |
| TC-011 | FR-006a | — | 集成（taosx QueryRange 时间范围过滤） | Pending |
| TC-012 | FR-007 | — | httptest（/api/v1/market/ticks redisx hit + taosx fallback） | Pending |
| TC-013 | FR-007 | — | httptest（/api/v1/market/depth redisx cache） | Pending |
| TC-014 | FR-007 | — | httptest（API key 401） | Pending |
| TC-015 | FR-007 | — | httptest（限流 429） | Pending |
| TC-016 | FR-006d | BR-006 | 单元（先写 ossx ETag 校验后删 taosx） | Pending |
| TC-017 | FR-006d | — | 单元（归档路径格式） | Pending |
| TC-018 | FR-008 | — | 单元（kafkax topic + partition key；2026-06-24 local adapter topic/key 子集已验证，真实 broker pending） | Partial |
| TC-019 | FR-008 | BR-004 | 单元（kafkax 不可达→error/不 Ack；2026-06-24 strict handoff BNC-008 before durable/Ack 子集已验证，broker/DLQ pending） | Partial |
| TC-020 | FR-009 | BR-005 | CI gate（运行时共享包/client 包 import 检查） | **PASS** |
| TC-021 | FR-009 | BR-001 | CI gate（no-legacy 引用检查） | **PASS** |
| TC-022 | FR-009 | BR-009 | CI gate（go.mod 合规） | **PASS** |
| TC-023 | FR-006 | — | 单元（redisx SET(tick:*, json, 60s)；PUT 失败→降级不阻塞） | Pending |
| TC-024 | FR-007 | — | httptest（/api/v1/analytics/vwap + top-movers + correlation） | Pending |
| TC-025 | FR-010 | BR-006 | 集成（clickhousex ETL：taosx Query → 聚合 → InsertBatch） | Pending |
| TC-026 | FR-010 | — | 单元（clickhousex 不可达→503 + ETL 跳过本批次） | Pending |
| TC-027 | FR-011 | — | 单元（redisx SetNX 获取锁 → 启动 ETL；5s 轮询重试） | Pending |
| TC-028 | FR-011 | — | 单元（lease 续期失败 → 停止任务；主动释放锁 → Del） | Pending |
| TC-029 | FR-012 | — | 集成（active stream registry 增删订阅） | Pending |
| TC-030 | FR-013 | — | 单元 + 集成（retry budget、rate-limit、clock skew） | Pending |
| TC-031 | FR-014 | — | httptest + metrics（stream state / lag / unhealthy reason） | Pending |
| TC-032 | FR-015 | — | httptest + 集成（pause/resume/drain + audit） | Pending |
| TC-033 | FR-016 | — | 单元（window validation + cursor + overlap rejection） | Pending |
| TC-034 | FR-017 | — | 集成（gap detect + replay idempotency） | Pending |
| TC-035 | FR-018 | — | 单元 + 集成（manifest + restore + retention delete） | Pending |
| TC-036 | FR-019 | — | 单元（global/per-instrument caps + cancellation cursor） | Pending |
| TC-037 | FR-020 | — | 单元 + 集成（funding_rate mapping/storage/query/fanout） | Pending |
| TC-038 | FR-021 | — | 单元 + 集成（mark/index price kind/topic/storage） | Pending |
| TC-039 | FR-022 | — | 文档校验（R2 governance matrix + stale checks） | Pending |
| TC-040 | FR-023 | — | 证据归档（local/CI/live evidence bundle） | Pending |
| TC-041 | FR-023 | — | release gate（tag/changelog/evidence consistency） | Pending |
| TC-042 | FR-024 | — | 集成 + httptest（`POST /api/v1/admin/symbols/reload` + no-restart proof） | Pending |
| TC-043 | FR-025 | — | 单元 + 集成（token bucket weight 限流 + 80/20 配额 + 优先级排序） | Pending |
| TC-044 | FR-026 | — | 集成（04:00 UTC 对账 + tolerance 阈值 + alerts 表写入） | Pending |
| TC-045 | FR-027 | — | 集成（OSS→taosx 回热 + 202 job_id + 24h TTL 过期） | Pending |
| TC-046 | FR-028 | — | httptest（jobs 列表 + coverage 时间戳 + 诊断字段） | Pending |
| TC-047 | FR-029 | — | 集成 + metrics（event_time→persist/fanout freshness SLA + stale alert + schema drift） | Pending |
| TC-048 | FR-030 | — | 单元（Options 原始字段透传：strike/expiry/option_type/mark/IV） | Pending |
| TC-049 | FR-030 | — | 契约测试（Greeks 派生不进入 binance，交由分析域处理） | Pending |

---

## §5 AC 注册表

| AC ID | 所属 FR | AC 描述 | 验证方式 |
|-------|---------|---------|----------|
| AC-001 | FR-001 | Client 启动且 product-line 已启用时建立 WebSocket 连接并开始采集 | TC-001 |
| AC-002 | FR-001 | WebSocket 连接断开后自动重连，JetStream durable consumer 自动恢复消费位置 | 集成测试：模拟断连 → 验证重连 |
| AC-003 | FR-001 | 收到 Binance 原生事件后映射为 MarketFactEnvelope 并通过 natsx 发布 | TC-004 |
| AC-004 | FR-002 | Binance 原生事件映射为 canonical MarketFactEnvelope，所有必填字段正确填充 | TC-002 |
| AC-005 | FR-002 | Binance 原生字段缺失时使用 product-line 配置补全 | TC-002 |
| AC-006 | FR-002 | 同 symbol 跨 product_line 时 InstrumentKey 可区分（BTCUSDT Spot ≠ BTCUSDT USDⓈ-M） | TC-003 |
| AC-007 | FR-003 | Client 通过 `natsx.Publish(subj, json)` 发布事件，等待 JetStream PubAck（确保持久化） | TC-004 |
| AC-008 | FR-003 | Server 通过 `natsx.Subscribe(durable)` 订阅，不共享 client 进程或内存 | TC-004, TC-005 |
| AC-009 | FR-003 | Subject 格式 `binance.market.{product_line}.{event_type}`，大小写统一小写 | TC-004 |
| AC-010 | FR-003 | C/S 可在不同机器独立启动，共用外部 NATS JetStream 连接地址；CI gate 验证无跨进程 import | TC-005 |
| AC-011 | FR-004 | JetStream durable consumer（durable: `binance-server`）进程重启后从上次 Ack 位置恢复 | TC-006 |
| AC-012 | FR-004 | 处理成功（redisx+taosx+postgresx+kafkax handoff 全完成）后 msg.Ack() | TC-006 |
| AC-013 | FR-004 | 处理失败时 msg.NakWithDelay(5s)，MaxDeliver=5 后进入死信 | TC-006 |
| AC-014 | FR-005 | 首次消息（SetNX 成功）→ 继续写入 taosx | TC-007 |
| AC-015 | FR-005 | 重复消息（SetNX 失败）→ Ack 并跳过，不写 taosx | TC-007 |
| AC-016 | FR-005 | Redis 不可达 → error，consumer NakWithDelay | TC-008 |
| AC-017 | FR-006a | taosx WriteTick 使用 symbol+product_line 子表名，自动创建子表 | TC-009 |
| AC-018 | FR-006a | taosx WriteBatch 合并多条消息一次网络往返 | TC-009 |
| AC-019 | FR-006b | postgresx UpsertSymbol 幂等（ON CONFLICT DO UPDATE） | TC-010 |
| AC-020 | FR-006b | postgresx UpdateIngestStatus 更新 last_seq 用于 gap fill | TC-010 |
| AC-021 | FR-007 | GET /api/v1/market/ticks 从 taosx 查询，支持 symbol+time range+limit | TC-012 |
| AC-022 | FR-007 | GET /api/v1/market/depth/:symbol 从 redisx 读取最新快照 | TC-013 |
| AC-023 | FR-007 | 无效 API key → 401 | TC-014 |
| AC-024 | FR-007 | 超限（1000 req/min）→ 429 + Retry-After | TC-015 |
| AC-025 | FR-007 | GET /readyz 任一组件断连 → 503 | TC-012 |
| AC-026 | FR-006d | 每日定时查询 cutoff（now - 90d）之前的 taosx 数据；归档路径格式 `binance/{product_line}/{symbol}/{YYYY}/{MM}/{DD}/{event_type}.parquet` | TC-016, TC-017 |
| AC-027 | FR-006d | ossx ETag 验证通过后才执行 taosx.Delete（先写冷再删热） | TC-016 |
| AC-028 | FR-006d | ETag 不匹配时停止删除并报警；ossx path 与 parquet object 格式可回放校验 | TC-017 |
| AC-029 | FR-008 | kafkax topic = `binance.{product_line}.{event_type}.v1`；local adapter topic 已验证，真实 broker pending | TC-018 |
| AC-030 | FR-008 | partition key = symbol；local message key=symbol 已验证，相同 symbol broker partition/order e2e pending | TC-018 |
| AC-031 | FR-008 | strict dispatch failure 返回 retryable `BNC-008` before durable/Ack 已验证；broker/DLQ e2e pending | TC-019 |
| AC-032 | FR-009 | server 源码无 client 内部包或运行时共享包导入（CI gate） | TC-020 |
| AC-033 | FR-009 | 任何代码 reintroduce `binance-market` 引用时 CI no-legacy gate 失败 | TC-021 |
| AC-034 | FR-009 | go.mod 中 natsx/redisx/postgresx/taosx/clickhousex/kafkax/ossx/gin 均保持 direct 依赖 | TC-022 |
| AC-035 | FR-009 | BOUNDARY-GATES §5（运行时共享包回流禁止）+ §6（同进程禁止）+ §11（go.mod 合规）全 PASS | TC-020 |
| AC-036 | FR-006c | redisx SET(tick:{line}:{symbol}, json, 60s) 写入最新行情缓存 | TC-023 |
| AC-037 | FR-006c | redisx 缓存写入失败 → warn 日志 + 降级（不阻塞主管线） | TC-023 |
| AC-038 | FR-007a | GET /api/v1/analytics/vwap 从 clickhousex 返回跨符号 VWAP 排名 | TC-024 |
| AC-039 | FR-007a | GET /api/v1/analytics/top-movers 返回涨幅/跌幅 top N | TC-024 |
| AC-040 | FR-007a | GET /api/v1/analytics/correlation 返回两 symbol Pearson 相关系数 | TC-024 |
| AC-041 | FR-010 | ETL scheduler 每 5 分钟从 taosx 聚合写入 clickhousex（1m_ohlcv/5m_vwap/15m_stats） | TC-025 |
| AC-042 | FR-010 | clickhousex InsertBatch 失败 → error 日志 + 告警 + 跳过本批次（下周期重试） | TC-026 |
| AC-043 | FR-010 | clickhousex 不可达 → analytics API 返回 503；实时 API 不受影响 | TC-026 |
| AC-044 | FR-010 | 启动时 market_binance 库不存在 → 自动 DDL 建库建表 | TC-025 |
| AC-045 | FR-011 | redisx SetNX("lock:binance:coordinator", instanceID, 30s) 成功 → 启动 scheduler | TC-027 |
| AC-046 | FR-011 | 锁获取失败 → standby 模式，每 5s 轮询重试，自动接管 | TC-027 |
| AC-047 | FR-011 | lease 续期失败 → 停止 ETL+归档；正常关闭 → Del 主动释放 | TC-028 |
| AC-048 | FR-012 | active stream registry 可在运行中新增 symbol/product_line 订阅，不重启 client 进程 | TC-029 |
| AC-049 | FR-012 | active stream registry 可在运行中移除订阅并关闭对应 websocket/topic fanout | TC-029 |
| AC-050 | FR-012 | 增删订阅期间已存在 stream 的 sequence、lag 与 reconnect state 不丢失 | TC-029 |
| AC-051 | FR-013 | retry budget 对 connect/read/publish 分别限额，超限后进入 unhealthy 状态 | TC-030 |
| AC-052 | FR-013 | Binance rate-limit 响应映射为可观测 backoff，不忙等、不吞错 | TC-030 |
| AC-053 | FR-013 | 本地 clock skew 超阈值时拒绝签名/时间敏感请求并暴露告警 | TC-030 |
| AC-054 | FR-014 | admin/metrics 暴露每个 stream 的 state、last_event_time、lag 与 reconnect_count | TC-031 |
| AC-055 | FR-014 | unhealthy reason 可区分 connect、read、publish、rate_limit、clock_skew | TC-031 |
| AC-056 | FR-014 | metrics label 使用 product_line/event_type/instrument，不泄漏 secret | TC-031 |
| AC-057 | FR-015 | operator 可 pause 单个 stream，pause 后停止 publish 但保留状态 | TC-032 |
| AC-058 | FR-015 | operator 可 resume 单个 stream，resume 后从当前 Binance stream 恢复采集 | TC-032 |
| AC-059 | FR-015 | drain 会等待 in-flight publish 完成并记录 audit event | TC-032 |
| AC-060 | FR-016 | backfill planner 拒绝 end<=start、overlap policy 未声明和超 retention window 请求 | TC-033 |
| AC-061 | FR-016 | backfill cursor 可持久化并在重启后从上次成功 offset 恢复 | TC-033 |
| AC-062 | FR-016 | backfill window 按 product_line/event_type/instrument 分片且可限速 | TC-033 |
| AC-063 | FR-017 | ingest gap detector 可基于 sequence/time bucket 发现缺口并生成 replay job | TC-034 |
| AC-064 | FR-017 | replay job 对已存在数据幂等，不重复写入 taosx/clickhousex | TC-034 |
| AC-065 | FR-017 | replay 失败会保留原因、重试次数和可恢复 cursor | TC-034 |
| AC-066 | FR-018 | archive manifest 记录 object key、checksum、row_count、time range 与 source query | TC-035 |
| AC-067 | FR-018 | restore 根据 manifest 校验 checksum/row_count 后恢复到指定存储 | TC-035 |
| AC-068 | FR-018 | retention delete 必须引用已验证 manifest，禁止无 manifest 删除热数据 | TC-035 |
| AC-069 | FR-019 | backfill/replay 支持全局并发与单 instrument 并发限额 | TC-036 |
| AC-070 | FR-019 | operator 可取消 backfill/replay，取消后 cursor 保持可恢复 | TC-036 |
| AC-071 | FR-019 | resource governance 指标暴露 queue depth、active jobs、throttled jobs | TC-036 |
| AC-072 | FR-020 | funding_rate Binance 原生事件可映射为 domain_market envelope 并持久化 | TC-037 |
| AC-073 | FR-020 | funding_rate 查询 API 与 Kafka fanout 使用独立 event_type，不与 ticker/trade 混淆 | TC-037 |
| AC-074 | FR-020 | funding_rate 的 historical replay 与 realtime ingest 使用同一 idempotency contract | TC-037 |
| AC-075 | FR-021 | mark_price 与 index_price 事件类型在 subject/topic/storage 中分离 | TC-038 |
| AC-076 | FR-021 | mark/index price 可按 instrument/time range 查询，返回统一 envelope | TC-038 |
| AC-077 | FR-021 | mark/index price 不覆盖 spot ticker 或 futures ticker 数据 | TC-038 |
| AC-078 | FR-022 | R2 event/product/governance matrix 覆盖 product_line × event_type × FR/AC/TC 映射 | TC-039 |
| AC-079 | FR-022 | 文档 checker 能阻断旧 topic、旧 product_line、旧 endpoint 或缺失 FR-024 锚点 | TC-039 |
| AC-080 | FR-022 | matrix 变更必须同步 SPEC、TRACEABILITY、ACCEPTANCE、FEATURES 与 checker | TC-039 |
| AC-081 | FR-023 | local evidence bundle 区分 docs checker、runtime unit/integration、boundary gates | TC-040 |
| AC-082 | FR-023 | CI/live evidence 不得由本地 smoke 冒充，必须记录来源、命令和时间 | TC-040 |
| AC-083 | FR-023 | release gate 要求 tag、CHANGELOG、evidence bundle 与 traceability 状态一致 | TC-041 |
| AC-084 | FR-024 | `POST /api/v1/admin/symbols/reload` 会重新读取 catalog 并返回 applied diff | TC-042 |
| AC-085 | FR-024 | reload 可新增或移除 active stream 且无需重启 client 进程 | TC-042 |
| AC-086 | FR-024 | reload 对非法 method/payload/catalog failure 返回稳定错误并保留旧配置 | TC-042 |
| AC-087 | FR-025 | token bucket 感知 spot 1200/futures 2400 weight/min 限流，超限暂停 backfill | TC-043 |
| AC-088 | FR-025 | weight 预算 80% 实时 / 20% backfill；backfill 优先级 trade>bar>tick | TC-043 |
| AC-089 | FR-025 | weight >90% 时暂停 backfill 调度并记录 `backfill.weight_exhausted` 指标 | TC-043 |
| AC-090 | FR-026 | 每日 04:00 UTC coordinator 持锁实例跑 symbol×1d 全量对账 | TC-044 |
| AC-091 | FR-026 | 差异超 tolerance 0.01% 写入 `binance_reconciliation_alerts` 表 | TC-044 |
| AC-092 | FR-026 | 对账完成发布 `binance.control.reconciliation.completed` + 当日统计 | TC-044 |
| AC-093 | FR-027 | 冷数据查询返回 202 + job_id，触发 OSS→taosx 回热（24h TTL 临时表） | TC-045 |
| AC-094 | FR-027 | `GET /api/v1/admin/rehydration/jobs/:job_id` 返回 pending/running/ready/expired | TC-045 |
| AC-095 | FR-027 | 临时表 24h TTL 到期自动删除，重复查询重新触发回热 | TC-045 |
| AC-096 | FR-028 | `GET /api/v1/admin/backfill/jobs` 返回活跃 job 列表含 cursor/progress_pct | TC-046 |
| AC-097 | FR-028 | `GET /api/v1/admin/backfill/coverage/:symbol` 返回 (pl,et) 最早可用时间戳 | TC-046 |
| AC-098 | FR-028 | 失败 job 暴露 last_error/retry_count/next_retry_at 诊断字段 | TC-046 |
| AC-099 | FR-029 | event_time→persist P99 < 200ms，event_time→kafkax fanout P99 < 300ms | TC-047 |
| AC-100 | FR-029 | spot/um_perp/cm_perp 30s、options 60s 无新事件触发 stale alert | TC-047 |
| AC-101 | FR-029 | parser 单测能捕获 Binance 原生字段增删或类型变更的 schema drift | TC-047 |
| AC-102 | FR-030 | Options chain 原始 strike/expiry/option_type/mark/IV 字段进入 MarketFactEnvelope 扩展字段或等价下游 payload | TC-048 |
| AC-103 | FR-030 | Options 原始字段透传不改变 canonical InstrumentKey 或 product_line identity | TC-048 |
| AC-104 | FR-030 | Greeks 派生指标不在 binance 内计算，必须交由分析域消费原始字段后生成 | TC-049 |

---

## §6 覆盖率仪表盘

| 指标 | 总数 | 已覆盖 | 覆盖率 | 说明 |
|------|------|--------|--------|------|
| 功能需求 (FR) | 34 current + 6 draft | 34 current | 100% current trace | 当前 Status-Projection 分母为 34（24 Done / 10 Partial / 0 Pending）；FR-031~FR-036 为 exchangeInfo draft 行（含 FR-035 admin auth + FR-036 连接拓扑），不计入当前投影；6b/6c/6d/7a 作为实现子切片保留在矩阵中 |
| 业务规则 (BR) | 9 current + 3 draft | 9 current | 100% current trace | BR-001 ~ BR-009 为当前基线；BR-010 ~ BR-012 为 exchangeInfo draft（含 BR-012 options 到期峰值平滑），不计入当前投影 |
| 非功能需求 (NFR) | 20 | 20 | 100% | NFR-001 ~ NFR-020 全部有验证方式 |
| 测试用例 (TC) | 49 current + 18 draft | 49 current | 100% current trace | TC-001 ~ TC-049 为当前基线；TC-050 ~ TC-067 为 exchangeInfo draft（含 diff/natsx/auth/连接拓扑/options 到期补强），不计入当前投影 |
| 验收标准 (AC) | 104 current + 24 draft | 104 current | 100% current trace | AC-001 ~ AC-104 为当前基线；AC-105 ~ AC-128 为 exchangeInfo draft（含 natsx stream/diff 引擎/admin auth/连接拓扑补强），不计入当前投影 |
| FR→TC 覆盖率 | — | 34/34 current | 100% | — |
| BR→验证覆盖率 | — | 9/9 current | 100% | — |
| AC→验证覆盖率 | — | 104/104 current | 100% | — |
| R2 governance matrix | 120 cells | 120 cells | 100% | 4 product lines × 6 event types × 5 文档/checker anchors |
| 实现状态（v3.6.1） | — | 24/34 FR Done | 71% Done | 当前有效基线分母 34 = **24 Done / 10 Partial / 0 Pending**；Runtime-Anchor `/home/binance@f18a329`；Issue-Ledger `../../report/binance/issues-sync-20260625.md`；Partial FR 为 FR-007/007a/011/016/017/023/024/026/027/028；FR-031~036 为 draft，不计入当前投影。 |

---

## §7 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-25 | v3.7.0-draft | **exchangeInfo 同步规格草案登记**：新增 FR-031~036 / BR-010~012 / AC-105~128 / TC-050~067，定义于 [`SPEC-exchangeinfo-sync.md`](SPEC-exchangeinfo-sync.md)。第三轮结构性审查修正：拆分 FR-033→FR-033（分类层）+ FR-036（连接拓扑层）；`StreamsForProductLineTier` 按 productLine 分化（options 仅 optionTicker）；control stream retention WorkQueue→LimitsPolicy（multi-server）；diff Updated/SpecUpdated 分离；新增 BR-012 options 到期峰值平滑。这些条目为 draft，不计入 v3.6.1 当前 Status-Projection；当前有效基线仍为 **24 Done / 10 Partial / 0 Pending**。技术依据见 `report/binance/symbol-sync-deep-analysis-20260625.md` 与 `report/binance/exchangeinfo-sync-design-20260625.md` | ZCode |
| 2026-06-25 | v3.6.1 | **Issue-ledger sync + 状态投影纠偏**：基于 Runtime-Anchor `/home/binance@f18a329` 与 Issue-Ledger `../../report/binance/issues-sync-20260625.md`，当前 FR 状态为 **24 Done / 10 Partial / 0 Pending**；Partial FR: FR-007, FR-007a, FR-011, FR-016, FR-017, FR-023, FR-024, FR-026, FR-027, FR-028；GitHub #1104~#1118 与后续 Plan008 issue 已同步闭合；Release closeout 已归档为 `release_closeable=YES`；历史「28 Done / 2 Partial」仅保留为已撤回历史口径。 | Codex |
| 2026-06-25 | v3.6.0 | **历史口径（已被 v3.6.1 覆盖）**：阶段性记录「28 Done / 2 Partial」与 `fix/binance-production-readiness` 投影；当前 issue-ledger 已撤回该口径，不能作为现行状态或关闭依据。 | ZoneCNH |
| 2026-06-25 | v3.6.0 | **历史记录：Plan007 对齐 + main.go 装配级证据标准**：FR 状态从「22 Done / 8 Partial」刷新为「19 Done / 11 Partial / 0 Pending」，对齐 runtime HEAD `e02b190`（Plan007 A1~A10 + B1~B8 已执行）。引入 main.go 装配级证据标准：9 存储类 FR（FR-005/006a-d/007/007a/010/011）writer 代码完整但 main.go 未装配实例（`bootstrap.Spec{Stores: bootstrap.None}` + `NewMemoryIdempotencyStore` + `StorageWriter=nil`），下调为 Partial；6 FR 上调（FR-002/004/008/025/030 Done + FR-016 实质升级 A1 真实 REST）；BR-004 提升为 Done（A3 NakWithDelay+DLQ + JetStream gated 测试）；§6 仪表盘同步刷新；SHA 统一为 `e02b190`。该行仅保留为历史记录；当前有效状态以 Runtime-Anchor `/home/binance@f18a329` 与 Issue-Ledger `../../report/binance/issues-sync-20260625.md` 为准。依据见 `report/binance/production-readiness-assessment-20260625.md` §4.1 G0 | ZoneCNH |
| 2026-06-24 | v3.5.1 | **历史记录：Plan007 A8 — 规格端一致性刷新**：FR 实现状态从「1/30」更新为「22 Done / 8 Partial」，对齐 runtime HEAD `8290dc9`（PR #73 之后真实代码状态）；BR-004 提升为 Partial（natsx NakWithDelay + DLQ deadletter 包已实现）；§6 仪表盘同步刷新；SHA 统一为 `8290dc9`。该行仅保留为历史记录；当前有效状态以 Runtime-Anchor `/home/binance@f18a329` 与 Issue-Ledger `../../report/binance/issues-sync-20260625.md` 为准。 | ZoneCNH |
| 2026-06-23 | v3.5.0 | **历史记录：Freshness/Options traceability closure**：补齐 FR-029~FR-030 的 TC-047~TC-049 与 AC-099~AC-104；R2 matrix 文案统一为 4×6×5 anchors；新增项当时保持 Pending，runtime/release evidence 当时仍未闭合；后续 Plan008 已闭合 release gate，当前状态以 v3.6.1 Runtime-Anchor `/home/binance@f18a329` 与 Issue-Ledger `../../report/binance/issues-sync-20260625.md` 为准。 | ZoneCNH |
| 2026-06-22 | v3.3.0 | **Realtime/Historical/Event/Release 扩展登记**：新增 FR-012~FR-024、TC-029~TC-042、AC-048~AC-086；登记 R2 120-cell governance matrix；统一 FR-024 endpoint 为 `POST /api/v1/admin/symbols/reload`；新增项均保持 Pending，FR-009 runtime evidence 不变 | ZoneCNH |
| 2026-06-16 | v1.0.0 | 从零创建 §1-§7 标准追溯矩阵 | ZoneCNH |
| 2026-06-17 | v1.1.0 | 修复 FR/BR/AC 错位，新增 AC-021~023 边界强制 | ZoneCNH |
| 2026-06-17 | v1.2.0 | BR-002/003 拆分；BR 总数 8→9 | ZoneCNH |
| 2026-06-17 | v1.3.0 | 同步 SPEC v1.0.1 Status 晋升 | ZoneCNH |
| 2026-06-17 | v1.4.0 | runtime 骨架落地，实现状态 0%→71% | ZoneCNH |
| 2026-06-21 | v2.0.0 | **全面重写：gRPC/spool/checkpoint/同进程 → natsx JetStream 分布式架构**：FR-003~006 替换，新增 FR-007~010；BR-004~009 对齐 ManualAck/redisx/ossx/存储所有权；NFR 删除 spool/gRPC 延迟，新增 natsx/taosx/Gin 预算；TC 扩展至 22 条；AC 扩展至 35 条；覆盖率全部 100% | ZoneCNH |
| 2026-06-21 | v2.1.0 | **七模块补全 + 追溯链扩展**：FR-006 拆分为 6a(taosx)/6b(postgresx)/6c(redisx cache)/6d(ossx)；新增 FR-010（clickhousex OLAP）、FR-011（分布式锁）、FR-007a（analytics API）；Config §11 从 14 项扩展至 100+ 项（7 模块 + Gin + Obs + 环境变量）；Error 码 BNC-009~013；Performance Budget 从 8 项扩展至 20 项；Subject 命名统一 um_perp/cm_perp；TC 22→28；AC 35→47；NFR 13→20；dashboard 全量更新 | ZoneCNH |
| 2026-06-22 | v2.2.0 | **命名收敛 + Options depth 补全 + 状态口径修复**：(1) 4 套旧命名全部收敛到 `um_perp/cm_perp`（与根 SPEC §9 natsx subject 表对齐）；(2) 新增 `binance.market.cm_perp.depth` + `binance.market.options.depth` 两条 subject，TASK-CLIENT-006 Scope 加 depth/update events（依据：Binance EOptions `<symbol>@depth1000` WebSocket stream）；(3) FR-001 Partial→Pending（与 client/TRACEABILITY 同步，以 runtime 仓为准） | ZoneCNH |
| 2026-06-22 | v2.2.1 | **Boundary gate runtime evidence 回填**：BR-001/002/003/005/006/007/008/009 与 TC-020/021/022 对齐 `/home/binance/scripts/boundary-gates.sh` 10/10 PASS；BR-004、TC-005 与非边界业务 FR 仍保持 Pending | ZoneCNH |
| 2026-06-22 | v2.2.2 | **PR-C 模块治理收尾**：新建 `CHANGELOG.md`（Keep-a-Changelog 格式）；ACCEPTANCE Module-Version v2.0.0 → v2.2.3、FEATURES Module-Version v2.0.0 → v2.2.2、IMPLEMENTATION-PLAN Version v2.1.2 → v2.2.3；满足 RULES.md R6 + R9 + DRIFT D4 | ZoneCNH |
| 2026-06-23 | evidence-20260623 | **本地 runtime evidence 刷新**：`/home/binance/release/evidence/binance/20260623/` 归档 build/test/race/vet/lint/smoke/boundary gate 证据；验证代码 `9777a5b0db9a3de5db53942b9aaf6b55eec04f24`，证据提交 `20c7712935f53e1948bdf4b30a72d3db07f9acfb`；FR-009/BR 本地边界证据闭合，release、remote CI、live websocket、外部集成与 L2 功能 FR 仍 Pending | ZoneCNH |
| 2026-06-22 | v2.2.3 | **PR-D runtime evidence 回填（历史记录）**：FR-009 状态曾附早期 runtime SHA + CI workflow URL（runtime PR ZoneCNH/binance#9 合并，删除运行时共享包 + 集成 `.github/workflows/boundary-gates.yml` 9 道 gate）；当前证据口径见 2026-06-23 evidence-20260623 行 | ZoneCNH |
| 2026-06-23 | v2.2.4 | **PR-007 runtime boundary evidence refresh**：对齐 `/home/binance/BOUNDARY-GATES.md` §2-§11 与 `scripts/boundary-gates.sh` 10/10 PASS；证据提交 `20c7712935f53e1948bdf4b30a72d3db07f9acfb`，验证代码 `9777a5b0db9a3de5db53942b9aaf6b55eec04f24`；新增 HTTP JSON `/ingest` admin/server boundary evidence；本地 evidence bundle `/home/binance/release/evidence/binance/20260623/`；远端 CI/release tag 与 PR-007a~g 分布式 runtime 仍单独验收 | ZoneCNH |
| 2026-06-23 | v2.2.5 | **standalone client boundary evidence（历史记录）**：曾记录独立 `cmd/binance-client` admin `:8081` self-test 与 HTTP `/ingest` client/server 边界；当前权威证据口径见 2026-06-24 gated JetStream 子集与 2026-06-23 evidence-20260623 行；独立 client/server 进程 TC-005、完整 JetStream TC-004/TC-006（`NakWithDelay`、dead-letter/parking）、live websocket、release tag 与 PR-007a~g 分布式 runtime 仍 Pending | ZoneCNH |
| 2026-06-23 | v2.2.6 | **round 2 证据刷新**：重新运行 `/home/binance/scripts/boundary-gates.sh` 10/10 PASS；`go build`/`go vet`/`go test` 全部 PASS 于 SHA `71e2a6e8bb5591c43e8a2ebfff8c7645bf030786`；全部 9 个 issue 分支已合并至 origin/main；release、remote CI、live websocket、外部集成与 L2 功能 FR 仍 Pending | ZoneCNH |
| 2026-06-23 | v3.5.0 | **审计对齐**：修复 §1 与 §6 FR-001/002 状态矛盾（统一为 Pending）；§6 仪表盘同步；§7 补充 v2.2.6→v3.5.0 版本跳空说明（v3.2.0-implied: fold DATA-LIFECYCLE FR-025~028；v3.3.0: version governance unification；v3.4.0: naming/natsx subject alignment；v3.5.0: FR-029~030 freshness/Options traceability） | ZoneCNH |
