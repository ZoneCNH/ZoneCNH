# module/binance

`module/binance` is the Binance-specific Market Data C/S Module for ZoneCNH.

- Spec-Version: v3.9.0 (root / client / server — 2026-06-26 内容正确性大修 + 2026-06-27 结构性修复：限流分钟模型、缺口检测按事件类型分策略、回填三级优先级、symbol生命周期、WS连接管理、退避参数补全、双态模型+Code-Drifted、config schema 字段名统一、退役文件 DEPRECATED、Appendix D 迁移)
- Runtime-Version: v0.2.0（Runtime-Anchor: `/home/binance@f046e16`）
- Delivery-State: FR-001~FR-044 spec/traceability registered — Code `21 Done / 10 Partial / 3 Drifted / 10 Pending`；Evidence-Done 仅 FR-009（13 gates PASS）。Drifted FR: FR-013, FR-017, FR-025（v3.9.0 spec 内容正确性大修后 runtime 未对齐）。Partial FR: FR-007, FR-007a, FR-011, FR-016, FR-023, FR-024, FR-026, FR-027, FR-028。Pending FR: FR-031~044。
- Last-Updated: 2026-06-27 (v3.9.0: 内容正确性大修 + 双态模型 + 结构性修复：config schema 统一 / Code-Drifted 四态 / 退役文件 DEPRECATED / Appendix D 迁移 / §14 目录清理)

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

## GitHub Issue Sync Gate

[COMPUTED, HIGH] Current issue-tracking ledger: [`../../report/binance/issues-sync-20260625.md`](../../report/binance/issues-sync-20260625.md).

[COMPUTED, HIGH] GitHub #1104~#1118 are synchronized as of 2026-06-25. #1106 is the documentation alignment item and is closed by this module/report alignment; #1104, #1105, and #1107~#1118 remain open until runtime/evidence closure.

[COMPUTED, HIGH] 2026-06-27 alignment refresh: runtime anchor `/home/binance@f046e16`; current FR projection `21 Done / 10 Partial / 3 Drifted / 10 Pending`; Drifted FR are FR-013, FR-017, FR-025 (v3.9.0 spec content correctness overhaul not yet reflected in runtime); Partial FR are FR-007, FR-007a, FR-011, FR-016, FR-023, FR-024, FR-026, FR-027, and FR-028. Historical `24 Done / 10 Partial`, `28 Done / 2 Partial` and Plan007 `19 Done / 11 Partial` snapshots are retained only as history in `TRACEABILITY.md` and must not be used as current state.

## Read Next

- `spec/SPEC.md`
- `goal/goal.md`
- `design/DESIGN.md`
- `gate/BOUNDARY-GATES.md`
- `matrix/TRACEABILITY.md`
- `evidence/2026-06-26/`
