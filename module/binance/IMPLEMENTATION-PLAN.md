# module/binance IMPLEMENTATION PLAN

## 1. Goal

Deliver `module/binance` v1.0.0 as a complete Binance-specific market-data C/S module.

## 2. Required Preflight Decisions

Before runtime implementation:

1. `binance-market` is removed.
2. `module/binance/client` and `module/binance/server` are documented.
3. `module/binance/server` is the Binance-specific `MarketDataService` implementation.
4. `module/domain-market` owns canonical market semantics.
5. `module/contracts` owns proto/gRPC wire contracts.
6. `module/market-data` owns downstream exchange-neutral processing.
7. Delivery semantics are at-least-once + idempotent acceptance.

### Phase 0: Upstream Contract Closure Gate (2026-06-17 验证通过)

在进入运行时实现前，必须先验证三条上游契约链闭合：

| Gate | 验证项 | 验证方式 | 状态 |
|------|--------|----------|:----:|
| G0-1 | `module/contracts` §8.4 已定义 `MarketDataService` + `IngestRequest`/`IngestResult`/`IngestAck`/`IngestReject`/`RejectCode` | `grep -c "IngestRequest\|IngestResult\|RejectCode" module/contracts/SPEC.md` ≥ 10 | ✅ |
| G0-2 | `module/domain-market` 已定义 `ProductLine`(4值)/`InstrumentKey`(12维)/`MarketFactEnvelope`(canonical wrapper) | `grep -c "ProductLine\|InstrumentKey\|MarketFactEnvelope" module/domain-market/SPEC.md` ≥ 15 | ✅ |
| G0-3 | `module/market-data` downstream dispatch port SPEC 已发布 + binance reject 映射规则已文档化 | `ls module/market-data/SPEC.md` + `grep -c "binance.*reject\|RejectCode" module/market-data/SPEC.md` ≥ 5 | ✅ |
| G0-4 | `module/binance` OQ-001（contracts wire 就绪？）已闭合 | SPEC §22 OQ-001 状态为已确认 | ✅ |
| G0-5 | `module/binance` OQ-002（market-data dispatch port 就绪？）已闭合 | SPEC §22 OQ-002 状态为已确认 | ✅ |
| G0-6 | BOUNDARY-GATES.md 全部 9 门禁有可执行 CI 脚本 | `grep -c "Suggested check:" module/binance/BOUNDARY-GATES.md` ≥ 7 | ✅ |

> **6/6 通过** — 上游契约链闭合，binance 可从 Draft 推进到运行时实现。PR-004（domain-market dependency）和 PR-005（contracts dependency）的 docs baseline 已就绪，后续 PR 只需引用已稳定的 SPEC 定义。

## 3. Recommended PR Sequence

```text
PR-000 Remove binance-market
PR-001 module/binance root
PR-002 module/binance/client
PR-003 module/binance/server
PR-004 domain-market dependency
PR-005 contracts dependency
PR-006 transportx dependency
PR-007 runtime implementation
```

## 4. PR-000 Remove binance-market

Scope:

- remove `binance-market` from active architecture/status
- remove old Provider references
- remove `docs/services/binance-market-client-svc.md`
- add migration note outside this module
- add no-legacy gate

Acceptance:

- no active doc says `binance-market` is current
- new Binance work points to `module/binance/client` and `module/binance/server`

## 5. PR-001 Root Module

Scope:

- add `module/binance/goal.md`
- add root `README.md`
- add root `SPEC.md`
- add root `TRACEABILITY.md`
- add root `BOUNDARY-GATES.md`
- add root `RUNTIME-MAPPING.md`
- add root `IMPLEMENTATION-PLAN.md`

Acceptance:

- root doc defines client/server split
- no storage/query/strategy ownership appears in root
- no legacy Provider path remains

## 6. PR-002 Client Docs

Scope:

- add client README/SPEC/TRACEABILITY/PLAN
- add 12 client tasks
- define product-line catalog
- define parser/mapping/spool/checkpoint/sender/admin

Acceptance:

- each client task has A/C
- client does not implement server behavior
- checkpoint depends on server ACK

## 7. PR-003 Server Docs

Scope:

- add server README/SPEC/TRACEABILITY/PLAN
- add 8 server tasks
- define ingest service implementation
- define validation/idempotency/ACK/dispatch/admin

Acceptance:

- server owns Binance-specific ingest acceptance
- server does not connect to Binance exchange endpoints
- server does not own physical storage/query/strategy

## 8. PR-004 domain-market Dependency

Required external concepts:

- `InstrumentKey`
- `ProductLine`
- `InstrumentType`
- `OptionType`
- `PriceKind`
- `MarketScope`
- `MarketFactEnvelope`
- `decision_time`

> **Docs baseline**: 以上全部类型已在 `module/domain-market/SPEC.md` v1.0.1 §10 中定义（ProductLine=4 值枚举, InstrumentKey=12 字段, MarketFactEnvelope=canonical wrapper with time semantics）。运行时实现时直接 import domain-market Go 类型，不需要在 binance 侧重新定义。

Acceptance from Binance perspective:

- Spot/Futures/Options identity collisions are impossible
- proto/domain mapping can be tested
- old event envelopes have a compatibility path if needed

## 9. PR-005 contracts Dependency

Required external protocol:

- `MarketDataService`
- `IngestRequest`
- `IngestAck`
- `IngestReject`
- canonical event envelope wire representation
- enum compatibility policy

> **Docs baseline**: 以上全部接口和 DTO 已在 `module/contracts/SPEC.md` v1.2.0 §8.4 中定义（MarketDataService Go 接口 + IngestRequest(12字段)/IngestResult/IngestAck/IngestReject + RejectCode(9码) + 跨层命名映射表）。运行时 proto 编译与 gRPC code generation 待后续阶段执行。

Acceptance from Binance perspective:

- client can generate gRPC sender
- server can implement gRPC receiver
- ACK/reject semantics are testable

## 10. PR-006 transportx Dependency

Required external policies:

- gRPC streaming policy
- retry/backoff defaults
- Gin admin conventions
- health/readiness conventions
- auth/TLS recommendations

## 11. PR-007 Runtime Implementation

Recommended runtime layout:

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

Implementation order:

1. generated contracts integration
2. domain type mapping
3. server mock and contract tests
4. client catalog/parser
5. connectors
6. mapper
7. spool/checkpoint
8. gRPC sender
9. real server ingest
10. validation/idempotency/ACK
11. downstream dispatch
12. admin/observability
13. integration tests
14. boundary gates in CI

## 12. Done Definition

v1.0.0 is done when:

- docs compile as a coherent module
- all tasks have acceptance criteria
- client/server boundaries are enforced
- server ACK can drive client checkpoint
- duplicate idempotency keys are accepted once
- no `binance-market` active reference exists
- integration test demonstrates client → server → downstream port flow
