# module/binance/client IMPLEMENTATION PLAN

## Phase 1: Contract and Domain Integration

- consume generated contracts
- consume `domain-market` semantic types
- define mapping adapters without owning canonical semantics

## Phase 2: Catalog and Parser

- implement product-line catalog loader
- implement symbol parser
- validate identity collision cases

## Phase 3: Connectors

- implement Spot connector
- implement USDⓈ-M connector
- implement COIN-M connector
- implement Options connector
- normalize raw events into internal event model

## Phase 4: Mapping

- map normalized events to canonical market envelopes
- generate idempotency keys
- add fixtures for each product line

## Phase 5: Spool and Checkpoint

- implement SQLite spool
- implement checkpoint store
- enforce ACK-based checkpoint advancement

## Phase 6: gRPC Sender

- implement streaming sender
- handle ACK/reject
- retry/reconnect from spool

## Phase 7: Admin and Observability

- implement `/healthz`
- implement `/readyz`
- implement `/debug/*`
- implement safe `/admin/*`
- add metrics/logging/tracing dimensions

## Phase 8: Tests and Gates

- connector tests
- parser tests
- mapper tests
- spool tests
- checkpoint tests
- contract tests
- boundary gates

## Dependencies / DAG

Task references are the execution handles for the client slice:

| Task ref | Depends on | Dependency rationale |
|----------|------------|----------------------|
| TASK-BINANCE-CLIENT-001 | — | Product-line catalog is the base identity input for parsers and connectors. |
| TASK-BINANCE-CLIENT-002 | TASK-BINANCE-CLIENT-001 | Instrument parsing requires the catalog vocabulary. |
| TASK-BINANCE-CLIENT-003 | TASK-BINANCE-CLIENT-001, TASK-BINANCE-CLIENT-002 | Spot connector requires product-line and instrument parsing. |
| TASK-BINANCE-CLIENT-004 | TASK-BINANCE-CLIENT-001, TASK-BINANCE-CLIENT-002 | USDⓈ-M connector requires product-line and instrument parsing. |
| TASK-BINANCE-CLIENT-005 | TASK-BINANCE-CLIENT-001, TASK-BINANCE-CLIENT-002 | COIN-M connector requires product-line and instrument parsing. |
| TASK-BINANCE-CLIENT-006 | TASK-BINANCE-CLIENT-001, TASK-BINANCE-CLIENT-002 | Options connector requires product-line and instrument parsing. |
| TASK-BINANCE-CLIENT-007 | TASK-BINANCE-CLIENT-003, TASK-BINANCE-CLIENT-004, TASK-BINANCE-CLIENT-005, TASK-BINANCE-CLIENT-006 | Canonical mapping starts after raw product-line event shapes are known. |
| TASK-BINANCE-CLIENT-008 | TASK-BINANCE-CLIENT-007 | gRPC sender sends canonical envelopes and ACK metadata. |
| TASK-BINANCE-CLIENT-009 | TASK-BINANCE-CLIENT-008 | Spool/checkpoint behavior depends on sender ACK semantics. |
| TASK-BINANCE-CLIENT-010 | TASK-BINANCE-CLIENT-009 | Admin readiness and debug surfaces need spool/checkpoint state. |
| TASK-BINANCE-CLIENT-011 | TASK-BINANCE-CLIENT-008, TASK-BINANCE-CLIENT-009 | Contract tests validate sender plus checkpoint semantics together. |
| TASK-BINANCE-CLIENT-012 | TASK-BINANCE-CLIENT-010, TASK-BINANCE-CLIENT-011 | Boundary gates close after admin and contract behavior are visible. |
| TASK-BINANCE-CLIENT-013 | TASK-BINANCE-CLIENT-007, TASK-BINANCE-CLIENT-008 | Contract binding readiness depends on canonical mapping and sender DTO shape. |

DAG summary: `TASK-BINANCE-CLIENT-001 -> TASK-BINANCE-CLIENT-002 -> {TASK-BINANCE-CLIENT-003,TASK-BINANCE-CLIENT-004,TASK-BINANCE-CLIENT-005,TASK-BINANCE-CLIENT-006} -> TASK-BINANCE-CLIENT-007 -> TASK-BINANCE-CLIENT-008 -> TASK-BINANCE-CLIENT-009 -> {TASK-BINANCE-CLIENT-010,TASK-BINANCE-CLIENT-011,TASK-BINANCE-CLIENT-013} -> TASK-BINANCE-CLIENT-012`.

## Validation Commands

Client plan and task validation:

```bash
python3 scripts/rule-scorer.py plan binance/client --out /tmp/binance-client-plan-score.json
python3 scripts/rule-scorer.py tasks binance/client --out /tmp/binance-client-tasks-score.json
bash .github/ci/task-spec-validate.sh
go test ./module/binance/client/...
```

The `go test` command is the runtime target once the implementation repo/package exists; this docs baseline validates structure with the scorer and task-spec CI.

## Risks

- Binance product-line event schemas can drift independently across Spot, USDⓈ-M, COIN-M, and Options.
- Checkpoint advancement can become unsafe if tests mock ACKs without durable acceptance semantics.
- Secret redaction can regress when admin/debug payloads include connector configuration.
- Contract DTO changes in `module/contracts` can invalidate sender and mapper assumptions.

## Rollback

- Docs-only rollback: revert the client task or plan commit and rerun the scorer plus task-spec validator.
- Runtime rollback: stop the client process, preserve SQLite spool/checkpoint files, and replay only records without durable ACK.
- Connector rollback: disable the affected product line in configuration while keeping other product lines active.
- Contract rollback: pin generated contract bindings to the last compatible version and open a follow-up task before re-enabling sender changes.
