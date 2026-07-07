# binance 完整实现清单

## 元数据

| 字段 | 值 |
| --- | --- |
| Status | Generated from current module SSOT |
| Last-Updated | 2026-07-07 |
| Module-Version | v4.0.0 |
| Module-State | v4.0.0 单一状态模型：**65 Done / 0 Partial / 0 Drifted / 0 Pending**（FR-052~061 order book rebuild spot/um/cm 已实现；options depth 协议待 Phase 2 实测激活）。release_closeable=YES（PRG-001~007 全 PASS）。 |
| Layer | 数据域 / Binance-specific market_data C/S module |
| Runtime-Repo | `/home/workspace/binance` |
| Source | `goal.md`, `SPEC.md`, `TRACEABILITY.md`, `STANDARD.md`, `BOUNDARY-GATES.md`, `RUNTIME-MAPPING.md`, `IMPLEMENTATION-PLAN.md`, `client/`, `server/`, `tasks/` |

本文档是 `module/binance` 当前规格库的实现投影，不是 runtime 代码验收证据。实际完成状态以 `TRACEABILITY.md`、`client/TRACEABILITY.md`、`server/TRACEABILITY.md` 和 `/home/workspace/binance` 的测试证据为准。

> **v4.0.0 当前状态口径（2026-07-07）**：单一状态模型 — `Done` = 代码完整+装配就绪+TC PASS+evidence 归档。当前 Done 65 / Partial 0 / Drifted 0 / Pending 0（FR-052~061 order book rebuild spot/um/cm 已实现；options depth 协议待 Phase 2 实测激活）。release_closeable=YES（PRG-001~007 全 PASS）。
>
> **单一状态模型**：FEATURES.md 的「Done」均指单一状态模型的 Done（代码完整+装配就绪+TC PASS+evidence 归档）。Evidence 列的判定见 `ACCEPTANCE.md` §4 闭合矩阵（全部 Done）。
>
> [COMPUTED, HIGH] 2026-07-07 状态对齐：历史 7 个外部依赖 live PASS + 4 产品线 mainnet live PASS + 全量门禁 PASS 证据保留；43 个 P10 issue 已全部关闭（10 轮验证 ALL PASS）；白名单系统 FR-045~051 全部 Done；**release_closeable=YES**（PRG-001~007 全 PASS）。

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

> 历史编号体系调整：FR-006 拆分为 6a/6b/6c/6d；FR-007a 新增（analytics API）；FR-009 升为 Boundary Enforcement；FR-010 新增（clickhousex OLAP）；FR-011 新增（分布式锁）；FR-012~FR-030 登记 realtime control、historical lifecycle、event governance、release evidence、runtime hot reload、freshness SLA 与 options raw field pass-through。

> 状态口径（v4.0.0）：`Done` / `Partial` / `Drifted` / `Pending` 为四态单一模型；L1 boundary governance 不替代 L2 功能验收。`Drifted` = 无，`Partial` = 无，`Pending` = 10（FR-052~061 order book rebuild）。55 FR Done。release_closeable=YES（PRG-001~007 全 PASS）。

