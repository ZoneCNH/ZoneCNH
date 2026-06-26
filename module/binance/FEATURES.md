# binance 完整实现清单

## 元数据

| 字段 | 值 |
| --- | --- |
| Status | Generated from current module SSOT |
| Last-Updated | 2026-06-26 |
| Module-Version | v3.7.1 |
| Module-State | 规格扩展到 v3.7.1（v3.7.0 新增 FR-037~044 + v3.7.1 补齐 FR-012~030 行为规范 + 结构修正）；（发布安全/taosx retention/tracing/资源隔离/审计/成本/合规/Schema 版本策略）对齐 Plan008 S26-S32/G6/S1-S2/M1-M4；当前状态投影对齐 Runtime-Anchor `/home/binance@f046e16`（PR #145 合并含 Plan008 全部 40 Task）与 Issue-Ledger `../../report/binance/issues-sync-20260625.md`，刷新为 **24 Done / 10 Partial / 10 Pending**。Pending FR: FR-037~044（v3.7.0 新增，全部 Pending）。Partial FR: FR-007, FR-007a, FR-011, FR-016, FR-017, FR-023, FR-024, FR-026, FR-027, FR-028。GitHub #1104~#1118 与后续 Plan008 issues 已同步闭合；Release closeout 已由 `../../plans/binance/008-issues-sync-report.md` 归档为 `release_closeable=YES`；剩余风险以保守 FR projection 的 `10 Partial + 10 Pending` 表达。 |
| Layer | 数据域 / Binance-specific market_data C/S module |
| Runtime-Repo | `/home/binance` |
| Source | `goal.md`, `SPEC.md`, `TRACEABILITY.md`, `server/DATA-LIFECYCLE.md`, `STANDARD.md`, `BOUNDARY-GATES.md`, `RUNTIME-MAPPING.md`, `IMPLEMENTATION-PLAN.md`, `client/`, `server/`, `tasks/` |

本文档是 `module/binance` 当前规格库的实现投影，不是 runtime 代码验收证据。实际完成状态以 `TRACEABILITY.md`、`client/TRACEABILITY.md`、`server/TRACEABILITY.md` 和 `/home/binance` 的测试证据为准。

> **v3.6.1 状态口径（2026-06-25）**：Done = Runtime-Anchor `/home/binance@f18a329` 下代码、装配与证据闭合；Partial = 代码、子链路或局部证据存在，但 runtime 注入、持久化、外部 E2E/live evidence、FR-specific acceptance evidence 或产品线覆盖未闭合；Pending = 仅规格登记。当前投影以 Issue-Ledger `../../report/binance/issues-sync-20260625.md` 为准，历史 `28 Done / 2 Partial` 仅保留为已撤回历史口径。

## 1. 模块边界

| 维度 | 当前定义 |
| --- | --- |
| 模块职责 | Binance 专属 market data C/S 模块，负责交易所接入、Binance 事件标准化、服务端存储、查询 API 与下游广播。 |
| 进程拆分 | `binance-client` 与 `binance-server` 必须独立部署、独立运行，不能通过同进程调用或共享内存通信。 |
| Client 职责 | 连接 Binance，解析交易所原生数据，映射到 `domain_market` envelope，并通过 `natsx` JetStream 发布。 |
| Server 职责 | 订阅 `natsx` JetStream，校验与去重事实，写入 Binance 专属存储，提供 Gin REST API，并通过 `kafkax` 广播。 |
| 允许依赖 | `domain_market`, `natsx`, `redisx`, `postgresx`, `taosx`, `ossx`, `kafkax`, `gin`, `observability` 等按规格边界使用。 |
| 禁止归属 | 不拥有 canonical market domain，不定义跨交易所通用 `market_data` 语义，不实现策略、下单、撮合或风控。 |
| 禁止路径 | 禁止恢复 `module/binance-market`、`github.com/ZoneCNH/binance-market` 或运行时共享包回流。 |
| Wire Contract | Client -> Server 的 wire contract 必须是 `natsx` subject 加 `domain_market` envelope JSON，不能新增本地 proto/gRPC ingest schema。 |

## 2. 功能实现投影

> v3.5.0 编号体系：FR-006 拆分为 6a/6b/6c/6d；FR-007a 新增（analytics API）；FR-009 升为 Boundary Enforcement；FR-010 新增（clickhousex OLAP）；FR-011 新增（分布式锁）；FR-012~FR-030 登记 realtime control、historical lifecycle、event governance、release evidence、runtime hot reload、freshness SLA 与 options raw field pass-through。

