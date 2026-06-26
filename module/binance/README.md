# module/binance

`module/binance` is the Binance-specific Market Data C/S Module for ZoneCNH.

- Spec-Version: v3.7.1 (root) / v2.1.1 (client) / v2.2.0 (server)
- Runtime-Version: v0.2.0（Runtime-Anchor: `/home/binance@f046e16`）
- Delivery-State: FR-001~FR-044 spec/traceability registered; **2026-06-26 spec-gap-closure — Status-Projection `24 Done / 10 Partial / 10 Pending`**（含 v3.7.0 新增 FR-037~044 + v3.7.1 FR-012~030 行为规范补齐 + FR-031~036 Draft）。Runtime-Anchor `/home/binance@f046e16`; PR #145 + #1189 合并。Partial FR: FR-007, FR-007a, FR-011, FR-016, FR-017, FR-023, FR-024, FR-026, FR-027, FR-028。Pending FR: FR-037~044。
- Last-Updated: 2026-06-26

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

详细版见 `DEEP-ANALYSIS.md` 的 §2.1 和 §5.1。

## GitHub Issue Sync Gate

[COMPUTED, HIGH] Current issue-tracking ledger: [`../../report/binance/issues-sync-20260625.md`](../../report/binance/issues-sync-20260625.md).

[COMPUTED, HIGH] GitHub #1104~#1118 are synchronized as of 2026-06-25. #1106 is the documentation alignment item and is closed by this module/report alignment; #1104, #1105, and #1107~#1118 remain open until runtime/evidence closure.

[COMPUTED, HIGH] 2026-06-25 alignment refresh: runtime anchor `/home/binance@f18a329`; current FR projection `24 Done / 10 Partial / 0 Pending`; Partial FR are FR-007, FR-007a, FR-011, FR-016, FR-017, FR-023, FR-024, FR-026, FR-027, and FR-028. Historical `28 Done / 2 Partial` and Plan007 `19 Done / 11 Partial` snapshots are retained only as history in `TRACEABILITY.md` and must not be used as current state.

## Read Next

- `spec/SPEC.md`
- `goal/goal.md`
- `design/DESIGN.md`
- `gate/BOUNDARY-GATES.md`
- `matrix/TRACEABILITY.md`
- `evidence/2026-06-26/`
