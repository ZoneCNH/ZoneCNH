# Binance SPEC

- Spec-Version: v4.1.0
- Module: binance
- Last-Updated: 2026-07-10（runtime canonical capability 与 release evidence 对齐审计）
- Runtime-Repo: `/home/workspace/binance`
- Runtime-Version: v0.15.1（last published tag；本轮 runtime feature branch 尚未创建新 tag）
- State-Model: single-state only
- Current-State: 13 Done / 52 Partial / 0 Drifted / 0 Pending
- release_closeable_spec: NO（深度复审后 52 个 FR 仍缺功能或当前 RC 证据）
- release_closeable_runtime: NO（2026-07-10 runtime evidence 尚未闭合外部 durable/fanout/query E2E、正式 release tag/release notes 与 rollback）
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

只允许单一状态：`Done` 或 `Partial`。历史 `Code-State` / `Evidence-State` 双态口径已废除。[COMPUTED, HIGH] 当前追溯矩阵为 13 个 FR Done、52 个 Partial，因此 `release_closeable_spec=NO`；同一候选提交的 external-gates、正式 tag/release notes、部署前检查与 rollback 也未闭合，因此 `release_closeable_runtime=NO`。

## 6. Product Lines and Event Types

| 维度 | 允许值 |
| --- | --- |
| product_line | `spot`, `um_perp`, `cm_perp`, `options` |
| event_type (local contract/path implemented) | `book_ticker`, `kline`, `depth_update`, `trade`, `funding_rate`, `mark_price_update`, `option_tick`, `ticker`, `open_interest`, `index_reference`, `contract_info` |
| event_type (opt-in scaffold / postponed release) | `force_order`（独立事件设计与隔离实现已完成；不默认订阅，仍需 release owner 的独立 live gate 批准） |
| current release limitations | `funding_rate` 尚无独立实时/历史生产路径；Options 订单簿仅有显式白名单的本地代码路径，live/capacity/checksum 未验收；client 有界内存 backpressure/PubAck retry 已接入，但 client spec OQ-002 接受 crash-window 丢失，且配置/指标未闭合，与零静默丢失目标冲突 |
| identity | exchange + product_line + instrument_type + instrument_subtype + symbol + expiry + strike + option_type |

> [COMPUTED, HIGH] “local contract/path implemented”只表示对应 parser/mapper/allowlist/storage schema 中存在本地代码与测试锚点，不表示每个类型都已完成 Binance live capture、独立历史源、外部 durable fanout 或查询 readback。v3.18.0 canonical 命名对齐 Binance 原生事件名（camelCase→snake_case），legacy alias：`tick`→`book_ticker`、`bar`→`kline`、`depth`→`depth_update`、`mark_price`→`mark_price_update`。`force_order` 保持 opt-in/postponed；Options depth 的本地 snapshot+diff 路径已接入，但没有绑定当前 RC 的 live alignment/容量证据；`funding_rate` 独立数据流也未闭合。详见 [`design/EVENT-TYPE-MAPPING.md`](../design/EVENT-TYPE-MAPPING.md) §1-§3、[`design/FORCE-ORDER-EVENT-DESIGN.md`](../design/FORCE-ORDER-EVENT-DESIGN.md) 与 [`design/COMPATIBILITY-SUNSET-PLAN.md`](../design/COMPATIBILITY-SUNSET-PLAN.md)。

## 7. Functional Requirements