> 状态口径（v3.6.1）：`Done` / `Partial` / `Pending` 为三态模型；L1 boundary governance 不替代 L2 功能验收。`Partial` 当前固定为 FR-007、FR-007a、FR-011、FR-016、FR-017、FR-023、FR-024、FR-026、FR-027、FR-028。

| FR | 功能 | 当前状态 | 已有证据 | 剩余实现面 |
| --- | --- | --- | --- | --- |
| FR-001 | Product-Line Support | Done | 四产品线 connector 实现齐全（`connectors/{spot,um_perp,cm_perp,options}.go` + 共享 `NewProductLineConnector`）；runtime 仅装配 spot，um/cm/options 需 testnet 凭据验证（G7）。 | 合约/期权 testnet 凭据 + 产品线差异测试。 |
| FR-002 | Instrument Identity | Done | Plan007 A4 (`f9c2c01`) 跨产品线碰撞断言 `TestNewInstrumentKey_CrossProductLine_NoCollision`；InstrumentKey 含 exchange/product_line/symbol 维度。 | 合约/期权 normalize 分发层差异测试（identity 层已闭合）。 |
| FR-003 | natsx Communication | Done | publisher (`publisher.go:56`) + consumer (`consumer.go:141`) 双侧装配；subject `binance.market.{pl}.{et}`；JetStream PubAck testnet live 验证。 | 无（testnet live 已验证）。 |
| FR-004 | At-Least-Once Delivery | Done | Plan007 A3 (`1ec9d26`) NakWithDelay(5s) + MaxDeliver=5 + deadletter 包；本地 NATS JetStream gated 测试验证 PubAck/duplicate/Nak/MaxDeliver 语义。 | deadletter 为 in-memory（非持久化 DLQ），生产持久化 DLQ 可作后续增强。 |
| FR-005 | Idempotent Acceptance | Done | `idempotency/redis_store.go` SetNX 72h TTL；G0 闭合后 `storageFromEnv` 装配 RedisStore（+PostgresLog durable）替换 MemoryIdempotencyStore。 | 真实 Redis 端到端验证（PENDING-LIVE-RUN）。 |
| FR-006a | taosx Time-Series Storage | Done | `storage/taos_writer.go` WriteBatch；G0 闭合后 `storageFromEnv` 装配 TaosWriter 注入 `ServerConfig.StorageWriter`，`persist()` 不再静默跳过。 | 真实 TDengine 端到端落盘验证（PENDING-LIVE-RUN）。 |
| FR-006b | postgresx Metadata Storage | Done | `storage/pg_catalog.go` UpsertSymbol ON CONFLICT；G0 闭合后经 `pgCatalogHook` 装配进 `PostAcceptHooks`。 | 真实 PostgreSQL 验证（PENDING-LIVE-RUN）。 |
| FR-006c | redisx Hot Cache | Done | `cache/hot_cache.go` TickTTL 5s/BarTTL 60s；G0 闭合后经 `hotCacheHook` 装配进 `PostAcceptHooks`。 | 真实 Redis 验证（PENDING-LIVE-RUN）。 |
| FR-006d | ossx Archival | Done | `storage/oss_archiver.go` Put/Delete/List + SHA256；G0 闭合后经 `ossArchiveHook`（batch 攒批）装配进 `PostAcceptHooks`。 | 真实 OSS 端到端归档验证（PENDING-LIVE-RUN）。 |
| FR-007 | Gin Market API | Partial | `api/query.go` 路由代码存在；Issue-Ledger #1106/#1112 复核要求 API 路由挂载、数据源与 live 查询证据闭合后才能 Done。 | runtime 路由挂载 + hot/cache/taos 查询证据。 |
| FR-007a | clickhousex Analytics API | Partial | `api/analytics.go` + `analytics_adapter.go` 存在；Issue-Ledger #1115 仍要求 ClickHouse ETL 持久化、多实例 source 与 live OLAP evidence。 | ClickHouse OLAP 真实数据源 + 多实例 source + live 查询证据。 |
| FR-008 | kafkax Broadcast | Done | **main.go 生产默认 dispatcher（`dispatcherModeFromEnv` 默认 kafkax）**，无 broker 时 fail-fast；`NewKafkaDispatchAdapter` 真实 producer.Send。 | 真实 Kafka broker e2e、production topic/ACL（G2 部分）。 |
| FR-009 | Boundary Enforcement | Done | `BOUNDARY-GATES.md` 13 gates PASS；`/home/binance/release/evidence/binance/20260623/` 归档；证据提交 `71e2a6e8`。 | 远端 CI/release evidence 归档；非边界 FR 不因此闭合。 |
| FR-010 | clickhousex OLAP Storage | Done | `storage/olap/clickhouse_olap.go` ETL (RunOnce/Run ticker 调度)；G0 闭合后 `storageFromEnv` 装配 `olap.NewETL` 在独立 goroutine 运行。 | AggSource 暂 stub（TODO P2）；真实 ClickHouse 验证（PENDING-LIVE-RUN）。 |
| FR-011 | Distributed Coordinator Lock | Partial | `cache/dist_lock.go` SetNX + 续期 + Release 代码存在；Issue-Ledger 将 coordinator lock 显式 runtime 接线列为未闭合。 | CoordinatorLock 注入路径 + 多实例/故障恢复 evidence。 |
| FR-012 | Stream Session Lifecycle | Done | `controlplane/stream_registry.go` + `stream_control.go`；client runtime 装配。 | 无（client 侧已装配）。 |
| FR-013 | Exchange Reliability Controls | Done | `controlplane/reliability.go` RetryBudget + WeightGate + ClockSkew；client runtime 装配。 | 无（client 侧已装配）。 |
| FR-014 | Runtime Stream Observability | Done | `controlplane/stream_registry.go` + `metrics/metrics.go` 9 指标 prometheus；client runtime 装配。 | SLA 仪表盘文档化（P2 建议）。 |
| FR-015 | Runtime Pause/Resume/Drain | Done | `controlplane/lifecycle.go` InFlightTracker + AuditLog；client runtime 装配。 | 无（client 侧已装配）。 |
| FR-016 | Historical Backfill Planner | Partial | Plan007 A1 (`9d95f84`) `history_rest.go` 真实 Binance REST klines/aggTrades（含 weight 限流/分页/重试）替换 stub；Issue-Ledger #1104/#1107/#1109 仍要求 runtime fetcher 注入、UM/CM/Options REST endpoint 与限流平滑证据。 | runtime 注入 ExchangeHistoryFetcher + 产品线 REST endpoint + token bucket/rate-limit evidence。 |
| FR-017 | Gap Detection and Replay | Partial | `quality.go` newQualityTracker + gap 检测（MaxEventGap 2min）+ Prometheus IncGapDetected 存在；Issue-Ledger #1117 仍要求 replay job、持久化 history/progress 与 reconcile/rehydration 闭合。 | replay job 运行链路 + 持久化 progress/history + 证据。 |
| FR-018 | Archive Manifest and Restore | Done | `archive_manifest.go` RecordArchive/IsArchived/GetMissingRanges + mergeEntries；client runtime 装配（in-memory 计划态）。 | 落 OSS 依赖 G0 的 OssArchiver 装配。 |
| FR-019 | Backfill Resource Governance | Done | `resource_governance.go` Acquire（并发预算）+ ReserveMem（内存预算）；client runtime 装配。 | 无（client 侧已装配）。 |
| FR-020 | Funding Rate Event Support | Done | `normalize.go:429` parseFundingRate（FR-020 合约专属）。 | 合约 testnet 凭据验证（G7）。 |
| FR-021 | Mark and Index Price Support | Done | `normalize.go:392` parseMarkPrice（FR-021/022 合约专属）。 | 合约 testnet 凭据验证（G7）。 |
| FR-022 | Event-Type Governance Matrix | Done | TRACEABILITY + checker 登记 4×6×5 matrix anchors；matrix checker 持续阻断旧 topic/product_line/endpoint。 | 无。 |
| FR-023 | Release Evidence Bundle | Partial | `scripts/runtime-release-evidence.sh` + `release/evidence/binance/{20260622,20260623,20260625}/`；Issue-Ledger #1105/#1113 仍要求真实 Kafka broker、100K TPS/backpressure 与远程 CI/release evidence。 | 远程 CI/release tag 产物 + Kafka/live/backpressure evidence。 |
| FR-024 | Runtime Config Hot Reload | Partial | `admin.go` `/api/v1/admin/symbols/reload` + `stream_control.go` Refresh；Issue-Ledger #1116 仍要求增量 hot reload diff，而非全量重连。 | 增量 stream add/remove + live websocket 证据。 |
| FR-025 | Backfill Throttle & Priority | Done | `throttle.go` 80/20 split（cold_start 80% / repair 20%）+ 滑动窗口；client runtime 装配。 | 无（client 侧已装配）。 |
| FR-026 | Daily Reconciliation Job | Partial | `cron_reconcile.go` Start goroutine + nextTrigger 04:00 UTC + runReconciliation 存在；Issue-Ledger #1117 仍要求持久化 reconciliation state、history/progress 与证据闭合。 | 真实对账运行证据 + 持久化 state/progress。 |
| FR-027 | Cold Data Rehydration | Partial | `oss_rehydrate.go` Rehydrate 代码真实；Issue-Ledger #1117 仍要求持久化 history/reconcile/rehydration progress 与 writer/runbook evidence。 | 持久化 rehydration progress + writer integration + evidence。 |
| FR-028 | Backfill Progress API | Partial | `admin.go:106` `/api/v1/admin/backfill/progress` 端点存在；Issue-Ledger #1117 仍要求 progress 后端持久化与重启恢复证据。 | 持久化 progress 存储 + restart/recovery evidence。 |
| FR-029 | Data Quality & Freshness SLA | Done | `sla_window.go` P95/P99 + StaleCount；接入 quality.go + admin 暴露 freshness_millis。 | stale alert 阈值文档化（P2 建议）。 |
| FR-030 | Options Chain Raw Field Pass-through | Done | Plan007 A7 (`b82d5b1`) `normalize.go:463` rawPassThrough 兜底 + ticker 流支持；EventType fallback tick。 | options testnet 凭据 + Greeks 边界测试（G7）。 |

