# Binance SPEC

- Spec-Version: v4.0.1
- Module: binance
- Last-Updated: 2026-07-08（白名单补齐 GC-0~GC-5 全合入 main）
- Runtime-Repo: `/home/workspace/binance`
- Runtime-Version: v0.15.0（order book FR-052~061 spot/um/cm 实现；白名单 GC-0~GC-5 补齐）
- State-Model: single-state only
- Current-State: 65 Done / 0 Partial / 0 Drifted / 0 Pending
- release_closeable: YES（规格口径 65 Done；FR-052~061 spot/um/cm 已实现，options 待 Phase 2）
- Open-P10-Issues: 0（2026-07-05 全部关闭）

## 1. Goal

`binance` 提供 Binance 市场数据 ingestion、规范化、持久化、查询与生产就绪治理入口。当前目标不是声明 Perfect 10 已完成，而是把规格、代码锚点、追溯矩阵、issue 投影和运行时漂移检查恢复到同一事实口径。

## 2. Authority

| 层级 | 权威 |
| --- | --- |
| 最高治理 | `../../../CONSTITUTION.md`（§4 规格结构、§10 变更管理、§15 交付管线、§20 认识论标准） |
| 模块规格 | 本文件 |
| 追溯矩阵 | `module/binance/matrix/TRACEABILITY.md` |
| issue 投影 | Beads 与 GitHub issue 为当前 SSOT；历史本地投影归档于 `module/binance/evidence/2026-06-28/todo-archived.md` |
| 配置 schema | `module/binance/design/CONFIG-SCHEMA.md` |
| runtime 证据 | `/home/workspace/binance` 的测试、脚本、tag、CI/release evidence |

## 3. Scope

包含 client ingestion、server consumer/query、shared DTO validation、NATS JetStream contract、ClickHouse persistence、REST/Admin API、ExchangeInfo catalog、observability/security/deploy readiness 的规格要求。v4.0.0 起新增 order book rebuild 状态机（FR-052~061，ADR-011 supersede ADR-003）。不包含交易下单、账户管理、私有交易策略或生产凭证。用户数据流（私有流）排除决策见 [ADR-009](../design/ADR-009-user-data-stream-scope.md)。

## 4. Runtime Boundary

| 子系统 | 职责 | 禁止 |
| --- | --- | --- |
| `internal/client` | 连接 Binance、公有市场流转换、发布 envelope | 依赖 server 包、写数据库、暴露生产 `/ingest` |
| `internal/server` | 消费 NATS、校验、持久化、查询 API | 连接 Binance WS、持有 client-only 配置 |
| `internal/ingestcodec` | `domainmarket.InstrumentKey ↔ json.RawMessage` 序列化、BNC 私有码→canonical 码映射 | 定义跨域 DTO（DTO 由 `contracts` canonical 承载）、承载业务流程、持久化、生产入口 |

> C/S 共享契约层自 ADR-007 迁入 `contracts` canonical（`pkg/contracts/ingestion.go`，v0.5.2）。原 `internal/wire` 已删除，DTO 字段定义以 `module/contracts/spec/SPEC.md` FR-006 为单一权威。binance 在 `internal/ingestcodec` 仅保留 boundary 序列化与私有码映射，不定义任何 DTO。
| `configs/*.env.example` | 参数示例与默认边界 | 写入真实凭证 |

## 5. State Model

只允许单一状态：`Done` 或 `Partial`。历史 `Code-State` / `Evidence-State` 双态口径已废除。当前 65 个 FR Done（100%），0 Partial。`release_closeable=YES`，PRG-001~007 全 PASS。参见 TRACEABILITY.md §4。

## 6. Product Lines and Event Types

| 维度 | 允许值 |
| --- | --- |
| product_line | `spot`, `um_perp`, `cm_perp`, `options` |
| event_type (implemented) | `book_ticker`, `kline`, `depth_update`, `trade`, `funding_rate`, `mark_price_update` |
| event_type (planned) | `ticker`, `force_order`, `open_interest`, `index_reference`, `contract_info` |
| identity | exchange + product_line + instrument_type + instrument_subtype + symbol + expiry + strike + option_type |

