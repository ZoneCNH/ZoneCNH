# module/market-data

`module/market-data` defines the exchange-neutral downstream market-data receiving contract.

It receives validated `domain-market` market facts from exchange-specific ingest servers such as `module/binance/server`. It owns the receiver-side dispatch port and the durable handoff contract used before upstream servers emit durable ACKs.

## Read Next

- `SPEC.md` (v1.0.0) — DownstreamDispatchPort + 12 input fields + 8 reject reasons + §4.4.1 binance reject mapping
- `TRACEABILITY.md` — FR-MD-001~008, BR-MD-001~006, TC-MD-001~006
- `IMPLEMENTATION-PLAN.md` — PR sequence PR-000 through PR-006
- `tasks/TASK-MARKET-DATA-001-downstream-dispatch-port.md`
- `tasks/TASK-MARKET-DATA-002-receiver-spec.md`