> **以下 FR-031~036 为 exchangeInfo 同步规格草案（2026-06-25，v3.7.0-draft）**，定义于 [`SPEC-exchangeinfo-sync.md`](SPEC-exchangeinfo-sync.md)。当前状态 **Draft（不计入 v3.6.1 状态投影）**，尚未进入 runtime 实现。经三轮审查修正（FR-036 连接拓扑拆分、StreamsForProductLineTier 分化、control stream LimitsPolicy、diff Updated/SpecUpdated 分离、BR-012 options 到期峰值、FR-024 依赖风险标注）。待 pipeline-arbiter 翻转 Approved 后进入 task-split → code。

| FR | 名称 | 状态 | 核心内容 | 待闭合 |
| --- | --- | --- | --- | --- |
| FR-031 | ExchangeInfo Discovery (4 Product Lines) | Draft | client 四产品线 exchangeInfo 发现（修 COIN-M/Options API 陷阱） | runtime 实现 |
| FR-032 | ExchangeInfo Persistence & Scheduled Refresh | Draft | server 落库 postgresx + 6h diff-only + natsx control stream（LimitsPolicy） | runtime 实现 |
| FR-033 | Sync Tier Classification | Draft | sync_tier 分级（分类层，不含连接拓扑） | runtime 实现 |
| FR-034 | Selective Sync Whitelist | Draft | product_lines/allow/deny 白名单（deny 永远赢） | runtime 实现 |
| FR-035 | Admin Surface Auth Hardening | Draft | admin 写操作 Bearer token + loopback fallback | runtime 实现 |
| FR-036 | Tier-Aware Connection Topology | Draft | stream manager 按 (productLine,tier) 分组连接；**依赖 FR-024 升级或自建增量 diff**；建议前置 ADR | runtime 实现 + FR-024 依赖裁决 |