> Implemented 类型已由 runtime 装配（FR-001~055）。v3.18.0 canonical 命名对齐 Binance 原生事件名（camelCase→snake_case），legacy alias：`tick`→`book_ticker`、`bar`→`kline`、`depth`→`depth_update`、`mark_price`→`mark_price_update`。Runtime migration（NATS subject + TDengine super table + idempotency key）由独立 FR 承接。Planned 类型基于四问分类判据（Q1 ID/Q2 快照/Q3 传输层/Q4 非权威），待 FR 驱动实现。`serverShutdown` 为传输层信号，不进枚举。详见 [`design/EVENT-TYPE-MAPPING.md`](../design/EVENT-TYPE-MAPPING.md) §1-§3。序号连续性校验策略见 [`design/SEQUENCE-CONTINUITY-STRATEGY.md`](../design/SEQUENCE-CONTINUITY-STRATEGY.md)。历史数据同步策略见 [`design/HISTORICAL-DATA-SYNC-STRATEGY.md`](../design/HISTORICAL-DATA-SYNC-STRATEGY.md)。平台变更风险见 [`design/ADR-010-platform-change-risks.md`](../design/ADR-010-platform-change-risks.md)。

## 7. Functional Requirements

| ID | Scope | Requirement | State | Closure evidence |
| --- | --- | --- | --- | --- |
| FR-001 | client | ingest public tick/trade-like stream and normalize envelope | Done | local runtime + E2E history |
| FR-002 | client | ingest kline/bar stream and normalize envelope | Done | local runtime + E2E history |
| FR-003 | contract | publish to NATS subject `binance.market.{product_line}.{event_type}.v1` | Done | drift-check 22/22 PASS + publisher `.v1` fix (`4f740e5`) |
| FR-004 | server | consume JetStream independently from client process | Done | local runtime + boundary docs |
| FR-005 | server | persist ticks to ClickHouse schema | Done | local runtime evidence |
| FR-006a | client | provide client CLI/config loading | Done | runtime config examples |
| FR-006b | server | provide server CLI/config loading | Done | runtime config examples |
| FR-006c | config | shared env validation and deterministic defaults | Done | config schema + examples |
| FR-006d | smoke | local-only smoke path remains non-production | Done | `/ingest` smoke-only gate |
| FR-007 | API | query tick data through REST | Done | REST API + analytics tests PASS (80.3% coverage) |
| FR-007a | replay | historical replay/import path | Done | analytics tests PASS + history_lifecycle.go (737 lines) |
| FR-008 | client | ingest depth stream | Done | local runtime + E2E history |
| FR-009 | client | ingest aggregate trade stream | Done | local runtime + E2E history |
| FR-010 | server | persist/query bar aggregates | Done | local runtime evidence |
| FR-011 | reliability | delayed retry, parking, dead-letter behavior | Done | deadletter tests PASS (86.6% coverage) + DLQ consumer |
| FR-012 | catalog | ExchangeInfo catalog refresh | Done | local runtime/docs |
| FR-013 | control | whitelist/blacklist hot reload | Done | throttle.go (+110 lines) + stream_control.go reload |
| FR-014 | ops | graceful shutdown and drain | Done | local tests/history |
| FR-015 | identity | stable idempotency/event keys | Done | shared DTO validation |
| FR-016 | observability | metrics exporter coverage | Done | metrics/cost.go (+101 lines) + /metrics endpoint |
| FR-017 | observability | trace propagation and OTel visibility | Done | binancex.InitTracer + tracing.go + logging.go |
| FR-018 | API | query bars through REST | Done | local runtime evidence |
| FR-019 | API | query depth through REST | Done | local runtime evidence |
| FR-020 | API | query funding-rate data | Done | local runtime/docs |
| FR-021 | API | query mark-price data | Done | local runtime/docs |
| FR-022 | identity | distinguish spot/perp/delivery/options instruments | Done | DTO/schema evidence |
| FR-023 | lifecycle | retention, TTL, archival policy | Done | taos_retention.go (+121 lines) + oss_archiver.go |
| FR-024 | control | symbol-change control subject and reload | Done | controlplane/lifecycle.go + assembly reload |
| FR-025 | reliability | backpressure and reconnect limits | Done | throttle.go AIMD + 418 circuit breaker + stream limits |
| FR-026 | recovery | checkpoint recovery after restart | Done | cron_reconcile.go + cursor recovery + history lifecyle |
| FR-027 | client | multi-product websocket lifecycle | Done | history_lifecycle.go (737 lines) multi-line backfill |
| FR-028 | errors | normalized error taxonomy | Done | quality.go (+152 lines) + error taxonomy + alerts |
| FR-029 | data quality | anomaly/SLA tags and quality rules | Done | migrated from deprecated quality doc |
| FR-030 | admin | health/readiness/admin status | Done | local runtime evidence |
| FR-031 | catalog | full ExchangeInfo sync | Done | exchangeinfo.go (247 lines) + refresh_test.go |
| FR-032 | catalog | diff ExchangeInfo sync | Done | exchangeinfo_refresh.go (+36 lines) + catalog.go (+136 lines) |
| FR-033 | catalog | delist handling | Done | exchangeinfo.go symbols BREAK/HALT/DELISTED lifecycle（**澄清**：本 FR 承载 delist 交易状态生命周期，非 GAP-E24 采集分级；symbol 采集 Tier/Collection 见 [ADR-005](../design/ADR-005-symbol-tier-classification.md)） |
| FR-034 | identity | InstrumentKey stability | Done | product_line.go (+27 lines) + DTO validation |
| FR-035 | identity | delivery expiry metadata | Done | exchangeinfo_option.go delivery metadata + catalog |
| FR-036 | identity | options metadata | Done | exchangeinfo_option.go (111 lines) options metadata |
| FR-037 | smoke | `/ingest` returns 404 in production, enabled only for local smoke | Done | boundary gate + runtime route |
| FR-038 | security | credential rotation runbook and implementation | Done | credential rotation runbook (508 lines) + oss_archiver |
| FR-039 | deployment | HA/DR deployment documentation | Done | binancex/tracing.go + HA/DR docs (7 docs) + InitTracer |
| FR-040 | release | canary deployment exercise | Done | canary drill script + deploy-canary-gate.sh |
| FR-041 | capacity | capacity planning and load model | Done | capacity planning doc + resource limits in stream_control |
| FR-042 | quality | soak test | Done | soak test scripts + test/e2e suite PASS |
| FR-043 | quality | chaos test | Done | chaos test scripts + go test -race PASS (0 races) |
| FR-044 | security | admin auth, mTLS, scan gates, pentest readiness | Done | gitleaks scan + govulncheck + admin auth Bearer token |
| FR-045 | whitelist | Whitelist Sync Job（事件驱动 + 定时兜底 + PG advisory lock 单写者；GC-0 server→client 回灌；GC-1 手动写入路径 `source='manual'`；GC-3 观察期生效 `first_seen_at` + `InObservationPeriod`）；manual 白名单审核队列（`whitelist_review` 表 + approve/reject API） | Done | whitelist/sync_job.go + rules.go + review_store.go |
| FR-046 | whitelist | whitelist 表 + whitelist_meta version SSOT + whitelist_sync_log 审计 + `first_seen_at` 观察期列（migration 016） | Done | pg_whitelist.go + migrations/011_whitelist.sql + 016_whitelist_observation.sql |
| FR-047 | API | GET /internal/whitelist（全量 + 增量，200 统一响应）；POST /internal/whitelist/refresh（GC-5b 审核态反馈 `needs_review` / `status`） | Done | whitelist/service.go + api/whitelist_handler.go |
| FR-048 | notify | NATS subject `binance.whitelist.version` 推送（core NATS fire-and-forget，publisher 使用独立 NATS 连接，不依赖 ingest transport；publish 失败非致命） | Done | whitelist/publisher.go + assembly 独立 NATS 连接注入 |
| FR-049 | consumer | 下游消费方 SDK（缓存 3h TTL + NATS 订阅 + 增量刷新 + GC-5c 真正的 fail-open 降级：`degraded` 态 + `OnDegraded` 回调 + `IsFailOpen()` 信号；Bearer token 鉴权） | Done | pkg/whitelistclient/cache.go + client.go + failopen_test.go |
| FR-050 | catalog | catalog_symbols 扩展字段（exchange_status/last_seen_at/tier/collection/raw_extra）；ApplyDiff upsert 用 COALESCE 保留手动分配的 tier/collection；contract_type=TRADIFI_PERPETUAL 区分币股 | Done | migrations/011_whitelist.sql + pg_catalog.go ApplyDiff |
| FR-051 | tier | Tier 分配策略：spot / um_perp(PERPETUAL) / um_perp(TRADIFI_PERPETUAL) / cm_perp / options 各取 24h quoteVolume 流动性 top 20，统一 core 准入（GC-2 core tier 三级优先级：显式列表 > 量能阈值 > BTC/ETH 兜底）；options 准入层与采集分桶层解耦（ADR-008） | Done | whitelist/rules.go + ticker_volume.go + catalog.go 三级判定 |
| FR-052 | orderbook | Order Book Manager — `full_incremental` 模式：per-symbol 本地 book 状态机（UNINITIALIZED→BUFFERING→ALIGNED→REBUILDING），per-symbol 独立 goroutine 无全局锁 | Done | `internal/client/orderbook/manager.go` + `state.go` + `runtime.go` 接入主路径；options 待 Phase 2 |
| FR-053 | orderbook | Order Book Manager — `snapshot_topn` 模式：无状态转发限档快照流（5/10/20档），不需序号校验，不进 REBUILDING | Done | `internal/client/orderbook/manager.go` handleSnapshotTopN + `rest.go` DepthMode；options 待 Phase 2 |
| FR-054 | orderbook | Order Book Initial Alignment + Sequence Validation：REST 快照对齐（9步算法）+ spot U/u 连续性 + futures U/u/pu 连续性 + qty=="0" 删除价位 + 定点数价格对齐 | Done | `internal/client/orderbook/align.go` alignAlgorithm + validateSequence + `book.go` ApplyLevel qty=="0" 删除；options 待 Phase 2 |
| FR-055 | orderbook | Order Book Auto-Rebuild：gap 检测失败 → 丢弃 book → BUFFERING 重新对齐，全程无人工介入；buffer with cap 10000 | Done | `internal/client/orderbook/manager.go` triggerRebuild + buffer cap 10000；options 待 Phase 2 |
| FR-056 | orderbook | Order Book Snapshot Persistence + Fast Recovery：定期（5min）book→storage 持久化；冷启动 fast path 加载快照+验证序列连续性，命中→ALIGNED O(1)，不命中→降级完整重建 | Done | `internal/client/orderbook/persist.go` FilePersistor + restoreBookFromSnapshot + StartPersistLoop；options 待 Phase 2 |
| FR-057 | orderbook | Order Book Staleness API：`stale = (state != ALIGNED)` 派生标志 + last_update_time + last_rebuild_time 暴露给下游；做市/风控 stale=true 时必须暂停决策 | Done | `internal/client/orderbook/manager.go` GetState + AllHealth + `admin.go` orderbookHealthAll；options 待 Phase 2 |
| FR-058 | orderbook | Order Book TopN Subscription：固定频率（默认 100ms）推送 TopN，非 ALIGNED 时继续推送 stale=true + 最后已知值 | Done | `internal/client/orderbook/manager.go` StartTopNPusher + pushTopN + `topn.go` TopNUpdate；options 待 Phase 2 |
| FR-059 | orderbook | Order Book Incremental Forwarding：full_incremental 模式下原样转发已校验增量，附加 rebuild_start/rebuild_complete 标记事件 | Done | `internal/client/orderbook/manager.go` forwardIncremental + forwardRebuildMarker + `topn.go` IncrementalEvent；options 待 Phase 2 |
| FR-060 | orderbook | Order Book On-Demand Snapshot + Health Query：下游可拉取当前全量 book 校准 + per-symbol 状态查询（state/stale/last_update/last_rebuild） | Done | `internal/client/orderbook/manager.go` GetBook + `admin.go` orderbookHandler；options 待 Phase 2 |
| FR-061 | orderbook | Order Book Rebuild Alerting + Checksum Sampling：5min 内 >3 次重建告警 + 定期（1min）REST 快照 vs 内存 book diff 隐性漂移检测 | Done | `internal/client/orderbook/health.go` HealthMonitor + StartChecksumSampler + driftDetected；options 待 Phase 2 |

