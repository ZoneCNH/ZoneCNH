# binance 完整实现清单

## 元数据

| 字段 | 值 |
| --- | --- |
| Status | Generated from current module SSOT |
| Last-Updated | 2026-06-25 |
| Module-Version | v3.5.2 |
| Module-State | 规格扩展到 v3.5.2；FR 状态对齐 runtime HEAD `e02b190`（Plan007 A1~A10 + B1~B8 已执行），刷新为 **19 Done / 11 Partial / 0 Pending**（main.go 装配级证据标准）；6 FR 上调（FR-002/004/008/025/030 + FR-016 实质升级），9 存储类 FR 下调（FR-005/006a-d/007/007a/010/011 code-complete 但 main.go 未装配实例）；以 `/home/binance` runtime/release evidence 为准 |
| Layer | 数据域 / Binance-specific market_data C/S module |
| Runtime-Repo | `/home/binance` |
| Source | `goal.md`, `SPEC.md`, `TRACEABILITY.md`, `DATA-LIFECYCLE.md`, `STANDARD.md`, `BOUNDARY-GATES.md`, `RUNTIME-MAPPING.md`, `IMPLEMENTATION-PLAN.md`, `client/`, `server/`, `tasks/` |

本文档是 `module/binance` 当前规格库的实现投影，不是 runtime 代码验收证据。实际完成状态以 `TRACEABILITY.md`、`client/TRACEABILITY.md`、`server/TRACEABILITY.md` 和 `/home/binance` 的测试证据为准。

> **v3.5.2 状态口径（2026-06-25）**：Done = writer/代码存在 **且** `cmd/binance-server/main.go` 装配真实实例；Partial = 代码完整但 main.go 未装配（存储装配断层，根因见 [`docs/report/binance/production-readiness-assessment-20260625.md`](../../docs/report/binance/production-readiness-assessment-20260625.md) §4.1 G0）或 runtime 未注入 / 集成验证缺。L1 边界治理（FR-009/BR）不可替代 L2 功能验收。

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

> 状态口径 L1/L2 分层（RULES R4）+ main.go 装配级证据标准（v3.5.2）：`Done`=代码存在 **且** `cmd/binance-server/main.go` 装配真实实例（L1 边界治理 FR-009/BR 需 boundary-gate + runtime SHA）；`Partial`=代码完整但 main.go 未装配（存储装配断层，runtime 永不执行）或 runtime 未注入 / 集成验证缺；`Pending`=仅规格登记。L1 不可替代 L2 功能验收。