| ID | Scope | Requirement | State | Closure evidence |
| --- | --- | --- | --- | --- |
| FR-001 | client | ingest public tick/trade-like stream and normalize envelope | Done | local runtime + E2E history |
| FR-002 | client | ingest kline/bar stream and normalize envelope | Done | local runtime + E2E history |
| FR-003 | contract | publish to NATS subject `binance.market.{product_line}.{event_type}.v1` | Partial | current RC NATS external gate blocked |
| FR-004 | server | consume JetStream independently from client process | Partial | ManualAck/redelivery current-RC evidence needed |
| FR-005 | server | persist ticks to ClickHouse schema | Partial | durable persistence/readback evidence needed |
| FR-006a | client | provide client CLI/config loading | Done | runtime config examples |
| FR-006b | server | provide server CLI/config loading | Done | runtime config examples |
| FR-006c | config | shared env validation and deterministic defaults | Done | config schema + examples |
| FR-006d | smoke | local-only smoke path remains non-production | Done | `/ingest` smoke-only gate |
| FR-007 | API | query tick data through REST | Partial | current RC query E2E evidence needed |
| FR-007a | replay | historical replay/import path | Partial | durable replay/external readback evidence needed |
| FR-008 | client | ingest depth stream | Done | local runtime + E2E history |
| FR-009 | client | ingest aggregate trade stream | Done | local runtime + E2E history |
| FR-010 | server | persist/query bar aggregates | Partial | current RC persistence/query readback needed |
| FR-011 | reliability | delayed retry, parking, dead-letter behavior | Partial | local DLQ durability repaired; production mandatory-path and failure injection evidence needed |
| FR-012 | catalog | ExchangeInfo catalog refresh | Partial | Candidate Catalog/Admission separation needed |
| FR-013 | control | whitelist/blacklist hot reload | Partial | product-line refresh code exists; current RC hot-reload E2E needed |
| FR-014 | ops | graceful shutdown and drain | Partial | active history/drain recovery is not closed |
| FR-015 | identity | stable idempotency/event keys | Partial | request/payload/instrument identity validation incomplete |
| FR-016 | observability | metrics exporter coverage | Partial | current RC metrics scrape/capability-matrix evidence needed |
| FR-017 | observability | trace propagation and OTel visibility | Partial | current RC end-to-end OTel evidence needed |
| FR-018 | API | query bars through REST | Partial | current RC external readback needed |
| FR-019 | API | query depth through REST | Partial | orderbook and current RC depth evidence incomplete |
| FR-020 | API | query funding-rate data | Partial | independent funding realtime/history path absent |
| FR-021 | API | query mark-price data | Partial | current RC storage/query evidence needed |
| FR-022 | identity | distinguish spot/perp/delivery/options instruments | Partial | strong identity wire validation incomplete |
| FR-023 | lifecycle | retention, TTL, archival policy | Partial | OSS partition/durable retry/rehydrate evidence needed |
| FR-024 | control | symbol-change control subject and reload | Partial | current RC no-restart reload evidence needed |
| FR-025 | reliability | backpressure and reconnect limits | Partial | bounded in-memory queue/backpressure/PubAck retry is wired; crash-window loss policy and operator config/metrics require closure |
| FR-026 | recovery | checkpoint recovery after restart | Partial | retry/restart paths fixed; interval-set reconciliation and state-load fail-closed evidence needed |
| FR-027 | client | multi-product websocket lifecycle | Partial | Options capacity and four-line lifecycle evidence needed |
| FR-028 | errors | normalized error taxonomy | Partial | normalization/error classification coverage remains incomplete |
| FR-029 | data quality | anomaly/SLA tags and quality rules | Partial | coverage/gap/reconcile capability matrix incomplete |
| FR-030 | admin | health/readiness/admin status | Done | local runtime evidence |
| FR-031 | catalog | full ExchangeInfo sync | Partial | Candidate Catalog 与 Admission 尚未结构性分离 |
| FR-032 | catalog | diff ExchangeInfo sync | Partial | true Added/Updated/Removed propagation evidence needed |
| FR-033 | catalog | delist handling | Partial | strategy removal 与 exchange delisting 仍可能混淆 |
| FR-034 | identity | InstrumentKey stability | Partial | wire/payload identity consistency validation needed |
| FR-035 | identity | delivery expiry metadata | Partial | perpetual/delivery contract discovery separation needed |
| FR-036 | identity | options metadata | Partial | Options status filter and strong-key wire roundtrip needed |
| FR-037 | smoke | `/ingest` returns 404 in production, enabled only for local smoke | Done | boundary gate + runtime route |
| FR-038 | security | credential rotation runbook and implementation | Partial | current RC rotation receipt and exposed-literal incident closure needed |
| FR-039 | deployment | HA/DR deployment documentation | Partial | canonical SRE contract exists; current RC HA/DR exercise needed |
| FR-040 | release | canary deployment exercise | Partial | same-RC canary and rollback evidence needed |
| FR-041 | capacity | capacity planning and load model | Partial | Options shard and four-line load capacity evidence needed |
| FR-042 | quality | soak test | Partial | historical soak is not bound to current RC |
| FR-043 | quality | chaos test | Partial | historical chaos evidence is not bound to current RC |
| FR-044 | security | admin auth, mTLS, scan gates, pentest readiness | Partial | current security/pentest and credential-incident closure needed |
| FR-045 | whitelist | Whitelist Sync Job（事件驱动 + 定时兜底 + PG advisory lock 单写者；GC-0 server→client 回灌；GC-1 手动写入路径 `source='manual'`；GC-3 观察期生效 `first_seen_at` + `InObservationPeriod`）；manual 白名单审核队列（`whitelist_review` 表 + approve/reject API） | Partial | fail-open/update/reconnect E2E needed |
| FR-046 | whitelist | whitelist 表 + whitelist_meta version SSOT + whitelist_sync_log 审计 + `first_seen_at` 观察期列（migration 016） | Done | pg_whitelist.go + migrations/011_whitelist.sql + 016_whitelist_observation.sql |
| FR-047 | API | GET /internal/whitelist（全量 + 增量，200 统一响应）；POST /internal/whitelist/refresh（GC-5b 审核态反馈 `needs_review` / `status`） | Done | whitelist/service.go + api/whitelist_handler.go |
| FR-048 | notify | NATS subject `binance.whitelist.version` 推送（core NATS fire-and-forget，publisher 使用独立 NATS 连接，不依赖 ingest transport；publish 失败非致命） | Partial | current RC NATS version-push evidence needed |
| FR-049 | consumer | 下游消费方 SDK（缓存 3h TTL + NATS 订阅 + 增量刷新 + GC-5c 真正的 fail-open 降级：`degraded` 态 + `OnDegraded` 回调 + `IsFailOpen()` 信号；Bearer token 鉴权） | Done | pkg/whitelistclient/cache.go + client.go + failopen_test.go |
| FR-050 | catalog | catalog_symbols 扩展字段（exchange_status/last_seen_at/tier/collection/raw_extra）；ApplyDiff upsert 用 COALESCE 保留手动分配的 tier/collection；contract_type=TRADIFI_PERPETUAL 区分币股 | Partial | true Catalog Added/Updated/Removed propagation incomplete |
| FR-051 | tier | Tier 分配策略：4 档词表 prime/standard/lite/blocked；Options 准入层独立 | Partial | Options 独立 capability 与热更新已修；真实准入/容量证据仍缺失 |
| FR-052 | orderbook | Order Book Manager — `full_incremental` 模式 | Partial | Options path 已接入；四线 live generation/freshness 证据仍缺失 |
| FR-053 | orderbook | Order Book Manager — `snapshot_topn` 模式 | Partial | four-line snapshot evidence incomplete |
| FR-054 | orderbook | Initial Alignment + Sequence Validation | Partial | alignment/apply-error/Options evidence incomplete |
| FR-055 | orderbook | Auto-Rebuild | Partial | generation and disconnect trigger incomplete |
| FR-056 | orderbook | Snapshot Persistence + Fast Recovery | Partial | age/bridge/checksum validation absent |
| FR-057 | orderbook | Staleness API | Partial | disconnect freshness cannot be proven |
| FR-058 | orderbook | TopN Subscription | Partial | stale/pool lifecycle evidence incomplete |
| FR-059 | orderbook | Incremental Forwarding | Partial | rebuild markers can be dropped |
| FR-060 | orderbook | On-Demand Snapshot + Health Query | Partial | four-line evidence incomplete |
| FR-061 | orderbook | Rebuild Alerting + Checksum Sampling | Partial | config/concurrency/Options coverage incomplete |

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

