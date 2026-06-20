# module/binance/server

`module/binance/server` is the Binance-specific ingest acceptance server.

It implements the contracts-defined `MarketDataService` for Binance market_data ingestion.

## Owns

- gRPC ingest server
- stream lifecycle
- event validation
- server-side idempotent acceptance
- ACK/reject generation
- durable acceptance boundary
- downstream dispatch
- server Gin admin endpoints

## Does Not Own

- Binance exchange connectivity
- REST/WebSocket connectors
- client-side spool
- client-side checkpoint
- canonical domain type definitions
- proto definitions
- physical storage engine
- query APIs
- strategy APIs
- `binance-market`

## Receives From

```text
module/binance/client
```

through contracts-defined gRPC.

## Dispatches To

```text
module/market_data
```

through downstream exchange-neutral market_data port.
