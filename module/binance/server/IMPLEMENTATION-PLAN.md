# module/binance/server IMPLEMENTATION PLAN

## Phase 1: Contract Server Skeleton

- consume generated gRPC server interface
- implement stream handler shell
- add contract fixtures

## Phase 2: Validation

- validate envelope fields
- validate domain enum mapping
- validate payload shape
- classify reject reasons

## Phase 3: Idempotency

- implement idempotency store interface
- implement duplicate detection
- implement conflict detection
- test retry behavior

## Phase 4: ACK / Reject

- implement ACK generation
- implement reject response generation
- define stream-level and event-level response behavior
- test checkpoint-driving ACK semantics

## Phase 5: Downstream Dispatch

- implement downstream market-data port adapter
- dispatch accepted events
- ensure duplicate accepted events do not duplicate dispatch

## Phase 6: Admin and Observability

- implement `/healthz`
- implement `/readyz`
- implement `/debug/*`
- implement safe `/admin/*`
- expose metrics/logging/tracing dimensions

## Phase 7: Contract and Integration Tests

- contract tests with client
- duplicate/retry tests
- stream reconnect tests
- downstream dispatch tests

## Phase 8: Boundary Gates

- no client internal imports
- no `binance-market`
- no storage/query/strategy ownership
- no local proto ownership

## Dependencies / DAG

Task references are the execution handles for the server slice:

| Task ref | Depends on | Dependency rationale |
|----------|------------|----------------------|
| TASK-BINANCE-SERVER-001 | — | gRPC ingest skeleton is the entry point for all server behavior. |
| TASK-BINANCE-SERVER-002 | TASK-BINANCE-SERVER-001 | Validation requires the request stream and generated DTOs. |
| TASK-BINANCE-SERVER-003 | TASK-BINANCE-SERVER-002 | Idempotent acceptance depends on validated event identity. |
| TASK-BINANCE-SERVER-004 | TASK-BINANCE-SERVER-003 | ACK/reject semantics depend on idempotent acceptance outcomes. |
| TASK-BINANCE-SERVER-005 | TASK-BINANCE-SERVER-004 | Downstream dispatch happens only after durable accepted ACK semantics are defined. |
| TASK-BINANCE-SERVER-006 | TASK-BINANCE-SERVER-005 | Admin readiness/debug surfaces need ingest, idempotency, and dispatch state. |
| TASK-BINANCE-SERVER-007 | TASK-BINANCE-SERVER-004, TASK-BINANCE-SERVER-005 | Contract tests validate ACK/reject plus downstream side effects. |
| TASK-BINANCE-SERVER-008 | TASK-BINANCE-SERVER-006, TASK-BINANCE-SERVER-007 | Boundary gates close after admin and contract behavior are visible. |
| TASK-BINANCE-SERVER-009 | TASK-BINANCE-SERVER-001, TASK-BINANCE-SERVER-005 | Dispatch binding readiness depends on generated ingest server and downstream port shape. |

DAG summary: `TASK-BINANCE-SERVER-001 -> TASK-BINANCE-SERVER-002 -> TASK-BINANCE-SERVER-003 -> TASK-BINANCE-SERVER-004 -> TASK-BINANCE-SERVER-005 -> {TASK-BINANCE-SERVER-006,TASK-BINANCE-SERVER-007,TASK-BINANCE-SERVER-009} -> TASK-BINANCE-SERVER-008`.

## Validation Commands

Server plan and task validation:

```bash
python3 scripts/rule-scorer.py plan binance/server --out /tmp/binance-server-plan-score.json
python3 scripts/rule-scorer.py tasks binance/server --out /tmp/binance-server-tasks-score.json
bash .github/ci/task-spec-validate.sh
go test ./module/binance/server/...
```

The `go test` command is the runtime target once the implementation repo/package exists; this docs baseline validates structure with the scorer and task-spec CI.

## Risks

- Duplicate detection can accidentally ACK conflicting payloads if idempotency keys are under-specified.
- Downstream dispatch can create duplicate side effects if ACK and dispatch ordering are not tested together.
- Admin/debug output can leak stream metadata or secrets when troubleshooting ingest failures.
- Contract DTO changes in `module/contracts` can invalidate generated server bindings.

## Rollback

- Docs-only rollback: revert the server task or plan commit and rerun the scorer plus task-spec validator.
- Runtime rollback: stop the server process, keep idempotency state intact, and restart from the last compatible binary.
- Dispatch rollback: disable downstream forwarding while continuing to reject or buffer new ingest events explicitly.
- Contract rollback: pin generated server bindings to the last compatible version and open a follow-up task before re-enabling ingest changes.
