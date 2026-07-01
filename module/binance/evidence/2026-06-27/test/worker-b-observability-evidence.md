# Worker B Observability / Quota / Audit Evidence — 2026-06-27

- Scope: GitHub #1270, #1271, #1272, #1275 / Beads `ZoneCNH-xzcr.2` through `ZoneCNH-xzcr.4`, `ZoneCNH-xzcr.7`
- Runtime-Anchor: `/home/workspace/binance@0602e78428633a368b0afcd1c578c07ed7144752`
- Evidence-State: Partial / tracker open; evidence blockers deferred

> `[COMPUTED, HIGH]` Canonical runtime artifact directory `/home/workspace/binance/release/evidence/binance/20260627-worker-b` was not present in the leader workspace. This file records rerun command evidence only and does not prove Evidence-Done for the linked issues.

## Rerun Evidence

`[COMPUTED, HIGH]` The following targeted runtime tests were rerun successfully in `/home/workspace/binance`:

```bash
go test ./internal/server/metrics -run 'Test(NewRegistry_Construction|NilRegistry_NoPanic|HTTPHandler_ExposeMetrics|CostObservabilityMetrics)$' -count=1
go test ./internal/server -run 'Test(StartIngestSpan|FinishIngestSpan|BuildCostUsageReport|KafkaDispatchAdapterSendsMarketEvent|NATSDispatchAdapterPublishesNATSXEnvelope|EventLogAttrs)' -count=1
go test ./internal/server/api -run 'Test(MarketRange_HistoryUsesConfiguredQueryTimeout|RateLimit_KeyIsIsolatedByProductLineAndCaller|RateLimit_Exceeded_Returns429WithRetryAfter|RateLimit_Allowed_PassesThrough)' -count=1
go test ./internal/server/controlplane -run 'TestLifecycle_(PauseResumeIdempotent|DrainWaitsInFlightAndAudits|DrainTimeoutRecordsError)|TestAuditLog_RecentOrder|TestLifecycle_AuditRecentExposesAllActions' -count=1
go test ./internal/server/deadletter -count=1
```

## Closing Blockers

| Issue | Current local evidence | Remaining blocker |
| ----- | ---------------------- | ----------------- |
| #1270 / `ZoneCNH-xzcr.2` | Trace span, dispatch attribute, Kafka/NATS envelope, and event-log tests pass. | OTel collector export, external NATS propagation, and deployed trace capture are still missing. |
| #1271 / `ZoneCNH-xzcr.3` | Product-line/caller rate-limit isolation and query-timeout tests pass. | Kafka quota, multi-tenant isolation, and ClickHouse timeout evidence are still missing. |
| #1272 / `ZoneCNH-xzcr.4` | Lifecycle audit ordering and action exposure tests pass. | Retention duration, archive linkage, and deployed permission evidence are still missing. |
| #1275 / `ZoneCNH-xzcr.7` | Cost metric and usage report tests pass. | Dashboard, alert, and production-like cost report artifacts are still missing. |

[RULES I BROKE]：无