| FR | 功能 | 当前状态 | 已有证据 | 剩余实现面 |
| --- | --- | --- | --- | --- |
| FR-001 | Product-Line Support | Done | 四产品线 connector 实现齐全（`connectors/{spot,um_perp,cm_perp,options}.go` + 共享 `NewProductLineConnector`）；runtime 仅装配 spot，um/cm/options 需 testnet 凭据验证（G7）。 | 合约/期权 testnet 凭据 + 产品线差异测试。 |
| FR-002 | Instrument Identity | Done | Plan007 A4 (`f9c2c01`) 跨产品线碰撞断言 `TestNewInstrumentKey_CrossProductLine_NoCollision`；InstrumentKey 含 exchange/product_line/symbol 维度。 | 合约/期权 normalize 分发层差异测试（identity 层已闭合）。 |
| FR-003 | natsx Communication | Done | publisher (`publisher.go:56`) + consumer (`consumer.go:141`) 双侧装配；subject `binance.market.{pl}.{et}`；JetStream PubAck testnet live 验证。 | 无（testnet live 已验证）。 |
| FR-004 | At-Least-Once Delivery | Done | Plan007 A3 (`1ec9d26`) NakWithDelay(5s) + MaxDeliver=5 + deadletter 包；本地 NATS JetStream gated 测试验证 PubAck/duplicate/Nak/MaxDeliver 语义。 | deadletter 为 in-memory（非持久化 DLQ），生产持久化 DLQ 可作后续增强。 |
| FR-005 | Idempotent Acceptance | Partial | `idempotency/redis_store.go` SetNX 72h TTL 代码完整；**main.go:134 用 `NewMemoryIdempotencyStore`（非 RedisStore）**，runtime 退化为内存幂等。 | main.go 装配 RedisStore 实例（G0 存储装配断层）。 |
| FR-006a | taosx Time-Series Storage | Partial | `storage/taos_writer.go` WriteBatch 代码完整；**main.go `StorageWriter=nil`，`persist()` 静默跳过**，runtime 永不落盘。 | main.go 装配 TaosWriter 实例 + 端到端落盘验证（G0）。 |
| FR-006b | postgresx Metadata Storage | Partial | `storage/pg_catalog.go` UpsertSymbol ON CONFLICT 代码完整；**main.go `PostAcceptHooks=nil`**，runtime 永不执行。 | main.go 装配 PGCatalog 实例（G0）。 |
| FR-006c | redisx Hot Cache | Partial | `cache/hot_cache.go` TickTTL 5s/BarTTL 60s 代码完整；**main.go 未注入**，runtime 永不刷新。 | main.go 装配 HotCache 实例（G0）。 |
| FR-006d | ossx Archival | Partial | `storage/oss_archiver.go` Put/Delete/List + SHA256 校验代码完整；**main.go 未引用 NewOssArchiver**，runtime 永不归档。 | main.go 装配 OssArchiver 实例（G0）。 |
| FR-007 | Gin Market API | Partial | `api/query.go` 路由完整（Bearer auth + 限流 1000/min）；**main.go `EnableMarketAPI` 未设，路由不挂载，后端数据源全 nil**。 | main.go 挂载 Market API 路由 + 注入数据源（G0）。 |
| FR-007a | clickhousex Analytics API | Partial | `api/analytics.go` + `analytics_adapter.go` 代码完整；**main.go 未装配**，runtime 永不执行。 | main.go 装配 ClickHouse + analytics adapter（G0）。 |
| FR-008 | kafkax Broadcast | Done | **main.go 生产默认 dispatcher（`dispatcherModeFromEnv` 默认 kafkax）**，无 broker 时 fail-fast；`NewKafkaDispatchAdapter` 真实 producer.Send。 | 真实 Kafka broker e2e、production topic/ACL（G2 部分）。 |
| FR-009 | Boundary Enforcement | Done | `BOUNDARY-GATES.md` 13 gates PASS；`/home/binance/release/evidence/binance/20260623/` 归档；证据提交 `71e2a6e8`。 | 远端 CI/release evidence 归档；非边界 FR 不因此闭合。 |
| FR-010 | clickhousex OLAP Storage | Partial | `storage/olap/clickhouse_olap.go` ETL (RunOnce/Run ticker 调度) 代码完整；**main.go 未装配 olap.NewETL**，runtime 无调度入口。 | main.go 装配 OLAP ETL + 调度验证（G0）。 |
| FR-011 | Distributed Coordinator Lock | Partial | `cache/dist_lock.go` SetNX + 续期 + Release 代码完整；**main.go 未引用 CoordinatorLock**，runtime 永不执行。 | main.go 装配 CoordinatorLock 实例（G0）。 |
| FR-012 | Stream Session Lifecycle | Done | `controlplane/stream_registry.go` + `stream_control.go`；client runtime 装配。 | 无（client 侧已装配）。 |
| FR-013 | Exchange Reliability Controls | Done | `controlplane/reliability.go` RetryBudget + WeightGate + ClockSkew；client runtime 装配。 | 无（client 侧已装配）。 |
| FR-014 | Runtime Stream Observability | Done | `controlplane/stream_registry.go` + `metrics/metrics.go` 9 指标 prometheus；client runtime 装配。 | SLA 仪表盘文档化（P2 建议）。 |
| FR-015 | Runtime Pause/Resume/Drain | Done | `controlplane/lifecycle.go` InFlightTracker + AuditLog；client runtime 装配。 | 无（client 侧已装配）。 |
| FR-016 | Historical Backfill Planner | Partial | Plan007 A1 (`9d95f84`) `history_rest.go` 真实 Binance REST klines/aggTrades（含 weight 限流/分页/重试）替换 stub；**`runtime.go:102` 用 `DefaultHistoryRuntimeConfig()` 未注入 ExchangeHistoryFetcher**。 | main.go/runtime 注入 ExchangeHistoryFetcher + spotBaseURL 配置（G0 关联）。 |
| FR-017 | Gap Detection and Replay | Done | `quality.go` newQualityTracker + gap 检测（MaxEventGap 2min）+ Prometheus IncGapDetected；接入 ingest.observe。 | 无。 |
| FR-018 | Archive Manifest and Restore | Done | `archive_manifest.go` RecordArchive/IsArchived/GetMissingRanges + mergeEntries；client runtime 装配（in-memory 计划态）。 | 落 OSS 依赖 G0 的 OssArchiver 装配。 |
| FR-019 | Backfill Resource Governance | Done | `resource_governance.go` Acquire（并发预算）+ ReserveMem（内存预算）；client runtime 装配。 | 无（client 侧已装配）。 |
| FR-020 | Funding Rate Event Support | Done | `normalize.go:429` parseFundingRate（FR-020 合约专属）。 | 合约 testnet 凭据验证（G7）。 |
| FR-021 | Mark and Index Price Support | Done | `normalize.go:392` parseMarkPrice（FR-021/022 合约专属）。 | 合约 testnet 凭据验证（G7）。 |
| FR-022 | Event-Type Governance Matrix | Done | TRACEABILITY + checker 登记 4×6×5 matrix anchors；matrix checker 持续阻断旧 topic/product_line/endpoint。 | 无。 |
| FR-023 | Release Evidence Bundle | Partial | `scripts/runtime-release-evidence.sh` + `release/evidence/binance/{20260622,20260623,20260625}/`；20260625 含 testnet live + SLO。 | 远程 CI/release tag 产物验证（G5 部分）。 |
| FR-024 | Runtime Config Hot Reload | Partial | `admin.go` `/api/v1/admin/symbols/reload` + `stream_control.go` Refresh；**全量重连非增量 stream diff**。 | 增量 stream add/remove（非全量重连）+ live websocket 证据。 |
| FR-025 | Backfill Throttle & Priority | Done | `throttle.go` 80/20 split（cold_start 80% / repair 20%）+ 滑动窗口；client runtime 装配。 | 无（client 侧已装配）。 |
| FR-026 | Daily Reconciliation Job | Done | `cron_reconcile.go` Start goroutine + nextTrigger 04:00 UTC + runReconciliation；client runtime 装配。 | 真实对账依赖 G0 的存储装配。 |
| FR-027 | Cold Data Rehydration | Partial | `oss_rehydrate.go` Rehydrate（List→过滤→Get→decode NDJSON→writer.Write）代码真实；**main.go 未装配 + 依赖 nil writer**。 | main.go 装配 OssArchiver + StorageWriter（G0）。 |
| FR-028 | Backfill Progress API | Partial | `admin.go:106` `/api/v1/admin/backfill/progress` 端点存在；**数据来自 in-memory historyRuntime**，非持久化。 | 持久化 progress 存储（依赖 G0）。 |
| FR-029 | Data Quality & Freshness SLA | Done | `sla_window.go` P95/P99 + StaleCount；接入 quality.go + admin 暴露 freshness_millis。 | stale alert 阈值文档化（P2 建议）。 |
| FR-030 | Options Chain Raw Field Pass-through | Done | Plan007 A7 (`b82d5b1`) `normalize.go:463` rawPassThrough 兜底 + ticker 流支持；EventType fallback tick。 | options testnet 凭据 + Greeks 边界测试（G7）。 |

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
| `TRACEABILITY.md` | 根级 FR/AC/TC/Task 追溯 | 作为当前状态与验收编号来源。 |
| `client/TRACEABILITY.md` | Client 子域追溯 | 作为 client active/pending 实现面来源。 |
| `server/TRACEABILITY.md` | Server 子域追溯 | 作为 server active/pending 实现面来源。 |
| `BOUNDARY-GATES.md` | 边界漂移防线 | 作为 FR-009 与 BR-001~BR-009 的文档和本地 runtime 证据入口。 |
| `RUNTIME-MAPPING.md` | docs 到 runtime repo 的路径映射 | 用于避免把文档仓库误当 runtime。 |
| `IMPLEMENTATION-PLAN.md` | 实施顺序与依赖计划 | 用于任务排序与风险解释。 |
| `tasks/` | 可执行 task specs | 用于 Root/Client/Server 任务粒度追踪。 |

