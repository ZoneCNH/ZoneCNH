# module/factor_engine IMPLEMENTATION PLAN

## 1. Goal

Deliver `module/factor_engine` v1.0.0 as the analysis-domain factor computation engine.

## 2. Current State

- Docs baseline published (v1.0.0-spec): Factor interface, FactorRegistry, ComputePipeline, FactorOutput DTO, 12 FRs, 5 BRs, 4 NFRs
- SPEC.md: Draft → Docs Baseline Approved / Runtime Pending (2026-06-17)
- TRACEABILITY.md / goal.md: present
- Runtime: Pending
- Upstream dependencies: market_data SPEC v1.0.0 (Approved), domain_market SPEC v1.1.0 (canonical types frozen), feature_store SPEC (Draft, output target only)

## 3. PR Sequence

```text
PR-000 module/factor_engine root docs (this PR)                  ← DONE
PR-001 runtime: Factor interface + FactorRegistry
PR-002 runtime: ComputePipeline + input validation
PR-003 runtime: built-in factors (momentum, volatility, volume)
PR-004 runtime: feature_store write adapter
PR-005 runtime: observability metrics + traces
PR-006 runtime: contract tests + integration tests
```

## 4. PR-000 Root Docs

Scope: SPEC.md status promotion (Draft → Docs Baseline Approved), IMPLEMENTATION-PLAN.md creation.

Acceptance:
- [x] SPEC.md status promoted (Draft → Docs Baseline Approved / Runtime Pending)
- [x] Upstream contract caveat removed (market_data + domain_market now stable)
- [x] IMPLEMENTATION-PLAN.md created (this file)
- [x] No runtime code introduced

## 5. PR-001 Factor Interface + Registry

Scope:
- Implement `Factor` interface
- Implement `FactorRegistry` (Register/Get/ListByTags/Names)
- Implement `ErrDuplicateFactor`

Acceptance:
- Register duplicates returns error
- Get returns (Factor, bool) correctly
- ListByTags filters by tag
- Unit tests for all registry operations

## 6. PR-002 ComputePipeline

Scope:
- Implement ComputePipeline: input validation → factor selection → parallel compute → result aggregation → output write
- Implement input validation (FR-004)
- Implement warmup management (FR-006)
- Implement parallelism control

Acceptance:
- Pipeline processes MarketEventEnvelope stream end-to-end
- Invalid input (nil, zero EventTime, unreliable quality) rejected with metric
- WarmupComplete=false until required history accumulated
- Parallelism respects config limit

## 7. PR-003 Built-in Factors

Scope:
- Implement momentum factor (price_t / price_{t-N} - 1)
- Implement volatility factor (stddev of returns over window)
- Implement volume factor (volume / avg_volume)
- Each factor implements `Factor` interface with correct Warmup()

Acceptance:
- Each factor computes correct values against known test data
- Warmup periods respected
- InputTypes declared correctly

## 8. PR-004 Feature-Store Write Adapter

Scope:
- Implement FactorOutput → feature_store write path
- Retry with exponential backoff on write failure
- Batch writes with configurable flush interval

Acceptance:
- FactorOutput correctly serialized to feature_store
- Write failure → 3 retries → alert
- Batch writes respect flush interval

## 9. PR-005 Observability

Scope:
- Metrics: compute_latency, compute_total, validation_reject_total, warmup_pending, feature_store_write_errors
- Dimensions: factor_name, product_line, instrument, outcome
- Traces: factor_name, instrument_key, pipeline_run_id
- Logging: factor lifecycle events at debug, errors at warn

Acceptance:
- Prometheus metrics exposed at /metrics
- Traces exportable to observex
- No secrets in log output

## 10. PR-006 Contract Tests + Integration

Scope:
- Contract tests: Factor interface compliance
- Integration tests: market_data event → factor_engine → feature_store → factor_eval (mock)
- Race detection: go test -race clean
- Coverage: >= 80%

Acceptance:
- All 12 FRs covered by tests
- Contract tests validate Factor interface
- Integration test demonstrates end-to-end pipeline
- Coverage report >= 80%

## 11. Runtime Gate

Runtime implementation starts when:
- [x] module/market_data SPEC Approved (v1.0.0)
- [x] module/domain_market canonical types frozen (v1.1.0)
- [ ] module/feature_store SPEC stabilized (currently Draft)
- [ ] All PR-001~PR-006 gates pass

## 12. DoD

- [ ] Factor interface fully implemented and tested
- [ ] FactorRegistry Register/Get/ListByTags all verified
- [ ] ComputePipeline input validation → parallel compute → output write tested end-to-end
- [ ] 3+ built-in factors implemented
- [ ] Warmup management correct
- [ ] Feature-store write with retry
- [ ] Observability: 5 metrics + traces
- [ ] Coverage >= 80%
- [ ] Race detector clean

## Task Reference

| Task | Scope | Effort |
|------|-------|--------|
| TASK-FE-001-core-implementation | Implementation | 2h |
