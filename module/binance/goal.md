# module/binance GOAL

## Purpose

`module/binance` defines the Binance-specific market-data ingest module for ZoneCNH.

It replaces the previous ambiguous split between a passive `binance` SDK and a separate `binance-market` Provider with a single explicit C/S architecture:

```text
module/binance/client
module/binance/server
```

## Primary Goal

Provide a reliable, canonical, Binance-specific market-data ingestion path for:

- Spot
- USDⓈ-M Futures
- COIN-M Futures
- Options

## Non-Goals

`module/binance` does not own:

- generic market-data domain semantics
- cross-exchange market-data ingestion policy
- market-data storage engine
- query APIs
- strategy APIs
- trading decisions
- order execution
- portfolio accounting
- risk management
- legacy `binance-market` compatibility

## Success Criteria

`module/binance` is successful when:

1. Binance market data can be collected by `module/binance/client`.
2. Canonical market events can be transmitted through contracts-defined gRPC.
3. `module/binance/server` can validate, deduplicate, acknowledge, and dispatch accepted events.
4. Spot `BTCUSDT`, USDⓈ-M `BTCUSDT`, COIN-M `BTCUSD`, and Options contracts produce non-colliding canonical instrument identities.
5. Client checkpoints advance only after durable server ACK.
6. No code or documentation reintroduces `binance-market`.
7. Client/server internals remain separated by boundary gates.