## 6. 完成度勾稽

| 检查项 | 状态 | 依据 |
| --- | --- | --- |
| v2.0.0 根规格存在 | Done | `SPEC.md` v3.5.2。 |
| 根级 traceability 存在 | Done | `TRACEABILITY.md` v3.5.2。 |
| Client/Server 子域 traceability 存在 | Done | `client/TRACEABILITY.md`, `server/TRACEABILITY.md`。 |
| C/S 独立进程边界已定义 | Done | `README.md`, `SPEC.md`, `BOUNDARY-GATES.md`。 |
| Boundary gate 文档已形成 | Done | `BOUNDARY-GATES.md` v2.2.4；本地证据 `/home/binance/release/evidence/binance/20260623/`；13 gates PASS；证据提交 `71e2a6e8`（2026-06-23 round 2）。 |
| Product line 全覆盖实现 | Partial | FR-001 Done（四线 connector 实现齐全）；runtime 仅装配 spot，um/cm/options 需 testnet 凭据（G7）。 |
| Instrument identity 全覆盖实现 | Done | FR-002 Done（Plan007 A4 跨产品线碰撞断言已加）。 |
| natsx publish/consume runtime 闭合 | Done | FR-003 Done（publisher+consumer 双侧装配 + testnet live 验证）。 |
| ManualAck 与 at-least-once runtime 闭合 | Done | FR-004 Done（Plan007 A3 NakWithDelay+DLQ + JetStream gated 测试）。 |
| Server idempotency runtime 闭合 | Partial | FR-005 Partial（redis_store 代码完整，main 用 MemoryIdempotencyStore，G0）。 |
| Storage/API/archival/broadcast/runtime 扩展闭合 | Partial | FR-008 Done（kafkax 生产默认）；FR-006a-d/007/007a/010/011 Partial（G0 存储装配断层）；FR-012~015/017~022/025/026/029/030 Done；FR-016/023/024/027/028 Partial。 |
| 全量 AC/TC 通过 | Not Done | Boundary gates 13/13 PASS；TC-020~TC-022 local PASS；多数 TC 仍 Pending 真实外部集成证据（G2/G7）与 G0 存储装配。 |