Current release gate verdict: `release_closeable_spec=NO`; `release_closeable_runtime=NO`。[COMPUTED, HIGH]

PRG-001~007 状态如下：
- PRG-001：当前 RC 的远程 CI 成功证据未归档 → BLOCKED。[COMPUTED, HIGH]
- PRG-002：当前 RC 未创建 tag、release notes 与制品摘要 → BLOCKED。[COMPUTED, HIGH]
- PRG-003：PRG-001~007 未全部通过 → BLOCKED。[COMPUTED, HIGH]
- PRG-004：可观测外部环境未绑定当前 RC 重验 → BLOCKED。[COMPUTED, HIGH]
- PRG-005：当前 RC 的完整 security/lint 证据未闭合 → BLOCKED。[COMPUTED, HIGH]
- PRG-006：当前 RC 的外部耐久性、故障注入与回滚演练未绑定同一 commit → BLOCKED。[COMPUTED, HIGH]
- PRG-007：Beads 生产就绪 epic `ZoneCNH-7i1p` 仍为 in_progress，外部证据子项未闭合 → BLOCKED。[COMPUTED, HIGH]

## 22. Change History

| Version | Date | Change |
| --- | --- | --- |
| v4.1.0 | 2026-07-09 | Plan 013 白名单规则统一重构：tier 词表 core/standard→prime/standard/lite/blocked 4 档；tierCapabilityMap 三元组推导 SSOT；DepthLevel 全链路接通；删 7 套机制收敛为 PG 双表 1 套；migration 017/018 |
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

