# module/binance GOAL

## Purpose

`module/binance` defines the Binance-specific market_data ingest module for ZoneCNH.

It replaces the previous ambiguous SDK/Provider split with a single explicit C/S architecture:

```text
module/binance/client
module/binance/server
```

## Primary Goal

Provide a reliable, canonical, Binance-specific market_data ingestion path for:

- Spot
- USDⓈ-M Futures
- COIN-M Futures
- Options

## Non-Goals

`module/binance` does not own:

- generic market_data domain semantics
- cross-exchange market_data ingestion policy
- generic cross-exchange market_data storage/query ownership
- strategy APIs
- trading decisions
- order execution
- portfolio accounting
- risk management
- legacy Provider compatibility

## Success Criteria

`module/binance` is successful when:

1. Binance market data can be collected by `module/binance/client`.
2. Canonical market events can be durably published through `natsx` JetStream using `domain_market` envelopes.
3. `module/binance/server` can validate, deduplicate, persist, expose, and fan out accepted Binance events.
4. Spot `BTCUSDT`, USDⓈ-M `BTCUSDT`, COIN-M `BTCUSD`, and Options contracts produce non-colliding canonical instrument identities.
5. Client publish success is confirmed by JetStream PubAck, and server consumption advances only after durable ManualAck.
6. Archived legacy Provider names remain confined to SPEC Appendix B, BR gates, migrations, and reports.
7. Client/server internals remain separated by boundary gates.
