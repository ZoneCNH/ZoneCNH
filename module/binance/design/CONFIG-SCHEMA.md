# Binance Config Schema

- Last-Updated: 2026-07-08
- Source-SPEC: `module/binance/spec/SPEC.md` v4.1.0 §11
- Runtime examples: `/home/workspace/binance/configs/binance-client.env.example`, `/home/workspace/binance/configs/binance-server.env.example`

## Rule

This file owns detailed parameter tables so the root SPEC remains compact. Runtime examples must project this schema without adding secrets or production-only assumptions.

## Shared

| Env | Required | Default | Notes |
| --- | --- | --- | --- |
| `BINANCE_LOG_LEVEL` | no | `info` | structured logs |
| `BINANCE_ENV` | no | `local` | `local`, `staging`, `prod` |
| `BINANCE_NATS_URL` | yes | `nats://localhost:4222` | shared bus |
| `BINANCE_NATS_STREAM` | no | `BINANCE_MARKET` | market stream |
| `BINANCE_SUBJECT_VERSION` | no | `v1` | must produce `.v1` subjects |

## Client

| Env | Required | Default | Notes |
| --- | --- | --- | --- |
| `BINANCE_PRODUCT_LINES` | yes | `spot` | comma-separated allowed product lines |
| `BINANCE_SYMBOLS` | yes | none | explicit symbol allowlist |
| `BINANCE_WS_BASE_URL` | yes | Binance public WS URL | public market stream only |
| `BINANCE_RECONNECT_MIN_BACKOFF` | no | `1s` | reconnect lower bound |
| `BINANCE_RECONNECT_MAX_BACKOFF` | no | `30s` | reconnect upper bound |

## Server

| Env | Required | Default | Notes |
| --- | --- | --- | --- |
| `BINANCE_HTTP_ADDR` | no | `:8080` | REST/admin bind address |
| `BINANCE_CLICKHOUSE_DSN` | yes | none | ClickHouse target |
| `BINANCE_CONSUMER_DURABLE` | no | `binance-server` | JetStream durable |
| `BINANCE_ENABLE_INGEST_SMOKE` | no | `false` | enables local `/ingest`; production must keep false |
| `BINANCE_QUERY_LIMIT_DEFAULT` | no | `1000` | REST query default |
| `BINANCE_QUERY_LIMIT_MAX` | no | `10000` | REST query hard cap |

## Security

| Env | Required | Default | Notes |
| --- | --- | --- | --- |
| `BINANCE_ADMIN_AUTH_ENABLED` | prod yes | `false` | required before production closeability |
| `BINANCE_MTLS_ENABLED` | prod yes | `false` | required before production closeability |
| `BINANCE_SECRET_PROVIDER` | prod yes | none | local files are not production evidence |

## Validation

```bash
cd /home/workspace/binance
bash -n scripts/spec-runtime-drift-check.sh
scripts/spec-runtime-drift-check.sh
go test ./...
```