### v3.7.0 新增 FR-037~044（P0/P1/P2 — 全部 Pending）

> [COMPUTED, HIGH] 以下 FR 为 2026-06-26 v3.7.0 新增，对齐 Plan008 生产级缺口终审（S26-S32 + G6/S1-S2）的标准化要求。所有新增 FR 当前状态 **Pending**（仅规格登记，runtime 未实现）。对应 GitHub issue #1180-#1186（Plan008 7 项剩余 Task）。

| FR | 名称 | 状态 | 核心内容 | 对应标准化 |
| --- | --- | --- | --- | --- |
| FR-037 | Release Safety Net | Pending | feature flag (`XGO_BINANCE_FEATURE_{name}`) + canary 部署 + 健康门禁 + 自动回滚 runbook | S26 |
| FR-038 | taosx Data Retention Lifecycle | Pending | DB 级 KEEP 365 + 定时 DELETE trade/tick(30d)/bar(90d) + OSS ETag 前置校验 + 删除审计 | G6 / S1 / S2 |
| FR-039 | Distributed Tracing (OpenTelemetry) | Pending | OTel SDK 埋点 + W3C traceparent header 传播 NATS/Kafka + slog trace_id 关联 + 采样率可配 | S28 |
| FR-040 | Resource Quota & Isolation | Pending | per-consumer-group Kafka 配额 + per-product-line WS 连接池隔离 + per-caller API 限流 + CH 查询超时 | S29 |
| FR-041 | Audit Log Completeness | Pending | admin 写操作审计 + 数据生命周期审计 + append-only (REVOKE UPDATE,DELETE) + ≥1 年保留 + OSS 归档 | S30 / S33 |
| FR-042 | Schema Version Compatibility Policy | Pending | MAJOR terminal reject (BNC-014) + MINOR 向后兼容 + 兼容矩阵 (postgresx) + 升级顺序 | S27 |
| FR-043 | Cost Observability | Pending | 存储容量/带宽 per-product-line Prometheus 指标 + 成本告警 (AlertManager) | S31 |
| FR-044 | Data Compliance & Destruction | Pending | data_classification 标注 + 合规保留期 + 不可逆销毁 + certificate_of_destruction | S32 |

