# module/frontend

`module/frontend` is the unified ZoneCNH visualization platform — a single-page application providing monitoring dashboards, market data exploration, system health, alert management, and administration for all ZoneCNH data modules.

- Spec-Version: v1.0.0
- Runtime-Version: v1.0.0
- Repository: <https://github.com/ZoneCNH/frontend>
- Last-Updated: 2026-07-01

## Role

`module/frontend` owns the web-based visualization layer for ZoneCNH. It does not own backend data semantics (those are owned by individual modules like `module/binance`), but provides the unified UI shell, module routing, and shared component library.

## Architecture

```text
ZoneCNH Frontend (React SPA)
├── Module Registry (src/modules/registry.ts)
│   ├── binance/     # Binance 行情采集监控
│   ├── market-data/ # 待实现
│   └── macro-data/  # 待实现
├── Shared: hooks/ · lib/ · components/layout/
└── Deploy: nginx static + API proxy → backend services
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | React 19 + TypeScript 6 + Vite 8 |
| Styling | Tailwind CSS 4 + Dark Trading Desk theme |
| Routing | React Router 7 (multi-module) |
| Data | TanStack Query 5 |
| Charts | Recharts 3 (lazy-loaded) |
| State | Zustand 5 |
| Testing | Playwright 1.61 (18 E2E tests) |
| Deploy | nginx static + proxy_pass |

## Module Support

| Module | Status | Pages |
|--------|:------:|-------|
| binance | ✅ v1.0.0 | Dashboard, Market, Health, Alerts, Admin |
| market-data | ⬜ planned | — |
| macro-data | ⬜ planned | — |

## Read Next

- `goal/goal.md`
- `spec/SPEC.md`
- `spec/FEATURES.md`
- <https://github.com/ZoneCNH/frontend>
