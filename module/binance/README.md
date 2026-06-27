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

[COMPUTED, HIGH] 2026-06-27 alignment refresh: runtime anchor `/home/binance@0602e78428633a368b0afcd1c578c07ed7144752` plus local working tree evidence package `/home/binance/release/evidence/binance/20260627-agent-audit-2/`; Code `23 Done / 25 Partial / 0 Drifted / 0 Pending` (Code-State)；Evidence-State **1 Done (FR-009) / 43 Pending**。Code-Partial: FR-007、FR-007a、FR-011、FR-013、FR-016、FR-017、FR-023、FR-024、FR-025、FR-026、FR-027、FR-028、FR-031、FR-032、FR-033、FR-034、FR-035、FR-036、FR-038、FR-039、FR-040、FR-041、FR-042、FR-043、FR-044。FR-031~036、FR-038~044 已由 Pending-only 修正为 Code-Partial / Evidence-Pending；FR-037 当前为 Code-Done / Evidence-Pending；production evidence/live/CI/dashboard/credentials/multi-tenant/destruction gates 仍未闭合。

[COMPUTED, HIGH] 2026-06-27 Beads/GitHub issue alignment evidence: [`evidence/2026-06-27/review/issue-alignment-20260627.md`](evidence/2026-06-27/review/issue-alignment-20260627.md). Current tracker status for GitHub #1267-#1279 is `OPEN`, Beads `ZoneCNH-8lb` and `ZoneCNH-xzcr*` are `in_progress`, and the Evidence-State blockers remain documented in the ledger and [`todo.md`](todo.md). Historical GitHub #1093 is closed/relocated; current milestone tracking is governed by the core-loop milestone evidence.

## Read Next

- `spec/SPEC.md`
- `goal/goal.md`
- `design/DESIGN.md`
- `gate/BOUNDARY-GATES.md`
- `matrix/TRACEABILITY.md`
- `evidence/2026-06-26/`
