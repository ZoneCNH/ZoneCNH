# module/binance

`module/binance` is the Binance-specific Market Data C/S Module for ZoneCNH.

## 入口导航

`module/binance` 只保留三条主线：

- 开发：`goal/goal.md`、`spec/SPEC.md`、`design/DESIGN.md`
- 验证：`matrix/TRACEABILITY.md`、`spec/ACCEPTANCE.md`
- 发布：`gate/RELEASE-CHECKLIST.md`、`gate/DEPLOY-PREFLIGHT.md`、`release/DEPLOYMENT-ORCHESTRATION.md`

其余文档保持原位，但不再在 README 里展开成完整流程。

- Spec-Version: v4.1.0 (root / client / server — canonical event_type recovery + order book rebuild 纳入 ADR-011)
- Runtime-Version: v0.15.1（last published tag；本轮 audit branch 未创建新 release tag）
- Runtime-Implementation-Commit: `462772f6`（fix/binance-production-readiness-20260710；local tests and boundary gates pass），尚未创建新 release tag。[COMPUTED, HIGH]
- Runtime-Evidence: `/home/workspace/binance/release/evidence/binance/20260710`；external-gates 当前 5 项 BLOCKED/NOT_RUN。[COMPUTED, HIGH]
- Delivery-State: FR-001~FR-065 spec/traceability registered — the specification projection remains `65 Done / 0 Partial / 0 Drifted / 0 Pending`; it does not grant runtime release approval. External E2E, tag/release notes and rollback remain open.
- Last-Updated: 2026-07-10 (todo closure audit + alignment split)

[COMPUTED, HIGH] 当前 Binance 规格结论仍为 `65 Done / 0 Partial / 0 Drifted / 0 Pending`；这是 FR/规格投影。runtime 正式发布结论保持 `release_closeable=NO`，直到同一最终 commit 具备外部 E2E、release tag/release notes、部署前检查和真实 rollback evidence。

It is split into two submodules:

```text
module/binance/client
module/binance/server
```

## Role

`module/binance` owns Binance-specific market_data ingestion into ZoneCNH.

It does not define the canonical market domain itself. Canonical semantics are owned by `module/domain_market`.

It does not define transport-neutral wire/domain contracts itself. Runtime transport is `natsx`; canonical payload semantics are owned by `module/domain_market`.

It owns Binance-specific persistence, query API, and fanout needed to serve accepted Binance facts. It does not own generic cross-exchange market_data semantics or strategy behavior.

## Submodules

| Submodule | Role |
|---|---|
| `module/binance/client` | Connects to Binance, parses exchange-native data, maps to `domain_market` envelopes, publishes through `natsx` JetStream |
| `module/binance/server` | Consumes `natsx` JetStream events, validates and deduplicates facts, persists Binance data, exposes Gin REST APIs, and fans out through `kafkax` |

## Removed Legacy Module

`binance-market` is removed.

New Binance market_data ingestion work must not target:

```text
module/binance-market
github.com/ZoneCNH/binance-market
```

## Runtime Shape

Recommended runtime repository shape:

```text
github.com/ZoneCNH/binance/
  cmd/
    binance-client/
    binance-server/
  internal/
    client/
    server/
  pkg/
    config/
    observability/
```

NATS JetStream 是独立部署的平台/基础设施服务；`binance-client` 与 `binance-server` 只配置连接地址，不内嵌或启动 NATS。
Dev 非敏感 NATS 默认连接为 `nats://127.0.0.1:4222`；认证通过 `FOUNDATIONX_NATS_*` 环境变量注入，明文只保留在本地 secrets。

## 数据流字符图

```text
Binance Exchange
  │ WS / REST
  ▼
module/binance/client
  catalog -> parser -> normalize -> mapper -> natsx publisher
  │
  ▼
natsx JetStream (BINANCE_MARKET)
  │
  ▼
module/binance/server
  consumer -> validation -> idempotency -> processor
   ├─ redisx hot cache / idempotency
   ├─ taosx time-series storage
   ├─ postgresx metadata / audit
   ├─ kafkax downstream fanout
   └─ ossx archive
  │
  └─ Gin REST API -> market_data / downstream consumers
```