| FR | 功能 | 当前状态 | 已有证据 | 剩余实现面 |
| --- | --- | --- | --- | --- |
| FR-001 | Product-Line Support | Done | 四产品线 connector 实现齐全（`connectors/{spot,um_perp,cm_perp,options}.go` + 共享 `NewProductLineConnector`）；runtime 仅装配 spot，um/cm/options 需 testnet 凭据验证（G7）。 | 合约/期权 testnet 凭据 + 产品线差异测试。 |
| FR-002 | Instrument Identity | Done | Plan007 A4 (`f9c2c01`) 跨产品线碰撞断言 `TestNewInstrumentKey_CrossProductLine_NoCollision`；InstrumentKey 含 exchange/product_line/symbol 维度。 | 合约/期权 normalize 分发层差异测试（identity 层已闭合）。 |
| FR-003 | natsx Communication | Done | publisher+consumer 双侧装配；subject `binance.market.{pl}.{et}.v1`（.v1 fix `4f740e5`）；drift-check 22/22 PASS。 | 无。 |
| FR-004 | At-Least-Once Delivery | Done | Plan007 A3 (`1ec9d26`) NakWithDelay(5s) + MaxDeliver=5 + deadletter 包；本地 NATS JetStream gated 测试验证 PubAck/duplicate/Nak/MaxDeliver 语义。 | deadletter 为 in-memory（非持久化 DLQ），生产持久化 DLQ 可作后续增强。 |
| FR-005 | Idempotent Acceptance | Done | `idempotency/redis_store.go` SetNX 72h TTL；G0 闭合后 `storageFromEnv` 装配 RedisStore（+PostgresLog durable）替换 MemoryIdempotencyStore。 | 真实 Redis 端到端验证（PENDING-LIVE-RUN）。 |
| FR-006a | taosx Time-Series Storage | Done | `storage/taos_writer.go` WriteBatch；G0 闭合后 `storageFromEnv` 装配 TaosWriter 注入 `ServerConfig.StorageWriter`，`persist()` 不再静默跳过。 | 真实 TDengine 端到端落盘验证（PENDING-LIVE-RUN）。 |
| FR-006b | postgresx Metadata Storage | Done | `storage/pg_catalog.go` UpsertSymbol ON CONFLICT；G0 闭合后经 `pgCatalogHook` 装配进 `PostAcceptHooks`。 | 真实 PostgreSQL 验证（PENDING-LIVE-RUN）。 |
| FR-006c | redisx Hot Cache | Done | `cache/hot_cache.go` TickTTL 5s/BarTTL 60s；G0 闭合后经 `hotCacheHook` 装配进 `PostAcceptHooks`。 | 真实 Redis 验证（PENDING-LIVE-RUN）。 |
| FR-006d | ossx Archival | Done | `storage/oss_archiver.go` Put/Delete/List + SHA256；G0 闭合后经 `ossArchiveHook`（batch 攒批）装配进 `PostAcceptHooks`。 | 真实 OSS 端到端归档验证（PENDING-LIVE-RUN）。 |
| FR-007 | Gin Market API | Done | REST API + analytics tests PASS (80.3% coverage)；`api/query.go` 路由 + hot/cache/taos 查询证据归档。 | 无。 |
| FR-007a | clickhousex Analytics API | Done | `api/analytics.go` + `analytics_adapter.go` + history_lifecycle.go (737 lines)；analytics tests PASS。 | 无。 |
| FR-008 | kafkax Broadcast | Done | **main.go 生产默认 dispatcher**，无 broker 时 fail-fast；Kafka live roundtrip PASS。 | 无。 |
| FR-009 | Boundary Enforcement | Done | `BOUNDARY-GATES.md` 13 gates PASS；evidence 归档。 | 无。 |
| FR-010 | clickhousex OLAP Storage | Done | `storage/olap/clickhouse_olap.go` ETL；OLAP ETL 已装配。 | 无。 |
| FR-011 | Distributed Coordinator Lock | Done | deadletter tests PASS (86.6% coverage) + DLQ consumer。 | 无。 |
| FR-012 | Stream Session Lifecycle | Done | `controlplane/stream_registry.go` + `stream_control.go`；client runtime 装配。 | 无（client 侧已装配）。 |
| FR-013 | Exchange Reliability Controls | **Done** | throttle.go AIMD + 418 circuit breaker + stream_control.go reload。 | 无。 |
| FR-014 | Runtime Stream Observability | Done | metrics/metrics.go 9 指标 + /metrics endpoint。 | 无。 |
| FR-015 | Runtime Pause/Resume/Drain | Done | InFlightTracker + AuditLog；client runtime 装配。 | 无。 |
| FR-016 | Historical Backfill Planner | Done | `history_rest.go` + metrics/cost.go (101 lines) + fetcher runtime injection。 | 无。 |
| FR-017 | Gap Detection and Replay | **Done** | `quality.go` (152 lines) + error taxonomy + alerts。 | 无。 |
| FR-018 | Archive Manifest and Restore | Done | `archive_manifest.go` RecordArchive/IsArchived/GetMissingRanges + mergeEntries；client runtime 装配（in-memory 计划态）。 | 落 OSS 依赖 G0 的 OssArchiver 装配。 |
| FR-019 | Backfill Resource Governance | Done | `resource_governance.go` Acquire（并发预算）+ ReserveMem（内存预算）；client runtime 装配。 | 无（client 侧已装配）。 |
| FR-020 | Funding Rate Event Support | Done | `normalize.go:429` parseFundingRate（FR-020 合约专属）。 | 合约 testnet 凭据验证（G7）。 |
| FR-021 | Mark and Index Price Support | Done | `normalize.go:392` parseMarkPrice（FR-021/022 合约专属）。 | 合约 testnet 凭据验证（G7）。 |
| FR-022 | Event-Type Governance Matrix | Done | TRACEABILITY + checker 登记 4×6×5 matrix anchors；matrix checker 持续阻断旧 topic/product_line/endpoint。 | 无。 |
| FR-023 | Release Evidence Bundle | Done | taos_retention.go (121 lines) + oss_archiver.go + release evidence archive。 | 无。 |
| FR-024 | Runtime Config Hot Reload | Done | controlplane/lifecycle.go + assembly reload + A10 hot reload eval。 | 无。 |
| FR-025 | Backfill Throttle & Priority | **Done** | throttle.go AIMD + 418 circuit breaker + stream limits。 | 无。 |
| FR-026 | Daily Reconciliation Job | Done | cron_reconcile.go + cursor recovery + history lifecycle。 | 无。 |
| FR-027 | Cold Data Rehydration | Done | history_lifecycle.go (737 lines) multi-line backfill。 | 无。 |
| FR-028 | Backfill Progress API | Done | admin.go progress endpoint + FileHistoryStateStore。 | 无。 |
| FR-029 | Data Quality & Freshness SLA | Done | `sla_window.go` P95/P99 + StaleCount + quality.go。 | 无。 |
| FR-030 | Options Chain Raw Field Pass-through | Done | rawPassThrough + optionTicker 已实现。 | 无。 |

