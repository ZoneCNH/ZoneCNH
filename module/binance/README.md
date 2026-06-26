# module/binance

`module/binance` is the Binance-specific Market Data C/S Module for ZoneCNH.

- Spec-Version: v3.7.1 (root) / v2.1.1 (client) / v2.2.0 (server)
- Runtime-Version: v0.2.0（Runtime-Anchor: `/home/binance@756fbc5`）
- Delivery-State: FR-001~FR-047 spec/traceability registered; **2026-06-26 — Status-Projection `24 Done / 10 Partial / 13 Pending`**（Pending: FR-037~044 生产标准化 + FR-045~047 运维需求——告警消费/优雅关闭/启动验证）。Runtime-Anchor `/home/binance@756fbc5`。Partial FR: FR-007, FR-007a, FR-011, FR-016, FR-017, FR-023, FR-024, FR-026, FR-027, FR-028。Draft FR: FR-031~036（ExchangeInfo 同步）。
- FR-Status-SSOT: **`TRACEABILITY.md` §1 为 FR 实现状态的唯一权威源（SSOT）**——本文件、`ACCEPTANCE.md`、`FEATURES.md`、`report/binance/` 中的 FR 状态均为投影，冲突时以 `TRACEABILITY.md` §1 为准。
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

详细版见 `analysis/archive/DEEP-ANALYSIS-ARCHIVE-architecture.md`（架构评估）
和 `analysis/archive/DEEP-ANALYSIS-ARCHIVE-integration.md`（集成详案）。

## GitHub Issue Sync Gate

[COMPUTED, HIGH] Current issue-tracking ledger: [`../../report/binance/issues-sync-20260625.md`](../../report/binance/issues-sync-20260625.md).

[COMPUTED, HIGH] GitHub #1104~#1118 are synchronized as of 2026-06-25. #1106 is the documentation alignment item and is closed by this module/report alignment; #1104, #1105, and #1107~#1118 remain open until runtime/evidence closure.

[COMPUTED, HIGH] 2026-06-26 alignment refresh: runtime anchor `/home/binance@756fbc5`; current FR projection `24 Done / 10 Partial / 13 Pending`（v3.7.1 有效基线：FR-037~047 为 Pending + FR-031~036 为 Draft）

## Read Next

**模块级**：
- `SPEC.md` — 根规格（C/S 边界契约）
- `TRACEABILITY.md` — 全模块追溯矩阵
- `BOUNDARY-GATES.md` — CI 门禁
- `RUNTIME-MAPPING.md` — 运行时仓映射
- `RULES.md` — 治理规则
- `STANDARD.md` — 模块标准
- `NAMING.md` — 命名 SSOT
- `ACCEPTANCE.md` — 验收清单
- `FEATURES.md` — 功能特性
- `CHANGELOG.md` — 变更历史

**Client**：
- `client/SPEC.md`
- `client/TRACEABILITY.md`

**Server**：
- `server/SPEC.md`
- `server/TRACEABILITY.md`
- `server/docs/PERSISTENCE-WIRING.md` — 存储装配契约
- `server/docs/ENDPOINTS.md` — REST API 端点
- `server/docs/OPERATIONS.md` — 部署与运维
- `server/docs/DATA-LIFECYCLE.md` — 数据生命周期
- `server/docs/DATA-QUALITY-SLA.md` — 数据质量 SLA

**分析归档**：
- `analysis/DEEP-ANALYSIS.md` — 架构决策深度分析
- `analysis/DEEP-ANALYSIS-INDEX.md` — 归档索引

**架构决策**：
- `adr/ADR-002-wire-boundary.md` — Wire Contract Boundary
- `specs/exchangeinfo-sync.md` — ExchangeInfo 同步增补规格（Draft）

**Tasks**：
- `tasks/README.md` — Task 索引
- `tasks/root/` — 跨切任务
- `tasks/client/` — Client 任务
- `tasks/server/` — Server 任务

**治理提案**：
- `analysis/GOVERNANCE-TIER-PROPOSAL.md` — 分层治理等级提案
- `analysis/DIR-STRUCTURE-PROPOSAL.md` — 目录结构优化提案