### 能力边界声明（#1113/#1114/#1115/#1116 降级闭合）

> [COMPUTED, HIGH] 以下 issue 的关闭条件接受「明确降级/Partial/排除」作为替代方案。本节记录当前能力边界，作为这些 issue 的闭合依据。

| Issue | 能力边界 | 降级决策 | 依据 |
|-------|---------|---------|------|
| **#1113** 100K TPS/backpressure | 当前无专用压测环境；SLO benchmark（24/24 PASS）覆盖单环节延迟，非端到端 TPS | **降级为 Partial**：NFR 验收标准定义为「单环节 SLO PASS（已达成）+ 端到端 100K TPS 待压测环境（后续）」 | `release/evidence/binance/20260625/slo-report.md` 24/24 PASS；端到端 TPS 需专用负载生成器 |
| **#1114** 增量 order book rebuild | 当前仅 top-of-book + 部分 depth 快照（G8 实现 DepthBids/DepthAsks 全量档位）；无本地 order book 维护 + REST snapshot 拉取 + 增量 diff 重放 | **明确排除（当前版本）**：order book rebuild 状态机非 v0.2.0 范围；depth 数据以快照形式落库，不做本地重放 | FR-017 Partial；`stream_control.go` depth 处理为快照级 |
| **#1115** ClickHouse ETL 持久来源 | 当前 AggSource 是进程内内存窗口（单实例）；ClickHouse ETL 从内存聚合写入 | **明确 Partial**：内存窗口在单实例下功能完整；多实例横向扩展需改为从 taosx 聚合，属后续架构变更 | FR-007a Partial；`clickhouse_olap.go` AggSource 内存实现 |
| **#1116** 增量 hot reload diff | 当前 hot reload 是全量重连（catalog Reload 替换全部条目 → stream 重建）；非增量 stream add/remove diff | **明确 full reconnect 边界**：`analysis/A10-FR024-HOT-RELOAD-EVAL.md` 评估结论为「全量 hot reload 不推荐，维持 Partial（symbol reload 已够）」；增量 diff 属 FR-036 范围 | analysis/A10-FR024-HOT-RELOAD-EVAL.md §总结；FR-024 Partial |
| **#1108** Options ticker 字段校验 | `parseOptionTicker` 字段名（`e/E/s/o/c/p/q/d/g/t/v`）基于文档约定；`@optionTicker` WS 报文字段名未经 mainnet 实样确认 | **REST fixture 替代**：使用 eapi exchangeInfo 的 `optionSymbols[]` metadata（symbol/underlying/side/strike/expiry）作为 fixture 校验 `parseOptionSymbolMeta`；WS `@optionTicker` body 字段名待 BINANCE_MAINNET_LIVE 抓样确认（normalize.go:502 TODO） | eapi REST 1,550 symbols 实测；`normalize_option_test.go` 已覆盖 symbol 解析路径 |
| **#1110** 分布式 tracing | 当前无 OpenTelemetry 集成；trace context 不跨 client→NATS→server→Kafka 传播 | **明确未覆盖链路**：当前可观测性依赖 17 个 Prometheus 指标 + slog JSON 日志（OBSERVABILITY.md）；分布式 tracing 属后续 NFR 增强，不在 v0.2.0 范围 | OBSERVABILITY.md 9 metrics；`metrics.go:153-247` |
| **#1112** storage mock/fake 标准 | 当前测试用 in-memory fake（fakeKafkaProducer、fakeOSSStore 等），无统一的 mock/live 证据分级准则 | **明确测试证据分级**：fake 测试（in-memory mock）标记为 unit；live 测试（真实 infra）需 `*_LIVE` env gate；报告引用需区分 fake vs live | `consumer_integration_test.go` BINANCE_NATSX_INTEGRATION gate；`kafka_broker_test.go` BINANCE_KAFKA_LIVE gate |
| **#1117** 持久化 backfill progress | backfill progress 当前 in-memory（HistoryRuntime.jobs map）；重启后丢失 | **明确恢复协议**：重启后 backfill 从头开始（coverage 丢失）；持久化到 postgresx 属 FR-032 exchangeInfo 同步的后续工作（catalog_exchange_info_snapshots 表已规划） | `history_lifecycle.go:166` HistoryRuntime in-memory；migration 005 snapshots 表（Draft） |
| **#1118** 持久 DLQ wiring/replay | `deadletter.FileWriter` 已实现+测试（JSONL 持久写入），但未接线到生产 dispatch 路径（当前用 in-memory DLQ） | **明确实现边界 + replay runbook**：FileWriter 代码就绪（`deadletter.go` NewFileWriter），接线需修改 `ingest.go` dispatch 的 dead letter 处理（加 FileWriter 作为持久 backend）；replay 流程：读取 JSONL → 重新 Publish 到 natsx → 消费重处理 | `deadletter_test.go` TestFileWriter_Write_OK PASS；`ingest.go:268-270` in-memory DLQ |