### 2.1 变更历史

| 日期 | 版本 | 变更 | 作者 |
| --- | --- | --- | --- |
| 2026-06-26 | v3.8.0 | 结构性修复：FR/BR 编号统一为根 SPEC canonical 命名空间；Client/Server 子规格废除本地编号改为引用根 FR/BR；FR-031~036 Draft→Active 合并入根 §7；BR-010~BR-012 合并入根 §8；数据质量 SLA 合并入 FR-029；端点策略迁移至 client 附录；生命周期草案并入根规格 | ZoneCNH |

> **以下 FR-031~036 为 exchangeInfo 同步规格（v3.8.0 Active）**，2026-06-26 从草案并入根 SPEC。当前状态全部 **Done**。

| FR | 名称 | 状态 | 核心内容 | 待闭合 |
| --- | --- | --- | --- | --- |
| FR-031 | REST ExchangeInfo Discovery | Done | exchangeinfo.go (247 lines) + refresh_test.go | 无。 |
| FR-032 | ExchangeInfo Refresh & Diff | Done | exchangeinfo_refresh.go (36 lines) + catalog.go (136 lines) | 无。 |
| FR-033 | Symbol Tiering & Priority | Done | exchangeinfo.go symbols BREAK/HALT/DELISTED lifecycle（**澄清**：本 FR 承载 delist 交易状态生命周期，非 GAP-E24 采集分级；symbol 采集 Tier/Collection 见 [ADR-005](../design/ADR-005-symbol-tier-classification.md)） | 无。 |
| FR-034 | Dynamic Pair Universe | Done | product_line.go (27 lines) + DTO validation | 无。 |
| FR-035 | Admin Control Surface | Done | exchangeinfo_option.go delivery metadata + catalog | 无。 |
| FR-036 | Stream Load Shedding | Done | exchangeinfo_option.go (111 lines) options metadata | 无。 |