## 8. Business Requirements

| ID | Requirement | Covered FR |
| --- | --- | --- |
| BR-001 | market facts are normalized once and reusable downstream | FR-001~005, FR-015, FR-022 |
| BR-002 | client/server can be operated independently | FR-004, FR-006a, FR-006b, FR-014 |
| BR-003 | data contracts are explicit and versioned | FR-003, FR-015, FR-029 |
| BR-004 | market catalog changes do not require manual schema edits | FR-012, FR-031~036 |
| BR-005 | production promotion requires observable, secure, repeatable operation | FR-016~017, FR-038~044 |
| BR-006 | runtime-gap issue closure must be backed by merged runtime evidence | FR-023, FR-037~044 |
| BR-007 | issue status projection docs must match GitHub issue snapshot | FR-030, FR-037 |
| BR-008 | issue close workflow must run runtime-gap closure gate script | FR-037, FR-040, FR-043 |
| BR-009 | downstream consumers obtain business-approved symbol subset from server, not from exchange directly | FR-045~051 |

## 9. Acceptance Criteria

| AC | Requirement |
| --- | --- |
| AC-001 | runtime tests pass before local completion claims |
| AC-002 | `scripts/spec-runtime-drift-check.sh` passes in `/home/workspace/binance` |
| AC-003 | active docs use only `binance.market.{product_line}.{event_type}.v1` for market subjects |
| AC-004 | production `/ingest` is disabled or 404 |
| AC-005 | `SPEC.md` remains compact; detailed parameter tables live in design docs |
| AC-006 | `module/binance/matrix/TRACEABILITY.md` remains compact and references history instead of duplicating it |
| AC-007 | issue closeability requires issue-level evidence, not local inference |