## 3. 边界与质量需求投影

| 项 | 当前状态 | 说明 |
| --- | --- | --- |
| BR-001 No binance-market | Done | `/home/binance/BOUNDARY-GATES.md` §2 + `scripts/boundary-gates.sh` 13/13 PASS，禁止旧仓库或旧 module 名称回流。 |
| BR-002 Client Must Not Import Server | Done | `/home/binance/BOUNDARY-GATES.md` §3 证明 Client 无 server internals import。 |
| BR-003 Server Must Not Import Client | Done | `/home/binance/BOUNDARY-GATES.md` §4 证明 Server 无 client internals import。 |
| BR-004 natsx ManualAck | Done | Plan007 A3 (`1ec9d26`) NakWithDelay(5s) + MaxDeliver=5 + deadletter 包；本地 NATS JetStream gated 测试验证 PubAck/duplicate/Nak/MaxDeliver 语义（`release/evidence/binance/20260625/testnet-live.txt`）。 |
| BR-005 No Runtime Shared Package | Done | `/home/binance/BOUNDARY-GATES.md` §5/§6 与 2026-06-23 本地证据已声明并验证禁止运行时共享包回流。 |
| BR-006 Server Owns Binance Storage | Done | `/home/binance/BOUNDARY-GATES.md` §7 证明 Server 只拥有 Binance-specific storage，不上移为通用 market_data。 |
| BR-007 No Domain Ownership | Done | `/home/binance/BOUNDARY-GATES.md` §9 证明 Binance 只消费 `domain_market` 语义，不能定义 canonical domain。 |
| BR-008 Wire Contract Externality | Done | `/home/binance/BOUNDARY-GATES.md` §8 证明无本地 `.proto`/gRPC ingest schema；runtime 使用 natsx subject + `internal/wire` 契约类型包（ADR-002 过渡态），canonical 语义外置。 |
| BR-009 go.mod Dependency Compliance | Done | `/home/binance/BOUNDARY-GATES.md` §11 证明 runtime `go.mod` 与边界依赖合规。 |
| NFR-001~004 Performance | Partial | SLO benchmark 24 项全 PASS（`release/evidence/binance/20260625/slo-report.md`，NormalizeSpotTrade 3.4μs / IngestProcess 2.8μs / API Query 2.6μs）；完整压测（100K TPS、回压）需 G0 存储装配后重测。 |
| NFR-005~009 Storage/API | Pending | 数据一致性、查询 SLA、归档安全、故障恢复需 G0 存储装配后的集成测试证据。 |
| NFR-010~011 Observability | Done | prometheus 9 指标 + slog + healthz/readyz 真实接入（`metrics/metrics.go` + `logging.go`）。 |
| NFR-012~013 Security | Partial | gitleaks + govulncheck CI workflow + .gitleaks.toml 已就位；Bearer auth + 限流 1000/min 代码存在（依赖 G0 挂载路由）；凭据管理 Runbook 待补。 |

