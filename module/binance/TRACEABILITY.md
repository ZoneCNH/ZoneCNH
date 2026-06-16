# module/binance TRACEABILITY

## Requirements Matrix

| Requirement ID | Requirement | Owner | Verification |
|---|---|---|---|
| BNC-ROOT-001 | Remove `binance-market` from active architecture | root | boundary gate + migration review |
| BNC-ROOT-002 | Define client/server split | root | `SPEC.md` + submodule specs |
| BNC-ROOT-003 | Assign `MarketDataService` implementation to server | root/server | server SPEC + contracts tests |
| BNC-ROOT-004 | Keep canonical semantics outside Binance | root | import/ownership review |
| BNC-ROOT-005 | Keep wire contract outside Binance | root | contracts dependency review |
| BNC-ROOT-006 | Keep storage/query/strategy outside Binance | root | boundary gate |
| BNC-CLIENT-001 | Support Spot product-line collection | client | connector tests |
| BNC-CLIENT-002 | Support USDⓈ-M product-line collection | client | connector tests |
| BNC-CLIENT-003 | Support COIN-M product-line collection | client | connector tests |
| BNC-CLIENT-004 | Support Options product-line collection | client | connector tests |
| BNC-CLIENT-005 | Generate non-colliding instrument identities | client/domain-market | mapping tests |
| BNC-CLIENT-006 | Generate idempotency keys | client/server | ingest duplicate tests |
| BNC-CLIENT-007 | Persist events to spool before send | client | spool tests |
| BNC-CLIENT-008 | Advance checkpoint only after ACK | client/server | reconnect tests |
| BNC-SERVER-001 | Implement Binance-specific ingest server | server | gRPC contract tests |
| BNC-SERVER-002 | Validate incoming event envelopes | server | validation tests |
| BNC-SERVER-003 | Perform idempotent acceptance | server | duplicate tests |
| BNC-SERVER-004 | Return ACK/reject responses | server | stream tests |
| BNC-SERVER-005 | Dispatch accepted events downstream | server/market-data | port tests |
| BNC-OPS-001 | Expose health/readiness/debug/admin endpoints | client/server | HTTP tests |
| BNC-OPS-002 | Hide secrets from logs/admin/debug output | client/server | security tests |
| BNC-OPS-003 | Provide metrics/logs/tracing dimensions | client/server | observability tests |

## Task Coverage

| Task | Requirements |
|---|---|
| CLIENT-001 | BNC-CLIENT-001, BNC-CLIENT-002, BNC-CLIENT-003, BNC-CLIENT-004 |
| CLIENT-002 | BNC-CLIENT-005 |
| CLIENT-003 | BNC-CLIENT-001 |
| CLIENT-004 | BNC-CLIENT-002 |
| CLIENT-005 | BNC-CLIENT-003 |
| CLIENT-006 | BNC-CLIENT-004 |
| CLIENT-007 | BNC-CLIENT-005, BNC-CLIENT-006 |
| CLIENT-008 | BNC-CLIENT-008, BNC-SERVER-004 |
| CLIENT-009 | BNC-CLIENT-007, BNC-CLIENT-008 |
| CLIENT-010 | BNC-OPS-001, BNC-OPS-002, BNC-OPS-003 |
| CLIENT-011 | BNC-ROOT-003, BNC-SERVER-001, BNC-SERVER-004 |
| CLIENT-012 | BNC-ROOT-001, BNC-ROOT-006 |
| SERVER-001 | BNC-SERVER-001 |
| SERVER-002 | BNC-SERVER-002 |
| SERVER-003 | BNC-SERVER-003 |
| SERVER-004 | BNC-SERVER-004, BNC-CLIENT-008 |
| SERVER-005 | BNC-SERVER-005 |
| SERVER-006 | BNC-OPS-001, BNC-OPS-002, BNC-OPS-003 |
| SERVER-007 | BNC-ROOT-003, BNC-SERVER-001, BNC-SERVER-004 |
| SERVER-008 | BNC-ROOT-001, BNC-ROOT-006 |