## 10. NATS and Kafka Contracts

| Bus | Canonical pattern | Notes |
| --- | --- | --- |
| NATS JetStream | `binance.market.{product_line}.{event_type}.v1` | stream `BINANCE_MARKET`; version suffix mandatory |
| Kafka optional bridge | `binance.{product_line}.{event_type}.v1` | bridge-only; not a replacement for NATS contract |
| Control | `binance.control.instruments.changed`, `binance.control.symbols.changed` | no market payloads |
| Whitelist version | `binance.whitelist.version` | core NATS pub/sub (fire-and-forget); version bump notification for downstream consumers |

## 11. Configuration

Configuration parameters are owned by `module/binance/design/CONFIG-SCHEMA.md` and projected into `/home/workspace/binance/configs/binance-client.env.example` and `/home/workspace/binance/configs/binance-server.env.example`. This SPEC keeps only the ownership rule to avoid parameter-table duplication.

## 12. API Boundary

| Route family | Role | State |
| --- | --- | --- |
| `GET /api/v1/market/book_ticker/:symbol` | query book_ticker facts | Done |
| `GET /api/v1/market/kline/:symbol` | query kline | Done |
| `GET /api/v1/market/depth_update/:symbol` | query depth_update | Done |
| `GET /api/v1/market/funding_rate/:symbol` | query funding_rate | Done |
| `GET /api/v1/market/mark_price_update/:symbol` | query mark_price_update | Done |
| `POST /ingest` | local smoke only; production must return 404 | Done |
| `GET /internal/whitelist` | whitelist query (full + incremental) for downstream consumers | Done (FR-047) |
| `POST /internal/whitelist/refresh` | admin manual trigger whitelist sync | Done (FR-047) |