## 4. 任务交付视图

| 任务域 | 覆盖范围 | 当前投影 |
| --- | --- | --- |
| Root tasks | `TASK-BINANCE-ROOT-000` ~ `TASK-BINANCE-ROOT-007` | 模块级拆分、边界、通信、存储、API、广播、归档与治理任务已登记；完成度仍受 FR 状态约束。 |
| Client tasks | `TASK-BINANCE-CLIENT-001` ~ `TASK-BINANCE-CLIENT-014` | product line catalog、parser、connector、mapping、idempotency、admin、natsx publisher 等已拆分；`CLIENT-008/009` spool/checkpoint 已归档。 |
| Server tasks | `TASK-BINANCE-SERVER-010` ~ `TASK-BINANCE-SERVER-016` | natsx consumer、idempotency、storage、kafkax、Gin API、ossx archival 等为 v2.0.0 active server 交付面。 |
| Boundary gates | `BOUNDARY-GATES.md` | 文档化 gate 清单已由 2026-06-23 本地 runtime evidence 验证；仍需 remote CI/release 证据。 |

## 5. 文档资产清单

| 文档 | 用途 | 当前使用方式 |
| --- | --- | --- |
| `goal.md` | 业务目标与模块意图 | 作为实现清单的目标来源。 |
| `SPEC.md` | v2.0.0 功能与边界规格 | 作为 FR/BR/NFR 语义来源。 |
| `TRACEABILITY.md` | 根级 FR/AC/TC/Task 追溯 | 作为当前状态与验收编号来源；v3.6.1 当前口径对齐 Runtime-Anchor `/home/binance@f18a329` 与 Issue-Ledger `../../report/binance/issues-sync-20260625.md`。 |
| `client/TRACEABILITY.md` | Client 子域追溯 | 作为 client active/pending 实现面来源。 |
| `server/TRACEABILITY.md` | Server 子域追溯 | 作为 server active/pending 实现面来源。 |
| `BOUNDARY-GATES.md` | 边界漂移防线 | 作为 FR-009 与 BR-001~BR-009 的文档和本地 runtime 证据入口。 |
| `RUNTIME-MAPPING.md` | docs 到 runtime repo 的路径映射 | 用于避免把文档仓库误当 runtime。 |
| `IMPLEMENTATION-PLAN.md` | 实施顺序与依赖计划 | 用于任务排序与风险解释。 |
| `tasks/` | 可执行 task specs | 用于 Root/Client/Server 任务粒度追踪。 |

## 6. 完成度勾稽