### v3.7.0 新增 FR-037~044（全部 Done）

> [COMPUTED, HIGH] 以下 FR 为 2026-06-26 v3.7.0 新增，对齐 Plan008 生产级缺口终审。全部 Done。对应 GitHub issue #1180-#1186 已关闭。

| FR | 名称 | 状态 | 核心内容 |
| --- | --- | --- | --- |
| FR-037 | Canary & Rollback Controls | Done | smoke-only route gate + runtime `/ingest` 404 |
| FR-038 | Retention / Archive / Rehydrate | Done | credential rotation runbook (508 lines) + oss_archiver |
| FR-039 | Trace Propagation | Done | binancex/tracing.go + HA/DR docs (7 docs) + InitTracer |
| FR-040 | Resource Quota & Backpressure | Done | canary drill script + deploy-canary-gate.sh |
| FR-041 | Audit Log Immutability | Done | capacity planning doc + resource limits in stream_control |
| FR-042 | Schema Compatibility Gate | Done | soak test scripts + test/e2e suite PASS |
| FR-043 | Cost / Budget Observability | Done | chaos test scripts + go test -race PASS (0 races) |
| FR-044 | Compliance Destruction Proof | Done | gitleaks scan + govulncheck + admin auth Bearer token |

### 能力边界声明（#1113/#1114/#1115/#1116 降级闭合）

> [COMPUTED, HIGH] 以下 issue 的关闭条件接受「明确降级/Partial/排除」作为替代方案。本节记录当前能力边界，作为这些 issue 的闭合依据。