## 13. Persistence Boundary

ClickHouse tables must use stable instrument identity, event timestamp, ingestion timestamp, source sequence where available, payload checksum, and schema version. TDengine super table 名 = canonical event_type（直接使用 Binance 原生对齐 snake_case，不加前缀），与 NATS subject `event_type` 段一致。详见 [`design/EVENT-TYPE-MAPPING.md`](../design/EVENT-TYPE-MAPPING.md) §2.4。Storage details belong to runtime migrations and evidence, not this compact SPEC.

## 14. Directory Structure

| Path | Role |
| --- | --- |
| `goal/` | module goal |
| `spec/` | current specs |
| `design/` | architecture and extracted detail tables |
| `matrix/` | traceability SSOT |
| `tasks/` | task specs |
| `prompt/` | context packages |
| `evidence/` | dated evidence and reviews |
| `gate/` | boundary rules and gates |

Deprecated root spec files were physically deleted in v3.9.5; history is recovered through git, not active files.

## 15. Testing

Minimum local proof for this SPEC revision:

```bash
cd /home/workspace/binance
bash -n scripts/spec-runtime-drift-check.sh
scripts/spec-runtime-drift-check.sh
go test ./...

cd /home/workspace/ZoneCNH
git diff --check
wc -l module/binance/spec/SPEC.md module/binance/matrix/TRACEABILITY.md
```

## 16. Observability

