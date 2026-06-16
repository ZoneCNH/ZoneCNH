# module/binance

`module/binance` is the Binance-specific Market Data C/S Module for ZoneCNH.

It is split into two submodules:

```text
module/binance/client
module/binance/server
```

## Role

`module/binance` owns Binance-specific market-data ingestion into ZoneCNH.

It does not define the canonical market domain itself. Canonical semantics are owned by `module/domain-market`.

It does not define the wire protocol itself. Wire contracts are owned by `module/contracts`.

It does not own downstream storage, query, or generic fanout. Those are owned by `module/market-data` and downstream modules.

## Submodules

| Submodule | Role |
|---|---|
| `module/binance/client` | Connects to Binance, parses exchange-native data, maps to canonical events, spools, checkpoints, sends over gRPC |
| `module/binance/server` | Implements Binance ingest server, validates events, performs idempotent acceptance, ACKs, dispatches downstream |

## Removed Legacy Module

`binance-market` is removed.

New Binance market-data ingestion work must not target:

```text
module/binance-market
github.com/ZoneCNH/binance-market
```

## Runtime Shape

Recommended runtime repository shape:

```text
github.com/ZoneCNH/binance/
  cmd/
    binance-client/
    binance-server/
  internal/
    client/
    server/
  pkg/
    config/
    observability/
```

## Read Next

- `SPEC.md`
- `BOUNDARY-GATES.md`
- `RUNTIME-MAPPING.md`
- `client/SPEC.md`
- `server/SPEC.md`
