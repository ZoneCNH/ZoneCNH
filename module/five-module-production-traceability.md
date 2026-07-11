# Five-module production traceability

- Status: Active for Wave 0 / Wave 1
- ADR: module/ADR-five-module-production-pipeline-v1.md
- Machine baseline: module/five-module-production-baseline.yaml

| Requirement | contracts | domain_market | binance | market_data | market_regime | Release gate |
| --- | --- | --- | --- | --- | --- | --- |
| HTTP/Gin handoff | endpoint/DTO | canonical values | HTTP client | Gin server | N/A | contract-conformance |
| durable submission | receipt scope | stable identity | local outbox | capture transaction | N/A | false-durable-ack |
| idempotency conflict | 409/error DTO | canonical hash inputs | quarantine | capture identity | N/A | same-key-different-hash |
| ordering | sequence fields | pure sequence values | source sequence | watermark/reorder | event-time reorder | sequence-gap |
| final Bar | BarState wire | BarState invariant | map exchange x | persist state | final-only | final-bar-only |
| quality | flags wire | valid combinations | source flags | quality gate | freshness axis | data-quality |
| replay | event schemas | deterministic values | outbox/history | capture/projector | deterministic snapshot | replay-determinism |
| no-lookahead | available_at | time invariants | preserve source time | query PIT | reject future input | no-lookahead |
| projection | event contracts | N/A | N/A | outbox/projectors | consume accepted | projection-reconcile |
| decision boundary | snapshot vs decision | N/A | N/A | N/A | no TradePermission | boundary-gate |

## Current external blockers

- GitHub application can create branches in ZoneCNH/ZoneCNH.
- The same integration returned HTTP 403 for branch creation in xhyperium/contracts and xhyperium/domain_market.
- No attempt may bypass repository authorization.
- Runtime implementation remains blocked until xhyperium write access is granted or maintainers create target branches.

## Required Evidence

Each row must link spec → code → test → CI gate → evidence artifact → release verdict. A documentation status cannot be translated into runtime completion.