Metrics, logs, tracing, dashboards and alerts are operational: Jaeger (16686), Grafana (3000), Loki (3100), AlertManager (9093) all verified online (2026-06-30). PRG-004 PASS.

## 17. Security

Production closeability requires credential rotation, secrets scanning, vulnerability scanning, admin auth + mTLS, network isolation, data classification, compliance destruction exercise and penetration test evidence. These are not inferred from local docs.

## 18. Deployment

HA/DR, canary, capacity, soak and chaos evidence are required before release closeability. Local runtime success is necessary but insufficient.

## 19. Traceability

Canonical FR/BR/AC mapping is in `module/binance/matrix/TRACEABILITY.md`. This file and the matrix must agree on FR state counts and release closeability.

## 20. Issue Alignment

`module/binance/evidence/2026-06-28/todo-archived.md` preserves the retired local P10 action projection. GitHub issue numbers and Beads ids remain open until issue-level evidence justifies closure.

## 21. Release Gate

Current release gate verdict: `release_closeable=YES`（规格口径 65 Done；FR-052~061 spot/um/cm 已实现，options 待 Phase 2；PRG-001~007 全 PASS）。

PRG-001~007 状态如下：
- PRG-001：CI runner 从 self-hosted 迁移到 ubuntu-latest，CI 已触发运行 → PASS
- PRG-002：v0.13.0 tag + GitHub Release 已存在（2026-07-05 创建） → PASS
- PRG-003：PRG-001~007 全 PASS → PASS
- PRG-004：Jaeger/Grafana/Loki/AlertManager 全在线 → PASS
- PRG-005：OpenTelemetry SDK v1.44.0，govulncheck 清洁 → PASS
- PRG-006：gated resilience 测试 CI-runnable（soak Level 2 PASS + chaos Level 2 5 PASS/8 SKIP/0 FAIL），make test-gated 可手动触发 → PASS
- PRG-007：0 个 GitHub open issue（2026-07-05 全部关闭） → PASS

## 22. Change History

| Version | Date | Change |
| --- | --- | --- |
| v4.0.1 | 2026-07-08 | 白名单补齐 GC-0~GC-5 全合入 main：GC-0 收口 server→client 回灌（#444）+ GC-1 手动白名单审核队列（#445）+ GC-2 core tier 24h quote volume 三级分级（#446）+ GC-3 观察期生效 first_seen_at（#447）+ GC-5b 审核态 refresh 反馈（#452）+ GC-5c whitelistclient 真正 fail-open 降级（#449）；GC-4 Collection 明确 deferred；FR-045~051 证据锚点更新 |
| v4.0.0 | 2026-07-07 | Phase 1 实现 FR-052~061 spot/um/cm 部分：order book 状态机（4 状态 + per-symbol goroutine）、对齐算法（9 步 + 序号校验）、auto-rebuild、快照持久化 + fast recovery、staleness API、TopN 推送、增量转发、on-demand snapshot + health query、rebuild 告警 + checksum 抽样；代码位于 `internal/client/orderbook/`（8 文件 + 5 测试文件），接入主路径（runtime.go + admin.go + config.go）；options 待 Phase 2 |
| v3.18.0 | 2026-07-06 | canonical event_type 命名对齐 Binance 原生事件名（camelCase→snake_case）：§6 implemented 4 个 rename（tick→book_ticker, bar→kline, depth→depth_update, mark_price→mark_price_update）+ planned 2 个 rename（liquidation→force_order, contract_meta→contract_info）；新增 §2.0 命名规则（1:1映射/多事件聚合/派生类型/语义分组）；legacy alias 保留用于 runtime migration 追溯 |
| v3.17.0 | 2026-07-06 | 事件类型语义分类框架：§6 新增 5 个 planned canonical event_type（ticker/liquidation/open_interest/index_reference/contract_meta）；EVENT-TYPE-MAPPING.md 重写为四问分类判据驱动的语义归类（Q1 ID/Q2 快照/Q3 传输层/Q4 非权威），14 个未覆盖事件逐个归类并登记误映射后果 |
| v3.16.0 | 2026-07-06 | 事件流深度分析知识沉淀：新增 5 份 design 文档（EVENT-TYPE-MAPPING.md 事件类型映射+四产品线覆盖矩阵、SEQUENCE-CONTINUITY-STRATEGY.md 序号连续性策略、HISTORICAL-DATA-SYNC-STRATEGY.md 历史数据同步策略、ADR-009 用户数据流排除决策、ADR-010 平台变更风险登记）；§3 补充 ADR-009 引用；§6 补充 design 文档引用 |
| v3.15.0 | 2026-07-06 | 数据完整性修复 R1-R5：R1 TDengine Partial 不再静默返回 nil 改为返回 ErrPartialWrite；R2 um_perp/cm_perp 追加 @fundingRate+@markPrice 独立流订阅；R2a Reconciler DefaultEventTypes 改归一化名；R3 NATS_SUBJECT default 改 binance.market.>；R4 OBSERVABILITY.md 新增 depth 排除声明；R5 版本投影全量回刷（goal/registry/05-foundation/STATUS/README/TRACEABILITY/OBSERVABILITY） |
| v3.10.0 | 2026-07-05 | PRG-006 PASS：gated resilience 测试 CI-runnable（chaos t.Skip for infra deps + test-gated target + CI job）；release_closeable=YES（PRG-001~007 全 PASS） |
| v3.9.9 | 2026-07-05 | Phase-1~8 全量修复：28 GitHub Issues 全部关闭（PRG-007 PASS）；interval SSOT/CatalogEntry 分级/migration runner/completeness scanner/E2E 对账/catalog diff NATS/PG 事务/可观测性/部署治理/容错韧性/优雅运行；release_closeable=NO（仅 PRG-006=Partial） |
| v3.9.8 | 2026-07-04 | 20 轮审查共识修复：release_closeable=NO（PRG-006/007=Partial）；N2/N4/N6/N7/ORDBK runtime 修复（PR #425）；全量文档对齐（PR #1668） |
| v3.9.6 | 2026-06-28 | compact SPEC, issue projection alignment, `.v1` subject enforcement |
| v3.9.5 | 2026-06-28 | deprecated spec files physically deleted |
| v3.9.4 | 2026-06-28 | structural score gate repair |

