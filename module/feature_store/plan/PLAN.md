# module/feature_store IMPLEMENTATION PLAN

## 1. Goal

Deliver `module/feature_store` v1.0.0 as the analysis-domain feature storage with PIT queries and lineage tracking.

## 2. Current State

- Docs baseline published (v1.0.0-spec): FeatureStore interface, PIT query, version management, lineage tracking, 7 FRs, 4 BRs, 4 NFRs
- SPEC.md: Draft → Docs Baseline Approved / Runtime Pending (2026-06-17)
- goal.md: present
- TRACEABILITY.md / IMPLEMENTATION-PLAN.md: this PR
- Runtime: Pending
- Upstream: factor_engine SPEC v1.0.0 (Docs Baseline Approved)

## 3. PR Sequence

```text
PR-000 module/feature_store root docs (this PR)               ← DONE
PR-001 runtime: FeatureStore interface + write path
PR-002 runtime: version management + PIT query
PR-003 runtime: lineage tracking
PR-004 runtime: TTL + GC
PR-005 runtime: batch query + feature matrix
PR-006 runtime: storage backend adapter (postgresx)
PR-007 runtime: observability + integration tests
```

## 4. PR-000 Root Docs

Scope: SPEC.md status promotion (Draft → Docs Baseline Approved), IMPLEMENTATION-PLAN.md, TRACEABILITY.md creation.

Acceptance:
- [x] SPEC.md status promoted
- [x] Upstream caveat updated (factor_engine v1.0.0)
- [x] IMPLEMENTATION-PLAN.md created (this file)

## 5. PR-001 Write Path

Scope: FeatureStore.Write() with idempotent semantics.

Acceptance:
- FactorOutput accepted and persisted
- Duplicate (same factor_name + instrument_key + timestamp) returns existing version
- Write latency < 1ms (NFR-001)

## 6. PR-002 Version Management + PIT Query

Scope: Monotonic versioning, GetFeaturesAt() point-in-time correct query.

Acceptance:
- New values create monotonically increasing version numbers
- Old versions preserved, not overwritten
- PIT query returns only features with timestamp <= query time
- No future data leakage (BR-001)

## 7. PR-003 Lineage Tracking

Scope: GetLineage() with full provenance chain.

Acceptance:
- Lineage records source factor, input data range, factor version, compute time
- GetLineage returns complete chain for given factor_name + instrument_key

## 8. PR-004 TTL + GC

Scope: Time-to-live expiration and async garbage collection.

Acceptance:
- Expired features excluded from PIT queries
- GC runs async, non-blocking
- GC batch size and interval configurable

## 9. PR-005 Batch Query + Feature Matrix

Scope: GetFeatureMatrix() for multi-instrument queries.

Acceptance:
- Matrix query returns values for all requested instruments
- Missing values are NaN (not zero-filled)
- Matrix query latency < 100ms for 100×50 matrix (NFR-003)

## 10. PR-006 Storage Backend Adapter

Scope: postgresx storage backend with clean adapter interface.

Acceptance:
- Read/write through postgresx adapter
- Schema migrations managed separately
- Backend swappable via config (postgresx | taosx | clickhousex)

## 11. PR-007 Observability + Integration Tests

Scope: Metrics, end-to-end tests, race detection.

Acceptance:
- Metrics: write_latency, query_latency, gc_duration, expired_count
- Integration test: factor_engine → feature_store → factor_eval (mock) chain
- Coverage >= 80%
- Race detector clean

## 12. DoD

- [ ] FeatureStore.Write() idempotent
- [ ] PIT query no lookahead
- [ ] Lineage chain complete
- [ ] TTL + GC non-blocking
- [ ] Feature matrix with NaN fill
- [ ] Postgresx adapter
- [ ] Coverage >= 80%

## Task Reference

| Task | Scope | Effort |
|------|-------|--------|
| TASK-FS-001-core-implementation | Implementation | 2h |
