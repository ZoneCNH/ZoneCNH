# module/binance

`module/binance` is the Binance-specific Market Data C/S Module for ZoneCNH.

- Spec-Version: v3.6.0 (root) / v2.1.1 (client) / v2.2.0 (server)
- Runtime-Version: v0.2.0（已发布，CI 6/6 全绿，7/7 infra LIVE-PASS）
- Delivery-State: FR-001~FR-030 spec/traceability registered; **2026-06-25 生产就绪修复完成 — v0.2.0 已发布，FR 28 Done / 2 Partial / 0 Pending (93%)**. G0 存储装配闭合 — `storageFromEnv` 真实装配 5 infra client + 7 writer; 9 存储类 FR Partial→Done. **7/7 infra LIVE-PASS**（taosx v1.0.2/pg/redis/ch/kafka/oss/mainnet 四线 全实证）. CI 6/6 全绿（issue #94 closed）. v0.2.0 release.yml 首次成功（2 产物）. 剩余 2 Partial: FR-016/024（非阻断）. 详见 `report/binance/production-readiness-fix-execution-20260625.md`.
- Last-Updated: 2026-06-25

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

[COMPUTED, HIGH] Current issue-tracking ledger: [`../../report/binance/github-issues-923-931-closure-ledger-20260623.md`](../../report/binance/github-issues-923-931-closure-ledger-20260623.md).

[COMPUTED, HIGH] GitHub #923~#931 are closed in GitHub state as of 2026-06-23. This closure does not replace runtime/release evidence: live websocket, external `natsx` / storage / fanout / query, remote CI, release tag, and Partial FR implementation evidence remain governed by acceptance and release gates.

[COMPUTED, HIGH] 2026-06-25 alignment refresh: runtime HEAD `e02b190` (Plan007 A1~A10 + B1~B8 executed). FR status refreshed to 19 Done / 11 Partial / 0 Pending under main.go 装配级证据标准 (see `TRACEABILITY.md` v3.6.0 变更摘要). 9 存储类 FR 下调根因：`cmd/binance-server/main.go` 用 `bootstrap.Spec{Stores: bootstrap.None}` + `NewMemoryIdempotencyStore` + `StorageWriter=nil`，writer 代码完整但 runtime 永不执行（详见 [`report/binance/production-readiness-assessment-20260625.md`](../../report/binance/production-readiness-assessment-20260625.md) §4.1 G0）。Plan007 已闭合：G1 (历史回填真实 REST)、G3 (NakWithDelay+DLQ)、G4 (跨产品线碰撞测试)；G2/G5/G7/G8 仍 Partial。

## Read Next

- `SPEC.md`
- `BOUNDARY-GATES.md`
- `STANDARD.md`
- `DATA-LIFECYCLE.md`
- `RUNTIME-MAPPING.md`
- `client/SPEC.md`
- `server/SPEC.md`