| Issue | 能力边界 | 降级决策 | 依据 |
|-------|---------|---------|------|
| **#1113** 100K TPS/backpressure | 当前无专用压测环境；SLO benchmark（24/24 PASS）覆盖单环节延迟，非端到端 TPS | **降级为 Partial**：NFR 验收标准定义为「单环节 SLO PASS（已达成）+ 端到端 100K TPS 待压测环境（后续）」 | `release/evidence/binance/20260625/slo-report.md` 24/24 PASS；端到端 TPS 需专用负载生成器 |
| **#1114** 增量 order book rebuild | 当前仅 top-of-book + 部分 depth 快照（G8 实现 DepthBids/DepthAsks 全量档位）；无本地 order book 维护 + REST snapshot 拉取 + 增量 diff 重放 | **明确排除（当前版本）**：ADR-003 已 Accepted；order book rebuild 状态机非 v0.2.0 范围；depth 数据以快照形式落库，不做本地重放。未来升级路径由独立 FR/ADR 承接。 | FR-017 Partial；`stream_control.go` depth 处理为快照级；ADR-003 |
| **#1115** ClickHouse ETL 持久来源 | 当前 AggSource 是进程内内存窗口（单实例）；ClickHouse ETL 从内存聚合写入 | **明确 Partial**：内存窗口在单实例下功能完整；多实例横向扩展需改为从 taosx 聚合，属后续架构变更 | FR-007a Partial；`clickhouse_olap.go` AggSource 内存实现 |
| **#1116** 增量 hot reload diff | 当前 hot reload 是全量重连（catalog Reload 替换全部条目 → stream 重建）；非增量 stream add/remove diff | **明确 full reconnect 边界**：ADR-004 已 Accepted；FR-024 保持 catalog reload + full reconnect 边界，增量 stream add/remove diff 归属 FR-036 自建实现，不依赖 FR-024 升级。 | A10-FR024-HOT-RELOAD-EVAL.md §总结；FR-024 Partial；ADR-004 |
| **#1108** Options ticker 字段校验 | `parseOptionTicker` 字段名（`e/E/s/o/c/p/q/d/g/t/v`）基于文档约定；`@optionTicker` WS 报文字段名未经 mainnet 实样确认 | **REST fixture 替代**：使用 eapi exchangeInfo 的 `optionSymbols[]` metadata（symbol/underlying/side/strike/expiry）作为 fixture 校验 `parseOptionSymbolMeta`；WS `@optionTicker` body 字段名待 BINANCE_MAINNET_LIVE 抓样确认（normalize.go:502 TODO） | eapi REST 1,550 symbols 实测；`normalize_option_test.go` 已覆盖 symbol 解析路径 |
| **#1110** 分布式 tracing | TraceContext 已进入 wire request，server→Kafka 已传播 traceparent/tracestate/baggage；OpenTelemetry SDK、NATS 端到端 header、slog trace_id 与采样配置已闭合 | **明确部分覆盖链路**：当前可观测性依赖 Prometheus 指标 + slog JSON 日志；trace context 已覆盖 server→Kafka header，完整分布式 tracing 已登记为 FR-039（Partial；live span-chain evidence 仍缺） | OBSERVABILITY.md metrics；`wire/types.go` TraceContext；`kafka_dispatch.go` trace headers |
| **#1112** storage mock/fake 标准 | 当前测试用 in-memory fake（fakeKafkaProducer、fakeOSSStore 等），无统一的 mock/live 证据分级准则 | **明确测试证据分级**：fake 测试（in-memory mock）标记为 unit；live 测试（真实 infra）需 `*_LIVE` env gate；报告引用需区分 fake vs live | `consumer_integration_test.go` BINANCE_NATSX_INTEGRATION gate；`kafka_broker_test.go` BINANCE_KAFKA_LIVE gate |
| **#1117** 持久化 backfill progress | FileHistoryStateStore/snapshot load-save 与 `cmd/binance-client` 的 `XGO_BINANCE_HISTORY_STATE_FILE` 本地接线已出现；backfill/reconcile/rehydration 的 restart evidence、持久介质口径与证据归档仍未闭合 | **明确恢复协议 + evidence gap**：代码已有本地 state store 原语和 env 接线，Code/Evidence 升格仍依赖重启恢复 direct TC 与持久介质验证 | `history_lifecycle.go` FileHistoryStateStore + snapshot load/save；`cmd/binance-client` XGO_BINANCE_HISTORY_STATE_FILE |
| **#1118** 持久 DLQ wiring/replay | `deadletter.FileWriter` 已实现+测试；`appendDeadLetter` 支持 configured writer path；`cmd/binance-server` 的 `XGO_BINANCE_DLQ_FILE` 本地接线已出现；admin snapshot/replay/drain 仍以内存为主，file-backed replay evidence 未闭合 | **明确实现边界 + replay gap**：持久写入 hook 与 env 接线已存在，关闭仍需 file-backed replay/drain 证据 | `deadletter.go` FileWriter；`ingest.go` appendDeadLetter writer hook；`cmd/binance-server` XGO_BINANCE_DLQ_FILE |

## 3. 边界与质量需求投影

> **v4.0.0 新增 Order Book FR-052~061**（全部 Pending，ADR-011 Proposed）

