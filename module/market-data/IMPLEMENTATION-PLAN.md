# module/market-data IMPLEMENTATION PLAN

## 1. Goal

Deliver `module/market-data` v1.0.0 as the exchange-neutral downstream dispatch receiving module.

## 2. Current State

- Docs baseline published (v0.1.0): DownstreamDispatchPort semantics, AcceptedMarketEvent contract, FR-MD-001~008
- Runtime: Pending
- Upstream dependencies: module/domain-market canonical types, module/contracts wire contract

## 3. PR Sequence

```text
PR-000 module/market-data root docs (this PR)
PR-001 runtime: dispatch port interface + no-op implementation
PR-002 runtime: idempotency store
PR-003 runtime: quality gate
PR-004 runtime: ordering enforcement
PR-005 runtime: observability metrics
PR-006 runtime: contract tests + integration tests
```

## 4. PR-000 Root Docs

Scope: Create module/market-data/ with SPEC.md, TRACEABILITY.md, goal.md, IMPLEMENTATION-PLAN.md.

Acceptance:
- SPEC.md follows 23-section format
- TRACEABILITY.md has all FR/BR/NFR/TC/AC with closed traceability chains
- Adapter Gate: module/binance SPEC references this dispatch port
- No runtime code introduced

## 5. Runtime Gate

Runtime implementation starts when:
- module/domain-market provides approved, consumable ProductLine/InstrumentKey/MarketFactEnvelope types
- module/contracts provides approved, consumable IngestRequest/IngestResult types
- module/binance server is ready to integrate with dispatch port

## 6. DoD

- [ ] All FR-MD-001~008 implemented and tested
- [ ] Idempotency: duplicate key → deterministic outcome
- [ ] Ordering: sequence gap/reversal detected
- [ ] Quality gate: stale/future/dirty → fail-closed
- [ ] Observability: metrics by venue/productLine/channel/outcome/reason
- [ ] Contract tests pass
- [ ] Coverage >= 80%
