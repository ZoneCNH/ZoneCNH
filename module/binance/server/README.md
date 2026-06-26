# module/binance/server

`module/binance/server` is the Binance-specific ingest acceptance server.

It consumes Binance market data envelopes from `natsx` JetStream, validates and deduplicates them, persists Binance-owned data, exposes query APIs, and fans out accepted events through `kafkax`.

## Owns

- NATS JetStream consumer lifecycle
- `domain_market.MarketFactEnvelope` validation
- event validation
- server-side idempotent acceptance
- ManualAck / reject decisions
- durable acceptance boundary
- Binance-specific storage adapters
- Binance-specific query APIs
- `kafkax` fanout
- server Gin admin endpoints
- Storage assembly wiring ([PERSISTENCE-WIRING.md](PERSISTENCE-WIRING.md))
- REST API endpoints ([ENDPOINTS.md](ENDPOINTS.md))
- Deployment & operations ([OPERATIONS.md](OPERATIONS.md))
- Data lifecycle management ([DATA-LIFECYCLE.md](DATA-LIFECYCLE.md))
- Data quality SLA ([DATA-QUALITY-SLA.md](DATA-QUALITY-SLA.md))

## Does Not Own

- Binance exchange connectivity
- REST/WebSocket connectors
- client-side publish evidence
- client-side PubAck handling
- canonical domain type definitions
- local proto definitions
- gRPC / proto ingest contracts
- generic physical storage engine
- generic cross-exchange query APIs
- strategy APIs
- `binance-market`

## Receives From

```text
module/binance/client
```

through `natsx` JetStream.

## Publishes / Serves To

```text
taosx / postgresx / redisx / ossx
kafkax
Gin REST query/admin APIs
```

The server owns Binance-specific persistence and fanout, but not generic market_data or strategy semantics.