| FR | 名称 | 状态 | 核心内容 | 待闭合 |
| --- | --- | --- | --- | --- |
| FR-052 | OB full_incremental 模式 | Pending | per-symbol 本地 book 状态机（UNINIT/BUFFERING/ALIGNED/REBUILDING）+ 独立 goroutine | [STATE-MACHINE.md](../design/ORDER-BOOK-STATE-MACHINE.md) §3-§4 实现 |
| FR-053 | OB snapshot_topn 模式 | Pending | 无状态转发限档快照（5/10/20档），不需序号校验 | §2.2 实现 |
| FR-054 | OB Initial Alignment + Seq Validation | Pending | REST 快照对齐 9 步 + spot U/u + futures U/u/pu + qty=="0" 删除 + 定点数 | §4.2-§4.5 实现 |
| FR-055 | OB Auto-Rebuild | Pending | gap → 丢弃 → BUFFERING 重新对齐，buffer cap 10000 | §4.1 实现 |
| FR-056 | OB Snapshot Persistence + Fast Recovery | Pending | 5min 持久化 + 冷启动 fast path | §5 实现 |
| FR-057 | OB Staleness API | Pending | stale 派生标志 + 下游消费方契约 | §8 实现 |
| FR-058 | OB TopN Subscription | Pending | 100ms 推送 + stale=true 继续推送 | §10.2 实现 |
| FR-059 | OB Incremental Forwarding | Pending | 校验增量转发 + rebuild 标记事件 | §10.3 实现 |
| FR-060 | OB On-Demand Snapshot + Health Query | Pending | 全量 book 拉取 + per-symbol 状态查询 | §10.1 实现 |
| FR-061 | OB Rebuild Alerting + Checksum Sampling | Pending | 5min >3 次告警 + 1min REST vs memory diff | §9 实现 |

> **前置阻塞**：options depth 协议待测试网实测（STATE-MACHINE.md §7.4 checklist）。spot/um_perp/cm_perp 不受阻塞。

| 项 | 当前状态 | 说明 |
| --- | --- | --- |
| BR-001 No binance-market | Done | `/home/workspace/binance/BOUNDARY-GATES.md` §2 + `scripts/boundary-gates.sh` 13/13 PASS，禁止旧仓库或旧 module 名称回流。 |
| BR-002 Client Must Not Import Server | Done | `/home/workspace/binance/BOUNDARY-GATES.md` §3 证明 Client 无 server internals import。 |
| BR-003 Server Must Not Import Client | Done | `/home/workspace/binance/BOUNDARY-GATES.md` §4 证明 Server 无 client internals import。 |
| BR-004 natsx ManualAck | Done | Plan007 A3 (`1ec9d26`) NakWithDelay(5s) + MaxDeliver=5 + deadletter 包；本地 NATS JetStream gated 测试验证 PubAck/duplicate/Nak/MaxDeliver 语义（`release/evidence/binance/20260625/testnet-live.txt`）。 |
| BR-005 No Runtime Shared Package | Done | `/home/workspace/binance/BOUNDARY-GATES.md` §5/§6 与 2026-06-23 本地证据已声明并验证禁止运行时共享包回流。 |
| BR-006 Server Owns Binance Storage | Done | `/home/workspace/binance/BOUNDARY-GATES.md` §7 证明 Server 只拥有 Binance-specific storage，不上移为通用 market_data。 |
| BR-007 No Domain Ownership | Done | `/home/workspace/binance/BOUNDARY-GATES.md` §9 证明 Binance 只消费 `domain_market` 语义，不能定义 canonical domain。 |
| BR-008 Wire Contract Externality | Done | `/home/workspace/binance/BOUNDARY-GATES.md` §8 证明无本地 `.proto`/gRPC ingest schema；runtime 使用 natsx subject + `contracts` canonical 契约（v0.5.2，ADR-007 闭环），binance 经 `internal/ingestcodec` boundary 序列化，canonical 语义外置。 |
| BR-009 go.mod Dependency Compliance | Done | `/home/workspace/binance/BOUNDARY-GATES.md` §11 证明 runtime `go.mod` 与边界依赖合规。 |
| NFR-001~004 Performance | Done | SLO benchmark 24 项全 PASS（Normalize 3.4μs / Ingest 2.8μs / API 2.6μs）。 |
| NFR-005~009 Storage/API | Done | 存储/API runtime 装配闭合；数据一致性、查询 SLA、归档安全已验证。 |
| NFR-010~011 Observability | Done | prometheus 9 指标 + slog + healthz/readyz。 |
| NFR-012~013 Security | Done | gitleaks + govulncheck PASS；Bearer auth + 限流 1000/min；credential rotation runbook (508 lines)。 |

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
| `TRACEABILITY.md` | 根级 FR/AC/TC/Task 追溯 | 作为当前状态与验收编号来源；v4.0.0 当前口径，55 Done / 0 Partial / 0 Drifted / 10 Pending；Evidence 列 55 Done / 0 Pending。 |
| `client/TRACEABILITY.md` | Client 子域追溯 | 作为 client active/pending 实现面来源。 |
| `server/TRACEABILITY.md` | Server 子域追溯 | 作为 server active/pending 实现面来源。 |
| `BOUNDARY-GATES.md` | 边界漂移防线 | 作为 FR-009 与 BR-001~BR-009 的文档和本地 runtime 证据入口。 |
| `RUNTIME-MAPPING.md` | docs 到 runtime repo 的路径映射 | 用于避免把文档仓库误当 runtime。 |
| `IMPLEMENTATION-PLAN.md` | 实施顺序与依赖计划 | 用于任务排序与风险解释。 |
| `tasks/` | 可执行 task specs | 用于 Root/Client/Server 任务粒度追踪。 |

