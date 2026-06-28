# module/binance

`module/binance` is the Binance-specific Market Data C/S Module for ZoneCNH.

- Spec-Version: v3.9.0 (root / client / server — 2026-06-26 内容正确性大修 + 2026-06-27 结构性修复 + 2026-06-28 P10 状态对齐)
- Runtime-Version: v0.2.0（Runtime-Anchor: `/home/binance@2efc44a`；历史 full E2E evidence package `/home/binance/release/evidence/binance/20260628-full-e2e-closure/` 仅作为运行证据，不构成发布关闭结论）
- Delivery-State: FR-001~FR-044 spec/traceability registered — single state `23 Done / 25 Partial / 0 Drifted / 0 Pending`。release_closeable=NO。43 个 Binance P10 issue 已全部关闭（GitHub #1289~#1331 + Beads 43 条）；10 轮验证 ALL PASS；但 Code-Done 23/48 ≈ 47.9% < 90% 门禁，不得声称 release 可关闭。
- Last-Updated: 2026-06-28 (P10 全量修复完成：43 issues 全部 closed；release_closeable 仍为 NO)

[COMPUTED, HIGH] 当前 Binance P10 发布结论：单状态模型为 `23 Done / 25 Partial / 0 Drifted / 0 Pending`，release_closeable=NO。43 个 P10 issue 已全部关闭（GitHub + Beads），10 轮验证 ALL PASS，但 Code-Done 23/48 ≈ 47.9% < 90% 门禁，release 仍不可关闭。

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

[COMPUTED, HIGH] 2026-06-28 P10 状态更正：历史 full E2E evidence closure 不再构成发布关闭结论；当前 single state 为 `23 Done / 25 Partial / 0 Drifted / 0 Pending`，release_closeable=NO。43 个 P10 issue 已全部关闭（10 轮验证 ALL PASS），但 Code-Done 47.9% < 90% 门禁，release 仍不可关闭。历史证据归档于 `/home/binance/release/evidence/binance/20260628-full-e2e-closure/`。

[COMPUTED, HIGH] 2026-06-28 P10 对齐状态：`module/binance/todo.md` 是只读投影，Beads/GitHub Issues 是关闭 SSOT。43 个 P10 issue 已全部关闭（GitHub #1289~#1331 + Beads 43 条），10 轮验证 ALL PASS。release_closeable=NO（Code-Done 23/48 ≈ 47.9% < 90%）。当前证据见 [`evidence/2026-06-28/review/p10-closure-evidence.md`](evidence/2026-06-28/review/p10-closure-evidence.md) 与 [`evidence/2026-06-28/p10-alignment-10-pass.md`](evidence/2026-06-28/p10-alignment-10-pass.md)。

[COMPUTED, HIGH] 2026-06-27 Beads/GitHub issue alignment evidence (historical): [`evidence/2026-06-27/review/issue-alignment-20260627.md`](evidence/2026-06-27/review/issue-alignment-20260627.md)。P10 closure 已于 2026-06-28 全量完成（43 issues all closed）。

## Read Next

- `spec/SPEC.md`
- `goal/goal.md`
- `design/DESIGN.md`
- `gate/BOUNDARY-GATES.md`
- `matrix/TRACEABILITY.md`
- `evidence/2026-06-26/`