> [COMPUTED, HIGH] **单一状态声明**：当前统计为 13 Done / 52 Partial / 0 Drifted / 0 Pending。`RUNTIME-GAP-MATRIX.md` 是缺口细目，不是第二状态源；未闭合的功能或运行证据必须保持对应 FR 为 Partial。
>
> 来源报告：`report/binance/DEEP-ANALYSIS-20260704.md`（含 runtime baseline 对齐、发布阻断闭环与版本回刷证据）。
>
> **分级体系设计制品**：GAP-E6/E24/E25/E26（分级与水平扩展链）的系统设计沉淀于 [`design/ADR-005-symbol-tier-classification.md`](../design/ADR-005-symbol-tier-classification.md)，来源 `report/binance/DEEP-ANALYSIS-20260704.md`。client SPEC §10.1 CatalogEntry 与 §11.1 tiers 配置已开列分级字段槽位（slot 预留，落地不触发规格口径变更）。

## 23. Stop Condition

[COMPUTED, HIGH] Stop condition 尚未达成：当前 13/65 Done、52 Partial，且 Options 订单簿 live alignment/容量、当前 RC 外部 E2E、tag/release notes、preflight 与 rollback 证据未闭合。

> **v4.1.0 order book FR 实现状态**：FR-052~061 四线均保持 Partial。代码位于 `/home/workspace/binance/internal/client/orderbook/`；Options 已有显式白名单的 REST snapshot + full-incremental 路径，但仍须完成 live alignment、重连、容量与 checksum checklist 后才可发布。

> **运行时缺口说明**：58 个运行时缺口（GAP-E1~E58）对应的 28 个 GitHub Issues 已于 2026-07-05 全部关闭。2026-07-06 新增并修复 GAP-E59（数据血缘/版本控制：新增 `internal/server/lineage/` 包 + migration 012 `data_lineage` append-only 表 + ingest 三阶段接线）。PRG-006 gated resilience 测试已 CI-runnable（Level 2 测试默认 CI 通过/跳过，Level 1 测试可通过 `make test-gated` 或 CI `run_gated` 手动触发）。详见 `module/binance/matrix/RUNTIME-GAP-MATRIX.md` §7 双口径声明。
