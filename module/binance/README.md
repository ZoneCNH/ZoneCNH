# module/binance

`module/binance` is the Binance-specific Market Data C/S Module for ZoneCNH.

- Spec-Version: v3.5.0 (root) / v2.1.1 (client) / v2.2.0 (server)
- Runtime-Version: v0.1.0
- Delivery-State: FR-001~FR-030 spec/traceability registered; GitHub #923~#931 are closed as issue-tracking records on 2026-06-23; 2026-06-24 local runtime hygiene/build/readiness evidence passes, but runtime/release evidence remains Pending for FR-012~030 and PR-007 where no live/CI/release proof exists.
- Last-Updated: 2026-06-24

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

## GitHub Issue Closure Gate

[COMPUTED, HIGH] Current issue-tracking ledger: [`../../docs/report/binance/github-issues-923-931-closure-ledger-20260623.md`](../../docs/report/binance/github-issues-923-931-closure-ledger-20260623.md).

[COMPUTED, HIGH] GitHub #923~#931 are closed in GitHub state as of 2026-06-23. This closure does not replace runtime/release evidence: live websocket, external `natsx` / storage / fanout / query, remote CI, release tag, and FR-012~030 implementation evidence remain governed by acceptance and release gates.

[COMPUTED, HIGH] 2026-06-24 worker evidence refresh: `/home/binance` local checks passed (`make fmt-check boundary-gates build test vet readiness-audit`, `go test ./... -race -count=1`, `git diff --check`) at runtime HEAD `dd3332d3452f4eaa8146563bdb82caf577a3d4c1` with existing dirty readiness changes preserved. This local evidence updates hygiene/readiness traceability only; it does not close live websocket, external JetStream/storage/fanout/query, remote CI, or release tag gates.

## Read Next

- `SPEC.md`
- `BOUNDARY-GATES.md`
- `STANDARD.md`
- `DATA-LIFECYCLE.md`
- `RUNTIME-MAPPING.md`
- `client/SPEC.md`
- `server/SPEC.md`
