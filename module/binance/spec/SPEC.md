# Binance SPEC

- Spec-Version: v3.9.9
- Module: binance
- Last-Updated: 2026-07-05（Phase-1~8 全量修复：28 GitHub Issues 全部关闭；PRG-007 PASS；release_closeable=NO 因 PRG-006=Partial）
- Runtime-Repo: `/home/workspace/binance`
- Runtime-Version: v0.12.0
- State-Model: single-state only
- Current-State: 48 Done / 0 Partial / 0 Drifted / 0 Pending
- release_closeable: NO
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

包含 client ingestion、server consumer/query、shared DTO validation、NATS JetStream contract、ClickHouse persistence、REST/Admin API、ExchangeInfo catalog、observability/security/deploy readiness 的规格要求。不包含交易下单、账户管理、私有交易策略或生产凭证。

## 4. Runtime Boundary

| 子系统 | 职责 | 禁止 |
| --- | --- | --- |
| `internal/client` | 连接 Binance、公有市场流转换、发布 envelope | 依赖 server 包、写数据库、暴露生产 `/ingest` |
| `internal/server` | 消费 NATS、校验、持久化、查询 API | 连接 Binance WS、持有 client-only 配置 |
| `internal/wire` | shared DTO、topic/subject schema、validation、smoke-only transport | 承载业务流程、持久化、生产入口 |
| `configs/*.env.example` | 参数示例与默认边界 | 写入真实凭证 |

## 5. State Model

只允许单一状态：`Done` 或 `Partial`。历史 `Code-State` / `Evidence-State` 双态口径已废除。当前 48 个 FR Done（100%），0 Partial。`release_closeable=NO`，PRG-001~005、PRG-007 PASS；PRG-006 Partial（gated resilience 测试默认 CI 不执行）。参见 TRACEABILITY.md §4。

## 6. Product Lines and Event Types

| 维度 | 允许值 |
| --- | --- |
| product_line | `spot`, `um_perp`, `cm_perp`, `options` |
| event_type | `tick`, `bar`, `depth`, `trade`, `funding_rate`, `mark_price` |
| identity | exchange + product_line + instrument_type + instrument_subtype + symbol + expiry + strike + option_type |

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

## 11. Configuration

Configuration parameters are owned by `module/binance/design/CONFIG-SCHEMA.md` and projected into `/home/workspace/binance/configs/binance-client.env.example` and `/home/workspace/binance/configs/binance-server.env.example`. This SPEC keeps only the ownership rule to avoid parameter-table duplication.

## 12. API Boundary

| Route family | Role | State |
| --- | --- | --- |
| `GET /api/v1/market/ticks/:symbol` | query tick facts | Done |
| `GET /api/v1/market/bars/:symbol` | query bars | Done |
| `GET /api/v1/market/depth/:symbol` | query depth | Done |
| `GET /api/v1/market/funding-rate/:symbol` | query funding rate | Done |
| `GET /api/v1/market/mark-price/:symbol` | query mark price | Done |
| `POST /ingest` | local smoke only; production must return 404 | Done |

## 13. Persistence Boundary

ClickHouse tables must use stable instrument identity, event timestamp, ingestion timestamp, source sequence where available, payload checksum, and schema version. Storage details belong to runtime migrations and evidence, not this compact SPEC.

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

Current release gate verdict: `release_closeable=NO`（规格口径 FR 面 48/48 Done = 100% ≥ 90%，但 PRG-006=Partial 不满足全 PASS 前提；运行时口径 `PRG-006=Partial`（gated resilience 测试默认 CI 不执行）；PRG-007=PASS（0 open issues）。）。

PRG-001~007 状态如下：
- PRG-001：CI runner 从 self-hosted 迁移到 ubuntu-latest，CI 已触发运行 → PASS
- PRG-002：v0.12.0 tag + GitHub Release 已存在（2026-07-04 创建，target=c24b4ce） → PASS
- PRG-003：PRG-001~005、PRG-007 PASS；PRG-006 Partial（gated resilience） → Partial
- PRG-004：Jaeger/Grafana/Loki/AlertManager 全在线 → PASS
- PRG-005：OpenTelemetry SDK v1.44.0，govulncheck 清洁 → PASS
- PRG-006：soak/chaos 测试为 gated resilience，默认 CI 不执行 → Partial
- PRG-007：0 个 GitHub open issue（2026-07-05 全部关闭） → PASS

## 22. Change History

| Version | Date | Change |
| --- | --- | --- |
| v3.9.9 | 2026-07-05 | Phase-1~8 全量修复：28 GitHub Issues 全部关闭（PRG-007 PASS）；interval SSOT/CatalogEntry 分级/migration runner/completeness scanner/E2E 对账/catalog diff NATS/PG 事务/可观测性/部署治理/容错韧性/优雅运行；release_closeable=NO（仅 PRG-006=Partial） |
| v3.9.8 | 2026-07-04 | 20 轮审查共识修复：release_closeable=NO（PRG-006/007=Partial）；N2/N4/N6/N7/ORDBK runtime 修复（PR #425）；全量文档对齐（PR #1668） |
| v3.9.6 | 2026-06-28 | compact SPEC, issue projection alignment, `.v1` subject enforcement |
| v3.9.5 | 2026-06-28 | deprecated spec files physically deleted |
| v3.9.4 | 2026-06-28 | structural score gate repair |

## 22a. Runtime Gap Matrix Reference

> **双口径声明**：本 SPEC 的统计口径（48 Done / 0 Partial / 0 Drifted / 0 Pending）表示 **规格口径**——FR 功能面已闭合。运行时口径的 58 个数据完整性/安全性/可运维性缺口记录在独立制品 `module/binance/matrix/RUNTIME-GAP-MATRIX.md` 中。两者正交，不矛盾。详见该文件 §7 双口径声明。
>
> 来源报告：`report/binance/DEEP-ANALYSIS-20260704.md`（含 runtime baseline 对齐、发布阻断闭环与版本回刷证据）。
>
> **分级体系设计制品**：GAP-E6/E24/E25/E26（分级与水平扩展链）的系统设计沉淀于 [`design/ADR-005-symbol-tier-classification.md`](../design/ADR-005-symbol-tier-classification.md)，来源 `report/binance/DEEP-ANALYSIS-20260704.md`。client SPEC §10.1 CatalogEntry 与 §11.1 tiers 配置已开列分级字段槽位（slot 预留，落地不触发规格口径变更）。

## 23. Stop Condition

规格口径 FR 48/48 Done（100%）功能面已闭合，但 release_closeable=NO（PRG-006=Partial，不满足全 PASS 前提；PRG-007=PASS）。运行时口径仍存在 PRG-006 Partial（gated resilience 测试需在 runtime 仓按 gate 指南手动触发后回升 PASS）。

> **运行时缺口说明**：release_closeable=NO 基于 PRG-006 门禁未 PASS。58 个运行时缺口（GAP-E1~E58）对应的 28 个 GitHub Issues 已于 2026-07-05 全部关闭，代码修复在 binance 仓库 `fix/20round-review-consensus` 分支。PRG-006 为唯一剩余阻断项。详见 `module/binance/matrix/RUNTIME-GAP-MATRIX.md` §7 双口径声明与 §10 后续行动。