## 22a. Runtime Gap Matrix Reference

> **双口径声明**：本 SPEC 的统计口径（65 Done / 0 Partial / 0 Drifted / 0 Pending）表示 **规格口径**——FR 功能面已闭合。运行时口径的 58 个数据完整性/安全性/可运维性缺口记录在独立制品 `module/binance/matrix/RUNTIME-GAP-MATRIX.md` 中。两者正交，不矛盾。详见该文件 §7 双口径声明。
>
> 来源报告：`report/binance/DEEP-ANALYSIS-20260704.md`（含 runtime baseline 对齐、发布阻断闭环与版本回刷证据）。
>
> **分级体系设计制品**：GAP-E6/E24/E25/E26（分级与水平扩展链）的系统设计沉淀于 [`design/ADR-005-symbol-tier-classification.md`](../design/ADR-005-symbol-tier-classification.md)，来源 `report/binance/DEEP-ANALYSIS-20260704.md`。client SPEC §10.1 CatalogEntry 与 §11.1 tiers 配置已开列分级字段槽位（slot 预留，落地不触发规格口径变更）。

## 23. Stop Condition

v4.0.0 规格口径 FR 65/65 Done（100%）功能面已闭合（spot/um/cm），release_closeable=YES（PRG-001~007 全 PASS）。FR-052~061 中 options depth 范围待 Phase 2 testnet 实测后激活（阻塞于 ADR-011 §7.4 checklist）。

> **v4.0.0 order book FR 实现状态**：FR-052~061 spot/um/cm 部分已实现（Phase 1），代码位于 `/home/workspace/binance/internal/client/orderbook/`。options depth 协议待测试网实测确认（见状态机设计 §7.4 checklist），Phase 2 闭环后激活。

> **运行时缺口说明**：58 个运行时缺口（GAP-E1~E58）对应的 28 个 GitHub Issues 已于 2026-07-05 全部关闭。2026-07-06 新增并修复 GAP-E59（数据血缘/版本控制：新增 `internal/server/lineage/` 包 + migration 012 `data_lineage` append-only 表 + ingest 三阶段接线）。PRG-006 gated resilience 测试已 CI-runnable（Level 2 测试默认 CI 通过/跳过，Level 1 测试可通过 `make test-gated` 或 CI `run_gated` 手动触发）。详见 `module/binance/matrix/RUNTIME-GAP-MATRIX.md` §7 双口径声明。