详细版见 `design/DESIGN.md` §3（数据流）和 `spec/SPEC.md` §2（架构图）。历史深度分析已归档至 `design/DEEP-ANALYSIS-ARCHIVE-*.md`。

## Issue / Alignment Gate

[COMPUTED, HIGH] Current alignment ledger: Beads (`bd`) + GitHub Issues #1289~#1331. Archived legacy Markdown ledger: [`evidence/2026-06-28/todo-archived.md`](evidence/2026-06-28/todo-archived.md). Historical GitHub issue-sync ledger: `../../report/binance/issues-sync-20260625.md`.

[COMPUTED, HIGH] GitHub #1104~#1118 and #1123 remain historical 2026-06-25 sync evidence. Current stop condition is the single state ledger plus production evidence/live/CI/dashboard/credentials/multi-tenant/destruction gates listed in the 2026-06-28 P10 issues.

[COMPUTED, HIGH] 2026-07-07 对齐状态是历史快照：当时记录 `55 Done / 0 Partial / 0 Drifted / 10 Pending` 与 `release_closeable=YES`；不覆盖本文件顶部 2026-07-10 的 `65 Done` 规格投影和 `release_closeable_runtime=NO` 当前结论。历史 full E2E evidence closure 仍保留为归档证据，不作为当前结论来源。

[COMPUTED, HIGH] 2026-07-07 Issue Gate 是历史快照；`module/binance/todo.md` 仍是只读投影，当前 runtime release 状态以本轮 dated evidence 与 external ledger 为准。历史 P10 对齐证据见 [`evidence/2026-06-28/review/p10-closure-evidence.md`](evidence/2026-06-28/review/p10-closure-evidence.md) 与 [`evidence/2026-06-28/p10-alignment-10-pass.md`](evidence/2026-06-28/p10-alignment-10-pass.md)。

[COMPUTED, HIGH] 2026-07-05 Issue Gate：`gh issue list -R ZoneCNH/binance --state open` = 0 open。Phase-1~8 全量修复（28 issues closed），PRG-001~007 全 PASS，release_closeable=YES。PRG-006 gated resilience 测试 CI-runnable（PR #426）。

[COMPUTED, HIGH] 2026-06-27 Beads/GitHub issue alignment evidence (historical): [`evidence/2026-06-27/review/issue-alignment-20260627.md`](evidence/2026-06-27/review/issue-alignment-20260627.md)。P10 closure 已于 2026-06-28 全量完成（43 issues all closed）。

## Read Next

### 开发

- `goal/goal.md`
- `spec/SPEC.md`
- `design/DESIGN.md`
- `design/EVENT-TYPE-MAPPING.md` — Binance 原生事件类型 → canonical 映射 + 四产品线覆盖矩阵
- `design/SEQUENCE-CONTINUITY-STRATEGY.md` — 序号连续性校验策略
- `design/HISTORICAL-DATA-SYNC-STRATEGY.md` — 历史数据同步起始时间策略
- `design/ADR-009-user-data-stream-scope.md` — 用户数据流排除决策
- `design/ADR-010-platform-change-risks.md` — 平台变更风险登记
- `design/ADR-011-order-book-rebuild-inclusion.md` — 订单簿重建纳入决策（supersede ADR-003，v4.0.0 MAJOR 升级）

### 验证

- `matrix/TRACEABILITY.md`
- `evidence/2026-06-26/`

### 发布

- `gate/BOUNDARY-GATES.md`
- `gate/RELEASE-CHECKLIST.md`
- `gate/DEPLOY-PREFLIGHT.md`
- `release/DEPLOYMENT-ORCHESTRATION.md`
- `deploy/README.md`
