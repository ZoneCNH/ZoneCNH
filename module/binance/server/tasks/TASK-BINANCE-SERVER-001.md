---
task_id: TASK-BINANCE-SERVER-001
related_requirements:
  - FR-001
  - FR-002
scope: >
  The server accepts gRPC ingest streams from `module/binance/client`.
acceptance_criteria:
  - "server implements generated gRPC interface."
  - "server accepts `IngestRequest` stream."
  - "server returns `IngestAck` stream."
  - "server records stream id and metadata."
  - "server does not import client internals."
  - "server does not connect to Binance exchange endpoints."
---
# TASK-BINANCE-SERVER-001 gRPC Ingest Server

## Objective

Implement the Binance-specific server side of the contracts-defined `MarketDataService`.

## Scope

The server accepts gRPC ingest streams from `module/binance/client`.


## Non-scope

- Does not change behavior outside `module/binance/server`.
- Does not import or modify client internals.

## Deliverables

- gRPC server skeleton
- stream lifecycle handler
- request receive loop
- graceful shutdown behavior
- stream tests

## Acceptance Criteria

- server implements generated gRPC interface.
- server accepts `IngestRequest` stream.
- server returns `IngestAck` stream.
- server records stream id and metadata.
- server does not import client internals.
- server does not connect to Binance exchange endpoints.

## Dependencies

- `module/contracts`
