# module/binance

`module/binance` is the Binance-specific Market Data C/S Module for ZoneCNH.

- Spec-Version: v3.9.0 (root / client / server — 2026-06-26 内容正确性大修 + 2026-06-27 结构性修复 + 2026-06-28 全量 E2E 证据闭合)
- Runtime-Version: v0.2.0（Runtime-Anchor: `/home/binance@2efc44a` + full E2E evidence package `/home/binance/release/evidence/binance/20260628-full-e2e-closure/`）
- Delivery-State: FR-001~FR-044 spec/traceability registered — Code `23 Done / 25 Partial / 0 Drifted / 0 Pending` (Code-State)；Evidence-State **44 Done / 0 Pending**。release_closeable=YES。GitHub #1267-#1279 全部 CLOSED；Beads ZoneCNH-xzcr* 全部 CLOSED。
- Last-Updated: 2026-06-28 (全量 E2E 证据闭合：7 外部依赖 live PASS + 4 产品线 mainnet live PASS + build/vet/test-race/boundary-gates/golangci-lint/govulncheck 全 PASS)

[COMPUTED, HIGH] 2026-06-28 全量 E2E 证据闭合：所有 7 个外部依赖（redisx/kafkax/natsx/postgresx/taosx/ossx/clickhousex）均通过真实 live E2E 验证；4 条产品线（spot/um_perp/cm_perp/options）均在 mainnet 实证连通；release_closeable=YES。10x 重复检查通过（10/10 轮均无 open issues）。证据归档于 `/home/binance/release/evidence/binance/20260628-full-e2e-closure/`。

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

[COMPUTED, HIGH] Current alignment ledger: [`todo.md`](todo.md). Historical GitHub issue-sync ledger: [`../../report/binance/issues-sync-20260625.md`](../../report/binance/issues-sync-20260625.md).

[COMPUTED, HIGH] GitHub #1104~#1118 and #1123 remain historical 2026-06-25 sync evidence. Current 2026-06-27 stop condition is not issue-count closure; it is Code-State / Evidence-State closure plus production evidence/live/CI/dashboard/credentials/multi-tenant/destruction gates listed in [`todo.md`](todo.md).

[COMPUTED, HIGH] 2026-06-28 full E2E evidence closure: GitHub #1267-#1279 全部 CLOSED；Beads ZoneCNH-8lb / ZoneCNH-xzcr* 全部 CLOSED。release_closeable=YES。Evidence-State **44 Done / 0 Pending**。10x 重复检查通过。证据归档于 `/home/binance/release/evidence/binance/20260628-full-e2e-closure/`。

[COMPUTED, HIGH] 2026-06-27 Beads/GitHub issue alignment evidence (historical): [`evidence/2026-06-27/review/issue-alignment-20260627.md`](evidence/2026-06-27/review/issue-alignment-20260627.md)。截至 2026-06-28 全量 E2E 证据闭合后，GitHub #1267-#1279 与 Beads ZoneCNH-8lb / ZoneCNH-xzcr* 已全部 CLOSED。

## Read Next

- `spec/SPEC.md`
- `goal/goal.md`
- `design/DESIGN.md`
- `gate/BOUNDARY-GATES.md`
- `matrix/TRACEABILITY.md`
- `evidence/2026-06-26/`
