# Frontend SPEC

- Spec-Version: v1.0.1
- Module: frontend
- Last-Updated: 2026-07-01
- Repository: <https://github.com/ZoneCNH/frontend>
- State: L1 Released — binance module complete, multi-module architecture ready

## 1. Goal

Provide a unified web-based visualization platform for all ZoneCNH data modules.

## 2. Authority

| 层级 | 权威 |
| --- | --- |
| 最高治理 | `CONSTITUTION.md` |
| 模块规格 | 本文件 |
| 交互协议 | `INTERACTION-PROTOCOL.md` — 前后端通信规范 |
| 源码 | <https://github.com/ZoneCNH/frontend> |
| 线上 | <https://www.wecode7.com> |

## 3. Scope

包含多模块路由架构、Dark Trading Desk 设计系统、Prometheus 指标可视化、行情数据图表、系统健康监控、告警管理、Admin 控制台。不包含后端数据语义、API 定义或认证逻辑。

## 4. Runtime Boundary

| 组件 | 职责 | 禁止 |
| --- | --- | --- |
| Module Registry | 模块注册、路由生成、模块切换器 | 持有业务逻辑 |
| Layout | TopNav + Sidebar + Content | 直接调用 API（通过 hooks） |
| Hooks | TanStack Query 数据获取 | 服务端渲染假设 |
| Pages | 模块页面 UI | 跨模块状态共享 |
| Charts | Recharts 可视化 | 阻塞首屏（必须 lazy） |

## 5. Architecture

```text
src/
├── modules/registry.ts     # ModuleDefinition[] 注册表
├── modules/{name}/pages/   # 模块页面
├── modules/{name}/components/  # 模块组件
├── components/layout/      # AppLayout, TopNav, Sidebar
├── hooks/                  # useMetrics, useMarketData, useHealth
├── lib/                    # prometheus parser, cn()
└── index.css               # Tailwind + Dark Trading Desk tokens
```

## 6. Module Registry

```typescript
type ModuleId = 'binance' | 'market-data' | 'macro-data'

interface ModuleDefinition {
  id: ModuleId
  name: string
  description: string
  icon: LucideIcon
  routes: { path: string; label: string; icon: LucideIcon }[]
}
```

## 7. Pages

| Page | Route | Module | Content |
|------|-------|--------|---------|
| Home | `/` | — | Module overview, global status, connection indicator |
| Dashboard | `/binance` | binance | 4 KPI (Events/Streams/ClockSkew/Reject), SLO |
| Market | `/binance/market` | binance | ⌘K search, Candlestick+Volume, Ticker line, Depth, Trades, Funding, Mark |
| Health | `/binance/health` | binance | Process cards, Metrics overview table, Infra grid |
| Alerts | `/binance/alerts` | binance | 9 rules config, severity/status filters, live threshold check |
| Admin | `/binance/admin` | binance | Deadletter queue (Replay/Drain/Export), Client/Server/Security config |

## 8. Data Integration

Actual API routes verified on jp1 (2026-07-01):

| Source | Hook | Refresh | Actual Route |
|--------|------|:-------:|------|
| `/metrics` | `useMetrics()` | 5s | Prometheus text-format via `parseMetricsText()` |
| Ticks | `useTicks(symbol, pl)` | 5s | `GET /api/v1/market/{pl}/{symbol}/ticks/range?start=&end=` |
| Bars | `useBars(symbol, pl)` | 15s | `GET /api/v1/market/{pl}/{symbol}/bars/range?start=&end=` |
| Depth | `useDepth(symbol, pl)` | 5s | `GET /api/v1/market/{pl}/{symbol}/depth/range?start=&end=` |
| Trades | `useTrades(symbol, pl)` | 3s | `GET /api/v1/market/{pl}/{symbol}/trades/range?start=&end=` |
| Funding Rate | `useFundingRate(symbol, pl)` | 30s | `GET /api/v1/market/{pl}/{symbol}/funding-rate/range?start=&end=` |
| Mark Price | `useMarkPrice(symbol, pl)` | 30s | `GET /api/v1/market/{pl}/{symbol}/mark-price/range?start=&end=` |
| Health | `useServerHealth()` | 10s | `GET /healthz` + `GET /readyz` |

**API field mapping**: snake_case (API) → camelCase (frontend). Prices/quantities are strings in API, parsed to number in frontend. Timestamp field: `ts` (ISO 8601 + tz). See `INTERACTION-PROTOCOL.md` §3.

## 9. Design System

Dark Trading Desk — Tailwind CSS 4 `@theme` tokens:

| Token | Value |
|-------|-------|
| `--color-bg-primary` | `#0A0E14` |
| `--color-bg-surface` | `#131820` |
| `--color-accent-green` | `#00E676` |
| `--color-accent-red` | `#FF5252` |
| `--color-accent-blue` | `#4FC3F7` |
| `--color-accent-amber` | `#FFB74D` |

## 10. Component States

Every data-driven component handles: Loading (skeleton), Empty (dashed border + guidance), Error (red icon + message), Data (full visualization).

## 11. Performance

| Metric | Target | Actual |
|--------|:------:|:------:|
| Main JS (gzip) | < 300 KB | 217 KB |
| CSS (gzip) | < 30 KB | 4.5 KB |
| Code splitting | ≥ 3 chunks | 12 chunks |

## 12. Testing

| Layer | Tool | Status |
|-------|------|:------:|
| E2E | Playwright | 18 tests, 5 pages |
| TypeScript | tsc --noEmit | 0 errors |
| Build | vite build | PASS |

## 13. Deployment

```text
DNS: www.wecode7.com → 84.247.154.45 (jp1)

nginx (:443 TLS, Let's Encrypt)
├─ /api/*       → proxy_pass http://127.0.0.1:8081  (binance-server REST)
├─ /healthz     → proxy_pass http://127.0.0.1:8081
├─ /readyz      → proxy_pass http://127.0.0.1:8081
├─ /metrics     → proxy_pass http://127.0.0.1:8081  (Prometheus)
├─ /assets/*    → /opt/frontend/ (1y immutable cache)
└─ /*           → /opt/frontend/index.html (SPA fallback)

binance-server (systemd):
  REST API + Admin + Metrics all on :8081
  Admin only on 127.0.0.1:8081 (not exposed externally)

HTTP :80 → 301 redirect → HTTPS :443
```

Deploy: `bash deploy/deploy.sh jp1`

## 14. Future Modules

| Module | Status |
|--------|:------:|
| market-data | planned |
| macro-data | planned |

## 15. Change History

| Version | Date | Change |
|---------|------|--------|
| v1.0.1 | 2026-07-01 | Sync §8 API routes + §13 deployment port (8090→8081) with actual jp1 deployment; add Home page + INTERACTION-PROTOCOL ref |
| v1.0.0 | 2026-07-01 | Initial release — binance module, multi-module architecture |
