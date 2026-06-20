# module/binance/client

`module/binance/client` is the Binance exchange-facing collector.

It connects to Binance market_data endpoints, converts exchange-native events into canonical ZoneCNH market events, persists local delivery state, and sends events to `module/binance/server`.

## Owns

- product-line catalog
- Binance symbol parsing
- Binance REST/WebSocket adapters
- raw event normalization
- raw-to-canonical mapping
- idempotency key generation
- SQLite spool
- checkpoint
- gRPC sender
- client Gin admin endpoints

## Does Not Own

- gRPC ingest server implementation
- server-side idempotent acceptance
- durable server ACK
- downstream dispatch
- storage/query/strategy
- canonical domain type definitions
- proto definitions
- `binance-market`

## Sends To

```text
module/binance/server
```

over contracts-defined gRPC.

## Delivery Contract

The client provides at-least-once delivery.

It advances checkpoint only after durable ACK from server.
