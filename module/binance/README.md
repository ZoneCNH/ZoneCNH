# module/binance

`module/binance` is the Binance-specific Market Data C/S Module for ZoneCNH.

- Spec-Version: v4.0.0 (root / client / server — v3.18.0 canonical 命名对齐 + v4.0.0 order book rebuild 纳入 ADR-011)
- Runtime-Version: v0.13.0（Runtime-Anchor: `/home/workspace/binance@main`）
- Delivery-State: FR-001~FR-055 spec/traceability registered — single state `55 Done / 0 Partial / 0 Drifted / 0 Pending`。release_closeable=YES（PRG-001~007 全 PASS）。47/47 tasks Done；deep-review 37/37 fixed；coverage 100.0%；0 GitHub open issues。
- Last-Updated: 2026-07-06 (canonical 命名对齐 Binance 原生事件名)

[COMPUTED, HIGH] 当前 Binance 发布结论：单状态模型为 `55 Done / 0 Partial / 0 Drifted / 0 Pending`，release_closeable=YES（PRG-001~007 全 PASS）。47/47 tasks Done，deep-review 37/37 fixed；0 GitHub open issues（28 issues 于 2026-07-05 全部关闭）；PRG-006 gated resilience 测试 CI-runnable（soak L2 PASS + chaos L2 5 PASS/8 SKIP/0 FAIL）。

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

[COMPUTED, HIGH] Current alignment ledger: Beads (`bd`) + GitHub Issues #1289~#1331. Archived legacy Markdown ledger: [`evidence/2026-06-28/todo-archived.md`](evidence/2026-06-28/todo-archived.md). Historical GitHub issue-sync ledger: [`../../report/binance/issues-sync-20260625.md`](../../report/binance/issues-sync-20260625.md).

[COMPUTED, HIGH] GitHub #1104~#1118 and #1123 remain historical 2026-06-25 sync evidence. Current stop condition is the single state ledger plus production evidence/live/CI/dashboard/credentials/multi-tenant/destruction gates listed in the 2026-06-28 P10 issues.

[COMPUTED, HIGH] 2026-07-07 对齐状态：当前 single state 为 `55 Done / 0 Partial / 0 Drifted / 10 Pending`（FR-052~061 order book rebuild），release_closeable=YES（PRG-001~007 全 PASS）。历史 full E2E evidence closure 仍保留为 historical 证据归档（`/home/workspace/binance/release/evidence/binance/20260628-full-e2e-closure/`），不作为当前结论来源。

[COMPUTED, HIGH] 2026-07-07 Issue Gate：`module/binance/todo.md` 是只读投影，Beads/GitHub Issues 是关闭 SSOT。当前口径：`55 Done / 10 Pending`、release_closeable=YES（PRG-001~007 全 PASS）。历史 P10 对齐证据见 [`evidence/2026-06-28/review/p10-closure-evidence.md`](evidence/2026-06-28/review/p10-closure-evidence.md) 与 [`evidence/2026-06-28/p10-alignment-10-pass.md`](evidence/2026-06-28/p10-alignment-10-pass.md)（historical）。

[COMPUTED, HIGH] 2026-07-05 Issue Gate：`gh issue list -R ZoneCNH/binance --state open` = 0 open。Phase-1~8 全量修复（28 issues closed），PRG-001~007 全 PASS，release_closeable=YES。PRG-006 gated resilience 测试 CI-runnable（PR #426）。

[COMPUTED, HIGH] 2026-06-27 Beads/GitHub issue alignment evidence (historical): [`evidence/2026-06-27/review/issue-alignment-20260627.md`](evidence/2026-06-27/review/issue-alignment-20260627.md)。P10 closure 已于 2026-06-28 全量完成（43 issues all closed）。

## Read Next

- `spec/SPEC.md`
- `goal/goal.md`
- `design/DESIGN.md`
- `design/EVENT-TYPE-MAPPING.md` — Binance 原生事件类型 → canonical 映射 + 四产品线覆盖矩阵
- `design/SEQUENCE-CONTINUITY-STRATEGY.md` — 序号连续性校验策略
- `design/HISTORICAL-DATA-SYNC-STRATEGY.md` — 历史数据同步起始时间策略
- `design/ADR-009-user-data-stream-scope.md` — 用户数据流排除决策
- `design/ADR-010-platform-change-risks.md` — 平台变更风险登记
- `deploy/README.md`
- `gate/BOUNDARY-GATES.md`
- `matrix/TRACEABILITY.md`
- `evidence/2026-06-26/`
