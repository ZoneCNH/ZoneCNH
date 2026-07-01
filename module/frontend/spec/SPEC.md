# Frontend SPEC

- Spec-Version: v1.0.0
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
| 源码 | <https://github.com/ZoneCNH/frontend> |

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

## 7. Pages (Binance)

| Page | Route | Content |
|------|-------|---------|
| Dashboard | `/binance` | 4 KPI, Events chart, Latency chart, SLO |
| Market | `/binance/market` | ⌘K search, Candlestick, Depth, Trades, Funding, Mark |
| Health | `/binance/health` | Process cards, Stream table, Infra grid |
| Alerts | `/binance/alerts` | 9 rules, severity/status filters |
| Admin | `/binance/admin` | Deadletter queue, Config viewer |

## 8. Data Integration

| Source | Hook | Refresh |
|--------|------|:-------:|
| `/metrics` | `useMetrics()` | 5s |
| `/api/v1/market/ticks/:symbol` | `useTicks()` | 5s |
| `/api/v1/market/bars/:symbol` | `useBars()` | 15s |
| `/api/v1/market/depth/:symbol` | `useDepth()` | 5s |
| `/api/v1/market/trades/:symbol` | `useTrades()` | 3s |
| `/api/v1/market/funding-rate/:symbol` | `useFundingRate()` | 30s |
| `/api/v1/market/mark-price/:symbol` | `useMarkPrice()` | 30s |
| `/healthz`, `/readyz` | `useServerHealth()` | 10s |

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
| Code splitting | ≥ 3 chunks | 8 chunks |

## 12. Testing

| Layer | Tool | Status |
|-------|------|:------:|
| E2E | Playwright | 18 tests, 5 pages |
| TypeScript | tsc --noEmit | 0 errors |
| Build | vite build | PASS |

## 13. Deployment

```text
nginx (:443)
├─ /api/*     → proxy_pass binance-server :8090
├─ /healthz   → proxy_pass binance-server :8090
├─ /metrics   → proxy_pass binance-server :8090
└─ /          → /opt/frontend/ (static)
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
| v1.0.0 | 2026-07-01 | Initial release — binance module, multi-module architecture |
