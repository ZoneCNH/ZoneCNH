# module/binance

`module/binance` is the Binance-specific Market Data C/S Module for ZoneCNH.

- Spec-Version: v3.9.0 (root / client / server — 2026-06-26 内容正确性大修 + 2026-06-27 结构性修复：限流分钟模型、缺口检测按事件类型分策略、回填三级优先级、symbol生命周期、WS连接管理、退避参数补全、双态模型+Code-Partial/Code-Drifted、config schema 字段名统一、退役文件 DEPRECATED、Appendix D 迁移)
- Runtime-Version: v0.2.0（Runtime-Anchor: `/home/binance@f046e16`）
- Delivery-State: FR-001~FR-044 spec/traceability registered — Code `22 Done / 26 Partial / 0 Drifted / 0 Pending` (Code-State)；Evidence-State **1 Done (FR-009) / 43 Pending**。Drifted FR: 无。Code-Partial: FR-007、FR-007a、FR-011、FR-013、FR-016、FR-017、FR-023、FR-024、FR-025、FR-026、FR-027、FR-028、FR-031、FR-032、FR-033、FR-034、FR-035、FR-036、FR-037、FR-038、FR-039、FR-040、FR-041、FR-042、FR-043、FR-044。Code-Pending: 无。FR-031~044 仅为本地 anchors，生产运营仍 blocked。
- Last-Updated: 2026-06-27 (v3.9.0: 内容正确性大修 + 双态模型 + 结构性修复：config schema 统一 / Code-Partial/Code-Drifted 四态 / 退役文件 DEPRECATED / Appendix D 迁移 / §14 目录清理)

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

[COMPUTED, HIGH] 2026-06-27 alignment refresh: runtime anchor `/home/binance@f046e16`; Code `22 Done / 26 Partial / 0 Drifted / 0 Pending` (Code-State)；Evidence-State **1 Done (FR-009) / 43 Pending**。Code-Partial: FR-007、FR-007a、FR-011、FR-013、FR-016、FR-017、FR-023、FR-024、FR-025、FR-026、FR-027、FR-028、FR-031、FR-032、FR-033、FR-034、FR-035、FR-036、FR-037、FR-038、FR-039、FR-040、FR-041、FR-042、FR-043、FR-044。FR-031~044 已由 Pending-only 修正为 Code-Partial / Evidence-Pending；production evidence/live/CI/dashboard/credentials/multi-tenant/destruction gates 仍未闭合。

## Read Next

- `spec/SPEC.md`
- `goal/goal.md`
- `design/DESIGN.md`
- `gate/BOUNDARY-GATES.md`
- `matrix/TRACEABILITY.md`
- `evidence/2026-06-26/`
