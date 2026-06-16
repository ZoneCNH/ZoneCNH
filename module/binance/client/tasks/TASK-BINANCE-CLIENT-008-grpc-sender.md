# TASK-BINANCE-CLIENT-008 gRPC Sender

## Objective

Send canonical events from client to server through contracts-defined gRPC streaming.

## Scope

Implement the client side of `MarketDataService.Ingest`.

## Deliverables

- gRPC sender
- stream lifecycle management
- reconnect/retry behavior
- ACK/reject handling
- sender tests with mock server

## Acceptance Criteria

- sender uses generated contracts client.
- sender does not import server internals.
- sender supports bidirectional streaming ACK when available.
- sender can resume from spool after reconnect.
- sender does not advance checkpoint before server durable ACK.
- reject responses are classified as retryable or terminal.

## Dependencies

- CLIENT-007 mapper
- CLIENT-009 spool/checkpoint
- SERVER-001/SERVER-004 contract semantics
