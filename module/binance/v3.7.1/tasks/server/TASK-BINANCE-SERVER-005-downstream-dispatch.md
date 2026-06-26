# TASK-BINANCE-SERVER-005 Downstream Dispatch

> Archived v2.0.0: this `market_data` DownstreamDispatchPort task belongs to the pre-`natsx` design. Do not use it for implementation. Use TASK-BINANCE-SERVER-012/013/014/015/016 for storage, API, and `kafkax` delivery.

Status: Archived

## Objective

Dispatch accepted Binance market events to downstream exchange-neutral market_data infrastructure.

## Scope

Dispatch starts after server-side acceptance.

## Deliverables

- downstream port interface usage
- dispatch adapter
- dispatch retry/error handling
- duplicate dispatch tests

## Acceptance Criteria

- accepted event is dispatched once.
- duplicate event is not dispatched again.
- validation reject is not dispatched.
- dispatch failures are reported.
- server does not own physical storage implementation.
- server does not expose query APIs.
- server does not call strategy APIs.

## Dependencies

- SERVER-003 idempotency
- SERVER-004 ACK semantics
- `module/market_data` downstream port
