# module/binance RUNTIME MAPPING

## 1. Purpose

This file maps `module/binance` specifications to the recommended runtime repository structure.

Documentation path:

```text
module/binance/
```

Runtime repository:

```text
github.com/ZoneCNH/binance
```

## 2. Recommended Runtime Tree

```text
github.com/ZoneCNH/binance/
  go.mod

  cmd/
    binance-client/
      main.go
    binance-server/
      main.go

  internal/
    client/
      app/
      config/
      catalog/
      parser/
      spot/
      usdm/
      coinm/
      options/
      normalize/
      mapper/
      idempotency/
      spool/
      checkpoint/
      sender/
      admin/
      observability/

    server/
      app/
      config/
      ingest/
      validation/
      idempotency/
      ack/
      dispatch/
      admin/
      observability/

  pkg/
    config/
    observability/
    version/

  test/
    contract/
    integration/
    fixtures/
```

## 3. Command Mapping

| Command | Role |
|---|---|
| `cmd/binance-client` | runs exchange-facing client |
| `cmd/binance-server` | runs ingest acceptance server |

## 4. Client Mapping

| Spec Area | Runtime Path |
|---|---|
| product-line catalog | `internal/client/catalog` |
| symbol parser | `internal/client/parser` |
| Spot connector | `internal/client/spot` |
| USDⓈ-M connector | `internal/client/usdm` |
| COIN-M connector | `internal/client/coinm` |
| Options connector | `internal/client/options` |
| raw normalization | `internal/client/normalize` |
| canonical mapping | `internal/client/mapper` |
| idempotency key generation | `internal/client/idempotency` |
| SQLite spool | `internal/client/spool` |
| checkpoint | `internal/client/checkpoint` |
| gRPC sender | `internal/client/sender` |
| Gin admin | `internal/client/admin` |
| client app wiring | `internal/client/app` |

## 5. Server Mapping

| Spec Area | Runtime Path |
|---|---|
| gRPC ingest server | `internal/server/ingest` |
| validation | `internal/server/validation` |
| idempotent acceptance | `internal/server/idempotency` |
| ACK generation | `internal/server/ack` |
| downstream dispatch | `internal/server/dispatch` |
| Gin admin | `internal/server/admin` |
| server app wiring | `internal/server/app` |

## 6. Shared Packages

Allowed shared runtime packages:

```text
pkg/config
pkg/observability
pkg/version
```

Shared packages must not become hidden dependency channels between client and server.

## 7. Forbidden Runtime Imports

Client must not import:

```text
github.com/ZoneCNH/binance/internal/server/*
```

Server must not import:

```text
github.com/ZoneCNH/binance/internal/client/*
```

Both client and server must not import:

```text
github.com/ZoneCNH/binance-market
github.com/ZoneCNH/storage as owned dependency
github.com/ZoneCNH/strategy as owned dependency
```

## 8. Allowed External Dependencies

Allowed by role:

| Runtime Area | Allowed External Modules |
|---|---|
| client mapper | `module/domain_market`, `module/contracts` generated types |
| client sender | `module/contracts` generated gRPC client |
| server ingest | `module/contracts` generated gRPC server |
| server validation | `module/domain_market` |
| server dispatch | `module/market_data` downstream port |
| admin | `module/transportx` conventions, Gin |
| observability | approved logging/metrics/tracing libraries |

## 9. Test Mapping

| Test Type | Runtime Path | Purpose |
|---|---|---|
| connector tests | `internal/client/*/*_test.go` | validate Binance-native input handling |
| mapper tests | `internal/client/mapper` | validate canonical mapping |
| spool tests | `internal/client/spool` | validate durable local persistence |
| checkpoint tests | `internal/client/checkpoint` | validate ACK-based progression |
| server ingest tests | `internal/server/ingest` | validate gRPC lifecycle |
| idempotency tests | `internal/server/idempotency` | validate duplicate behavior |
| contract tests | `test/contract` | validate client/server proto behavior |
| integration tests | `test/integration` | validate client → server → dispatch path |

## 10. Runtime Acceptance

Runtime implementation is acceptable when:

- `cmd/binance-client` can run without server internals.
- `cmd/binance-server` can run without client internals.
- integration tests demonstrate ACK-based checkpoint.
- duplicate idempotency key does not produce duplicate downstream dispatch.
- boundary check script passes in CI.
- no `binance-market` dependency is present.
