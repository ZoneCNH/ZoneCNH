# Frontend Feature Checklist

- Module-Version: v1.0.0
- Last-Updated: 2026-07-01

## Architecture & Infrastructure

| ID | Feature | Status |
|----|---------|:------:|
| FE-001 | Multi-module registry | Done |
| FE-002 | Module switcher (TopNav) | Done |
| FE-003 | Sidebar with module navigation | Done |
| FE-004 | TanStack Query provider | Done |
| FE-005 | nginx static deployment | Done |
| FE-006 | TypeScript strict + oxlint | Done |

## Design System

| ID | Feature | Status |
|----|---------|:------:|
| FE-010 | Dark Trading Desk theme | Done |
| FE-011 | Design tokens (Tailwind @theme) | Done |
| FE-012 | cn() utility | Done |
| FE-013 | Status indicators (green/amber/red + glow) | Done |

## Binance Dashboard

| ID | Feature | Status |
|----|---------|:------:|
| FE-020 | KPI cards (Events, Streams, Lag, Reject) | Done |
| FE-021 | Prometheus /metrics parser | Done |
| FE-022 | Events stacked area chart | Done |
| FE-023 | Latency line chart (P50/P95/P99) | Done |
| FE-024 | SLO status with health indicators | Done |
| FE-025 | Product line filter | Done |
| FE-026 | 5s auto-refresh | Done |
| FE-027 | Loading/Error/Empty states | Done |

## Binance Market Data

| ID | Feature | Status |
|----|---------|:------:|
| FE-030 | ⌘K symbol search | Done |
| FE-031 | Candlestick chart | Done |
| FE-032 | Depth chart (bid/ask) | Done |
| FE-033 | Trades table (color-coded) | Done |
| FE-034 | Funding rate history | Done |
| FE-035 | Mark price history | Done |
| FE-036 | 6 event type tabs | Done |

## Binance Health

| ID | Feature | Status |
|----|---------|:------:|
| FE-040 | Server process card | Done |
| FE-041 | Client process card | Done |
| FE-042 | Stream status table | Done |
| FE-043 | Infrastructure grid (8 services) | Done |
| FE-044 | /healthz + /readyz polling | Done |

## Binance Alerts

| ID | Feature | Status |
|----|---------|:------:|
| FE-050 | 9 alert rule display | Done |
| FE-051 | Active/Resolved filter | Done |
| FE-052 | Critical/Warning filter | Done |
| FE-053 | Alert history list | Done |

## Binance Admin

| ID | Feature | Status |
|----|---------|:------:|
| FE-060 | Deadletter queue | Done |
| FE-061 | Config viewer (Client/Server/Security) | Done |
| FE-062 | Replay/Drain/Export/Hot Reload buttons | Done |

## Testing

| ID | Feature | Status |
|----|---------|:------:|
| FE-070 | Playwright E2E (18 tests) | Done |
| FE-071 | CI-ready build | Done |

## Summary

| Category | Total | Done |
|----------|:-----:|:----:|
| Architecture | 6 | 6 |
| Design | 4 | 4 |
| Dashboard | 8 | 8 |
| Market | 7 | 7 |
| Health | 5 | 5 |
| Alerts | 4 | 4 |
| Admin | 3 | 3 |
| Testing | 2 | 2 |
| **Total** | **39** | **39** |
