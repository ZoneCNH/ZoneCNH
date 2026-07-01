# module/frontend GOAL

## 元数据

| 字段 | 值 |
| --- | --- |
| 模块 | `frontend` |
| 层级 | 展示层 · ZoneCNH 统一可视化平台 |
| 仓库 | <https://github.com/ZoneCNH/frontend> |
| 当前版本 | v1.0.0 |
| Spec 版本 | v1.0.0 |
| 状态 | L1 Released — binance 模块 5 页面完成，多模块架构就绪 |

## Purpose

`module/frontend` provides the unified web-based visualization platform for all ZoneCNH data modules. It replaces the need for per-module dashboards with a single integrated application.

## Primary Goal

Provide a single, consistent, production-grade web interface for:

1. **Real-time monitoring** — Prometheus metrics visualization with auto-refresh
2. **Market data exploration** — Symbol search, candlestick charts, depth visualization
3. **System health** — Process status, stream monitoring, infrastructure health
4. **Alert management** — Rule configuration, alert filtering, threshold visualization
5. **Administration** — Deadletter management, configuration viewing

## Non-Goals

`module/frontend` does not own:

- Backend data semantics or storage (owned by individual backend modules)
- API endpoint definitions (owned by backend services)
- Authentication/authorization logic (delegated to nginx + backend services)
- Real-time WebSocket streaming (uses polling; WebSocket is a future upgrade path)

## Success Criteria

1. All active ZoneCNH modules have corresponding frontend pages via the module switcher
2. Dashboard KPI cards reflect live Prometheus metrics with ≤5s latency
3. Market data charts support symbol search across all product lines
4. Health page accurately reflects the state of all infrastructure dependencies
5. Build output < 300KB gzip for initial page load
6. Zero TypeScript errors in production build
7. E2E tests cover all critical user flows

## Architecture Principles

1. **Module isolation** — Each backend module owns its pages under `src/modules/{name}/`
2. **Shared infrastructure** — Common layout, hooks, and chart components at top level
3. **Lazy loading** — Heavy chart libraries (Recharts) code-split per page
4. **Design system** — Dark Trading Desk theme via Tailwind CSS 4 `@theme`
5. **API proxying** — All backend calls through nginx reverse proxy; no direct CORS

## Current Blockers

None. binance module complete. market-data and macro-data frontend pages pending backend module maturity.