## 7. 当前缺口登记

| 缺口 | 影响 | 关闭条件 |
| --- | --- | --- |
| **G0 存储装配断层（P0，阻断发布）** | 9 个存储类 FR（FR-005/006a-d/007/007a/010/011）代码完整但 `cmd/binance-server/main.go` 未装配实例，runtime 永不落盘/缓存/归档/OLAP。消息经 NATS→consumer→kafkax fanout 后即丢弃，查询 API/OLAP/归档无数据。 | main.go 新增 `storageFromEnv` 装配 taosx/pg/redis/ch/oss 实例 + 注入 serverConfig + 端到端落盘验证。详见 `docs/report/binance/production-readiness-assessment-20260625.md` §4.1。 |
| **G2 真实外部集成证据（P0）** | 合约/期权 testnet 凭据、真实 Kafka broker e2e、远程 CI 证据缺失。 | 申请 Binance 合约/期权 testnet 凭据 + 扩展 testnet_live_test + 真实 Kafka broker 集成测试。 |
| **G5 Release artifact（P1）** | release.yml 存在但 v0.1.0/v0.1.1 tag 是否真有 GitHub Release 产物未验证。 | 触发 release.yml + 验证 GitHub Release artifact。 |
| **G7 合约/期权产品线实质化（P1）** | um/cm/options 共享 spot engine，合约专属事件解析（markPrice/fundingRate）已有但未验证；options rawPassThrough 兜底但 Greeks 边界未测。 | 合约/期权 testnet 凭据 + 产品线差异测试（同 symbol 跨线 normalize/identity 断言）。 |
| **G8 订单簿 diff/snapshot 重建（P1）** | 仅 top-of-book（top bid/ask），无增量 depth 维护与全量快照重建。 | 本地 ordered book + REST snapshot 拉取 + 增量重放。 |
| FR-016 runtime 未注入 fetcher | Plan007 A1 真实 REST 已替换 stub，但 `runtime.go:102` 用 DefaultHistoryRuntimeConfig 未注入 ExchangeHistoryFetcher。 | runtime 注入 ExchangeHistoryFetcher + spotBaseURL 配置。 |
| FR-024 全量重连非增量 diff | hot reload 存在但为全量重连，非真正的增量 stream add/remove。 | 增量 stream diff 实现 + live websocket 证据。 |
| FR-023 远程 CI/release evidence | release evidence 本地归档完整，远程 CI/tag 产物未验证。 | 远程 CI run + release tag snapshot 归档。 |