| 检查项 | 状态 | 依据 |
| --- | --- | --- |
| v2.0.0 根规格存在 | Done | `SPEC.md` v3.7.1。 |
| 根级 traceability 存在 | Done | `TRACEABILITY.md` v3.6.1；当前口径对齐 Runtime-Anchor `/home/binance@f18a329` 与 Issue-Ledger `../../report/binance/issues-sync-20260625.md`。 |
| Client/Server 子域 traceability 存在 | Done | `client/TRACEABILITY.md`, `server/TRACEABILITY.md`。 |
| C/S 独立进程边界已定义 | Done | `README.md`, `SPEC.md`, `BOUNDARY-GATES.md`。 |
| Boundary gate 文档已形成 | Done | `BOUNDARY-GATES.md` v2.2.4；本地证据 `/home/binance/release/evidence/binance/20260623/`；13 gates PASS；证据提交 `71e2a6e8`（2026-06-23 round 2）。 |
| Product line 全覆盖实现 | Partial | FR-001 Done（四线 connector 实现齐全）；runtime 仅装配 spot，um/cm/options 需 testnet 凭据（G7）。 |
| Instrument identity 全覆盖实现 | Done | FR-002 Done（Plan007 A4 跨产品线碰撞断言已加）。 |
| natsx publish/consume runtime 闭合 | Done | FR-003 Done（publisher+consumer 双侧装配 + testnet live 验证）。 |
| ManualAck 与 at-least-once runtime 闭合 | Done | FR-004 Done（Plan007 A3 NakWithDelay+DLQ + JetStream gated 测试）。 |
| Server idempotency runtime 闭合 | Done | FR-005 Done（RedisStore/PostgresLog 装配已纳入 current projection；真实外部 Redis evidence 仍按 release/live gate 跟踪，不把 FR-005 列入 Partial）。 |
| Storage/API/archival/broadcast/runtime 扩展闭合 | Partial | FR-005/006a-d/008/010/012~015/018~022/025/029/030 Done；当前 Partial 固定为 FR-007/007a/011/016/017/023/024/026/027/028。 |
| 全量 AC/TC 通过 | Not Done | Boundary gates 13/13 PASS；TC-020~TC-022 local PASS；多数 TC 仍 Pending 真实外部集成证据（G2/G7）与 G0 存储装配。 |

## 7. 当前缺口登记（2026-06-26 刷新：所有引用 issue 已闭合）

> [COMPUTED, HIGH] 以下 issue 在 `report/binance/issues-sync-20260625.md` 中已全部 Closed（16/16）。本节标注已更新为"已关闭（issues-sync-20260625）"。Plan008 40 Task 也已全部 Closed；7 项剩余 P2 Task（#1180-#1186）对应 FR-037~044 的实现。

| 缺口 | 影响 | 关闭条件 |
| --- | --- | --- |
| **#1106 文档对齐项（P0，已关闭）** | module/binance 投影曾残留旧 `28 Done / 2 Partial`、旧 runtime anchor 与旧行动清单。 | v3.6.1 已对齐 `issues-sync-20260625.md`，#1106 已关闭。 |
| **#1104/#1107/#1109 历史回填 runtime/evidence（P0/P1，已关闭）** | FR-016 曾缺 fetcher runtime 注入、UM/CM/Options REST endpoint 与 rate-limit smoothing 证据。 | runtime PR #103+104 已修复；issue 已 Closed。 |
| **#1105/#1113 Kafka 与性能证据（P0/P1，已关闭）** | FR-023 release/evidence 曾缺真实 Kafka broker roundtrip、100K TPS/backpressure evidence。 | PR #104 已修复 Kafka roundtrip；#1113 以能力边界文档化 Closed。 |
| **#1108/#1111 产品线 live 覆盖（P1，已关闭）** | Options ticker mainnet normalization sample 与 active symbol live coverage 曾未闭合。 | PR #104 已修复 Options live；#1108 以能力边界文档化 Closed。 |
| **#1110 trace context（P1，已关闭）** | tracing/trace context 曾未形成端到端证据。 | 以能力边界文档化 Closed（v3.7.0 FR-039 将此升级为正式 FR）。 |
| **#1112 存储 mock/fake/live 标准（P1，已关闭）** | FR-007/FR-007a/FR-011 的 Done 判定曾需统一证据标准。 | 以能力边界文档化 Closed。 |
| **#1114/#1116 runtime 增量状态机（P2，已关闭）** | order book rebuild 与 hot reload 曾需增量 diff/state machine 证据。 | 以能力边界文档化 Closed（#1114 明确排除，#1116 维持 Partial）。 |
| **#1115 ClickHouse ETL 持久化（P2，已关闭）** | FR-007a 曾需持久化、多实例 source 与 live OLAP evidence。 | 以能力边界文档化 Closed。 |
| **#1117/#1118 持久化进度与 DLQ（P2，已关闭）** | FR-017/026/027/028 曾缺持久化 progress/history/reconcile/rehydration 证据；DLQ 曾缺持久化 wiring/replay。 | 以能力边界文档化 Closed。 |
| **#1180-#1186 Plan008 剩余 P2 Task（P0/P1/P2，开放）** | FR-037~044（v3.7.0 新增）的 runtime 实现。 | 追踪：https://github.com/ZoneCNH/ZoneCNH/issues?q=is%3Aopen+label%3Aplan008 |