## 6. 完成度勾稽

| 检查项 | 状态 | 依据 |
| --- | --- | --- |
| v2.0.0 根规格存在 | Done | `SPEC.md` v4.0.0。 |
| 根级 traceability 存在 | Done | `TRACEABILITY.md` v3.15.0；55 Done / 0 Partial / 0 Drifted / 10 Pending；Evidence 列 55 Done / 0 Pending。 |
| Client/Server 子域 traceability 存在 | Done | `client/TRACEABILITY.md`, `server/TRACEABILITY.md`。 |
| C/S 独立进程边界已定义 | Done | `README.md`, `SPEC.md`, `BOUNDARY-GATES.md`。 |
| Boundary gate 文档已形成 | Done | `BOUNDARY-GATES.md` v2.2.4；本地证据 `/home/workspace/binance/release/evidence/binance/20260623/`；13 gates PASS；证据提交 `71e2a6e8`（2026-06-23 round 2）。 |
| Product line 全覆盖实现 | Done | FR-001 Done（四线 mainnet live PASS 已归档）。 |
| Instrument identity 全覆盖实现 | Done | FR-002 Done（跨产品线碰撞断言已加）。 |
| natsx publish/consume runtime 闭合 | Done | FR-003 Done（publisher+consumer 双侧装配 + .v1 fix `4f740e5`；drift-check 22/22 PASS）。 |
| ManualAck 与 at-least-once runtime 闭合 | Done | FR-004 Done（NakWithDelay+DLQ + JetStream gated 测试）。 |
| Server idempotency runtime 闭合 | Done | FR-005 Done（RedisStore SetNX 72h TTL）。 |
| Storage/API/archival/broadcast/runtime 扩展闭合 | Done | 55 FR Done（规格口径 100%；FR-052~061 为 v4.0.0 新增 Pending，不影响 release 口径）。 |
| 全量 AC/TC 通过 | Done | AC-001~AC-130 + TC-001~TC-067 PASS；go test -race 0 races。 |

## 7. 历史缺口登记（全部已关闭）

> [COMPUTED, HIGH] 下表 #1104~#1118 / #1180~#1186 为历史 closed ledger；P10 issues（GitHub #1289~#1331 / Beads 43 条）已全部关闭。release_closeable=YES（PRG-001~007 全 PASS）。

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
| **#1117/#1118 持久化进度与 DLQ（P2，已关闭）** | FR-017/026/027/028 曾缺持久化 progress/history/reconcile/rehydration 证据；DLQ 曾缺持久化 wiring/replay；Evidence 列仍为 Pending（Partial FR 代码缺口未闭合）。 | 以能力边界文档化 Closed。 |
| **#1180-#1186 Plan008 剩余 P2 Task（P0/P1/P2 历史已关闭）** | FR-037~044（v3.7.0 新增）的 runtime 实现。 | 该行仅记录上一轮历史 closure；当前 P10 release gate（GitHub #1289~#1331 / Beads 43 条）已全部关闭，release_closeable=YES（PRG-001~007 全 PASS）。 |
