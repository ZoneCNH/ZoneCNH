# module/binance/client

`module/binance/client` is the Binance exchange-facing collector.

It connects to Binance market_data endpoints, converts exchange-native events into `domain_market.MarketFactEnvelope` payloads, and publishes them to `module/binance/server` through `natsx` JetStream.

## Owns

- product-line catalog
- Binance symbol parsing
- Binance REST/WebSocket adapters
- raw event normalization
- raw-to-canonical mapping
- idempotency key generation
- `domain_market` envelope construction
- `natsx` publisher
- JetStream PubAck evidence
- client Gin admin endpoints

## Does Not Own

- NATS JetStream consumer implementation
- server-side idempotent acceptance
- durable server processing state
- server storage/API/fanout
- storage/query/strategy ownership
- canonical domain type definitions
- local proto definitions
- gRPC / proto ingest contracts
- `binance-market`

## Sends To

```text
module/binance/server
```

over `natsx` JetStream subjects using `domain_market` payload semantics.

## Delivery Contract

The client publishes with at-least-once delivery semantics.

It records publish evidence only after JetStream PubAck. Server acceptance, durable storage, query API visibility, and `kafkax` fanout remain server-owned concerns.
