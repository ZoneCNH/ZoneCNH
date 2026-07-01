# Binance 模块前端设计方案

- 设计日期：2026-07-01
- 源模块：`module/binance/` v3.9.6 / Runtime v0.8.0
- 设计状态：Proposal

---

## 1. 设计目标

为 `module/binance` 构建一个生产级前端可视化平台，提供以下核心能力：

| 目标           | 描述                                                   | 优先级 |
| -------------- | ------------------------------------------------------ | :----: |
| 实时行情监控   | 9 个 Prometheus 指标 + 4 个 SLO 的可视化仪表盘         |   P0   |
| 市场数据浏览器 | 通过 REST API 查询和可视化 tick/bar/depth 等行情数据   |   P0   |
| 系统健康面板   | 双进程（client/server）状态、stream 状态、consumer lag |   P0   |
| 告警管理       | 阈值配置、告警历史、通知规则                           |   P1   |
| Admin 控制台   | 热重载、deadletter 管理、配置查看                      |   P1   |
| 可观测性集成   | 嵌入 Grafana iframe + Jaeger 追踪链接                  |   P1   |

---

## 2. 技术栈

### 2.1 推荐方案

```text
┌─ 框架层 ─────────────────────────────────────────────┐
│  React 19 + TypeScript 5.7                           │
│  Vite 6 (SPA) 或 Next.js 15 (App Router)             │
│  Tailwind CSS 4 + shadcn/ui (组件库)                  │
├─ 数据层 ─────────────────────────────────────────────┤
│  TanStack Query v5     — REST API 数据获取与缓存      │
│  SWR 或 WebSocket      — 实时指标推送                │
│  Recharts              — 图表可视化                   │
│  date-fns              — 时间格式化                   │
├─ 状态层 ─────────────────────────────────────────────┤
│  Zustand               — 全局状态（用户偏好、筛选器） │
│  nuqs                  — URL 状态（symbol、时间范围） │
├─ 基础设施 ───────────────────────────────────────────┤
│  pnpm                  — 包管理                       │
│  Biome                 — Lint + Format                │
│  Playwright            — E2E 测试                     │
│  Docker                — 容器化部署                   │
└──────────────────────────────────────────────────────┘
```

### 2.2 选型理由

| 决策     | 选择           | 理由                                            |
| -------- | -------------- | ----------------------------------------------- |
| 框架     | Vite 6 SPA     | 纯客户端应用，无需 SSR，Vite 更轻量快速         |
| 组件库   | shadcn/ui      | 无运行时依赖，可定制，符合 Dark Luxury 设计方向 |
| 数据获取 | TanStack Query | 自动缓存、重新验证、乐观更新                    |
| 图表     | Recharts       | React 原生，声明式 API，适合时序和指标可视化    |
| 样式     | Tailwind CSS 4 | 设计令牌化，与 shadcn/ui 深度集成               |

---

## 3. 页面架构

### 3.1 路由结构

```text
/                           → Dashboard（实时监控首页）
/market                     → 市场数据浏览器
/market/:symbol             → 单个 Symbol 详情
/health                     → 系统健康状态
/alerts                     → 告警管理
/admin                      → Admin 控制台
/admin/deadletter           → Dead-letter 管理
/admin/config               → 配置查看
```

### 3.2 布局结构

```text
┌──────────────────────────────────────────────────────┐
│  TopNav                                                │
│  [Logo] binance · Dashboard  Market  Health  Alerts   │
│  Admin                                   [Theme] [⚙] │
├────────────┬─────────────────────────────────────────┤
│            │                                         │
│  Sidebar   │  Content Area                           │
│            │                                         │
│ · KPI 概览 │  ┌─────────────────────────────────┐    │
│ · SLO 状态 │  │                                 │    │
│ · 产品线   │  │  Charts / Tables / Cards         │    │
│   - spot   │  │                                 │    │
│   - um     │  │                                 │    │
│   - cm     │  │                                 │    │
│   - opt    │  └─────────────────────────────────┘    │
│            │                                         │
└────────────┴─────────────────────────────────────────┘
```

---

## 4. Dashboard 首页设计

### 4.1 布局

Dashboard 是前端核心页面，采用 3 行网格布局：

```text
┌──────────────────────────────────────────────────────────┐
│  Row 1: 流量概览                                          │
│  ┌─────────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ │
│  │ Events/s     │ │ Streams  │ │ Consumer │ │ Reject   │ │
│  │ 12,345 ↑    │ │ 4/4 ●   │ │ Lag: 42  │ │ 0.3%     │ │
│  └─────────────┘ └──────────┘ └──────────┘ └──────────┘ │
├──────────────────────────────────────────────────────────┤
│  Row 2: 时序图表                                          │
│  ┌──────────────────────────────────────────────────────┐│
│  │ events_total (stacked by product_line)    [1h 6h 24h]││
│  │ ▓▓▓▓▓▓░░░░▓▓▓▓▓▓▓▓░░░▓▓▓▓▓▓░░░░▓▓▓▓▓▓▓▓░░░▓▓▓▓     ││
│  └──────────────────────────────────────────────────────┘│
│  ┌──────────────────────┐ ┌────────────────────────────┐ │
│  │ Ingest Latency       │ │ Dispatch Latency           │ │
│  │ P50/P95/P99 (折线)    │ │ P50/P95/P99 (折线)         │ │
│  └──────────────────────┘ └────────────────────────────┘ │
├──────────────────────────────────────────────────────────┤
│  Row 3: 健康面板 + SLO                                     │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │
│  │ Deadletter  │ │ Idempotency │ │ SLO Status          │ │
│  │ Count: 0    │ │ Hits: 150   │ │ ████ 99.95% avail   │ │
│  │ Rate: 0%    │ │             │ │ ████ 0.8s dispatch   │ │
│  └─────────────┘ └─────────────┘ └─────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

### 4.2 KPI 卡片组件

```typescript
// 核心 KPI 卡片数据结构
interface KpiCard {
  title: string;
  value: number | string;
  unit?: string;
  trend?: "up" | "down" | "stable";
  trendValue?: string;
  status: "healthy" | "warning" | "critical";
}
```

### 4.3 产品线筛选

Dashboard 默认显示全产品线聚合视图，支持按 `spot` / `um_perp` / `cm_perp` / `options` 切换。

### 4.4 时间范围选择器

预设：`1h` / `6h` / `24h` / `7d`，支持自定义范围。

---

## 5. 市场数据浏览器

### 5.1 Symbol 搜索与数据视图

```text
┌──────────────────────────────────────────────────────────┐
│  Market Data Explorer                                     │
│                                                          │
│  ┌──────────────────────────────────────────────────────┐│
│  │ 🔍 Search symbol...                    [产品线 ▼]     ││
│  │ BTCUSDT · spot        ETHUSDT · spot               ││
│  │ BTCUSDT · um_perp     BTCUSD_PERP · cm_perp         ││
│  │ ETH-250627-3000-C · options                        ││
│  └──────────────────────────────────────────────────────┘│
│                                                          │
│  [ticks] [bars] [depth] [trades] [funding] [mark price]  │
│                                                          │
│  ┌──────────────────────────────────────────────────────┐│
│  │  Price Chart (Candlestick / Line)                    ││
│  │    ██                                                 ││
│  │   ████  ██                                            ││
│  │  ██████ ████   ██                                     ││
│  │ ██████████████ ████                                   ││
│  └──────────────────────────────────────────────────────┘│
│                                                          │
│  ┌──────────────────────┐ ┌────────────────────────────┐ │
│  │ Order Book (Depth)   │ │ Recent Trades              │ │
│  │ ████ Bids            │ │ 12:30:45  0.5 @ 87,432     │ │
│  │ ██   Asks            │ │ 12:30:44  0.2 @ 87,430     │ │
│  └──────────────────────┘ └────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

### 5.2 数据类型 → 可视化映射

| Tab          | API 端点                                  | 可视化                       |
| ------------ | ----------------------------------------- | ---------------------------- |
| Ticks        | `GET /api/v1/market/ticks/:symbol`        | 实时价格折线图 + 数据表格    |
| Bars         | `GET /api/v1/market/bars/:symbol`         | K 线图（OHLC）+ 成交量柱状图 |
| Depth        | `GET /api/v1/market/depth/:symbol`        | 订单簿深度图（双向柱状图）   |
| Trades       | `GET /api/v1/market/trades/:symbol`       | 逐笔成交瀑布流               |
| Funding Rate | `GET /api/v1/market/funding-rate/:symbol` | 资金费率时序折线图           |
| Mark Price   | `GET /api/v1/market/mark-price/:symbol`   | 标记价格 + 指数价格对比      |

### 5.3 API 数据层

```typescript
// TanStack Query hooks 示例
function useMarketTicks(symbol: string, range: TimeRange) {
  return useQuery({
    queryKey: ["ticks", symbol, range],
    queryFn: () =>
      fetch(`/api/v1/market/ticks/${symbol}?from=${range.from}&to=${range.to}`),
    refetchInterval: 5000, // 5s 轮询
  });
}
```

---

## 6. 系统健康面板

### 6.1 双进程健康视图

```text
┌──────────────────────────────────────────────────────────┐
│  System Health                                            │
│                                                          │
│  ┌─────────────────────┐ ┌─────────────────────────────┐ │
│  │ binance-client      │ │ binance-server              │ │
│  │ Status: ● Running   │ │ Status: ● Running           │ │
│  │ Uptime: 14d 3h      │ │ Uptime: 14d 3h              │ │
│  │ PID: 2841           │ │ PID: 2839                   │ │
│  │ Memory: 287M/512M   │ │ Memory: 2.1G/4G             │ │
│  │ WS Conn: 4 active   │ │ Consumer Lag: 42            │ │
│  │ Admin: :8082        │ │ GIN API: :8090              │ │
│  └─────────────────────┘ └─────────────────────────────┘ │
│                                                          │
│  ┌──────────────────────────────────────────────────────┐│
│  │ Stream Status                              [refresh] ││
│  │ ┌──────────┬────────┬─────────┬──────────┬─────────┐││
│  │ │ Stream   │ Active │ Events  │ Rejected │ Stale   │││
│  │ ├──────────┼────────┼─────────┼──────────┼─────────┤││
│  │ │ spot     │ ● 2/2  │ 8,234/h │ 12 (0.1%)│ 0       │││
│  │ │ um_perp  │ ● 3/3  │ 5,672/h │ 8 (0.1%) │ 0       │││
│  │ │ cm_perp  │ ● 1/1  │ 892/h   │ 3 (0.3%) │ 0       │││
│  │ │ options  │ ● 1/1  │ 1,201/h │ 5 (0.4%) │ 0       │││
│  │ └──────────┴────────┴─────────┴──────────┴─────────┘││
│  └──────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────┘
```

### 6.2 基础设施依赖状态

```text
┌──────────────────────────────────────────────────────────┐
│  Infrastructure Status                                    │
│                                                          │
│  NATS :4222        ● Connected    Redis :6379    ● OK   │
│  PostgreSQL :5432  ● OK           TDengine :6030  ● OK   │
│  Kafka :9092       ● OK           ClickHouse :9000 ● OK  │
│  OSS               ● OK           OTel :4318      ● OK   │
└──────────────────────────────────────────────────────────┘
```

---

## 7. 告警管理

### 7.1 告警列表

```text
┌──────────────────────────────────────────────────────────┐
│  Alerts                                                    │
│                                                           │
│  Filters: [All] [Active] [Resolved]  Severity: [All ▼]   │
│                                                           │
│  ┌──────────────────────────────────────────────────────┐ │
│  │ 🔴 CRITICAL · consumer_lag > 1000                    │ │
│  │   Triggered: 12:30:45 · Duration: 5m                 │ │
│  │   Value: 1,247 · Threshold: 1,000                   │ │
│  ├──────────────────────────────────────────────────────┤ │
│  │ 🟡 WARNING · reject_rate > 5%                        │ │
│  │   Triggered: 12:28:00 · Duration: 7m                 │ │
│  │   Value: 6.2% · Threshold: 5%                       │ │
│  ├──────────────────────────────────────────────────────┤ │
│  │ 🟢 RESOLVED · deadletter_total > 0                   │ │
│  │   Resolved: 11:45:00 · Duration: 3m                  │ │
│  └──────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

### 7.2 告警规则配置

基于 OBSERVABILITY.md 的 9 指标：

| Metric                          | 告警条件         |  严重度  |
| ------------------------------- | ---------------- | :------: |
| `ingest_events_total`           | 5min 无增长      | CRITICAL |
| `rejected_total`                | reject rate > 5% | WARNING  |
| `dispatch_latency_seconds`      | P99 > 1s         | WARNING  |
| `storage_write_latency_seconds` | P99 > 500ms      | WARNING  |
| `idempotency_hits_total`        | 突增（> 3σ）     | WARNING  |
| `deadletter_total`              | 5min > 0         | CRITICAL |
| `consumer_lag`                  | > 1000           | CRITICAL |
| `stream_active`                 | 突降             | CRITICAL |
| `event_stale_total`             | rate > 1%        | WARNING  |

---

## 8. Admin 控制台

### 8.1 Dead-letter 管理

```text
┌──────────────────────────────────────────────────────────┐
│  Dead-letter Management                                    │
│                                                           │
│  Total: 0 dead-letter events                               │
│                                                           │
│  ┌──────────────────────────────────────────────────────┐ │
│  │ ID      │ Timestamp │ Reason        │ Actions       │ │
│  ├─────────┼───────────┼───────────────┼──────────────┤ │
│  │ dl-001  │ 12:30:45  │ storage_write │ [Replay] [✕] │ │
│  │ dl-002  │ 11:22:10  │ schema_err   │ [Replay] [✕] │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                           │
│  [Replay All] [Drain] [Export]                            │
└──────────────────────────────────────────────────────────┘
```

### 8.2 配置查看器

```text
┌──────────────────────────────────────────────────────────┐
│  Configuration                          [Source: prod.env] │
│                                                           │
│  ┌─ Client ────────────────────────────────────────────┐ │
│  │ BINANCE_PRODUCT_LINES = spot,um_perp,cm_perp,options │ │
│  │ BINANCE_SYMBOLS = BTCUSDT,ETHUSDT,...               │ │
│  │ BINANCE_WS_BASE_URL = wss://stream.binance.com:9443  │ │
│  │ BINANCE_RECONNECT_MAX_BACKOFF = 30s                  │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                           │
│  ┌─ Server ────────────────────────────────────────────┐ │
│  │ BINANCE_HTTP_ADDR = :8090                           │ │
│  │ BINANCE_CONSUMER_DURABLE = binance-server            │ │
│  │ BINANCE_QUERY_LIMIT_DEFAULT = 1000                   │ │
│  │ BINANCE_QUERY_LIMIT_MAX = 10000                      │ │
│  │ BINANCE_ENABLE_INGEST_SMOKE = false                  │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                           │
│  [Hot Reload]                                             │
└──────────────────────────────────────────────────────────┘
```

---

## 9. 设计方向：Dark Trading Desk

### 9.1 设计理念

参考 `rules/ecc/web/design-quality.md` 的要求，前端采用 **Dark Luxury Trading Desk** 风格：

| 维度     | 选择                                                       |
| -------- | ---------------------------------------------------------- |
| 风格方向 | Dark Luxury（深色奢华交易台）                              |
| 配色     | 深灰底色 `#0A0E14`，绿色强调 `#00E676`，蓝色数据 `#4FC3F7` |
| 字体     | Geist Mono（数据列）+ Geist Sans（UI）                     |
| 动效     | 数字翻牌动画、微光泽、毛玻璃层级                           |
| 质感     | 深色表面 + 微纹理 + 绿色霓虹强调                           |

### 9.2 设计令牌

```css
:root {
  /* 底色系 */
  --color-bg-primary: #0a0e14;
  --color-bg-surface: #131820;
  --color-bg-elevated: #1a2330;
  --color-bg-overlay: #1f2a38;

  /* 文字 */
  --color-text-primary: #e6edf3;
  --color-text-secondary: #8b949e;
  --color-text-muted: #484f58;

  /* 强调色 */
  --color-accent-green: #00e676; /* 上涨/健康 */
  --color-accent-red: #ff5252; /* 下跌/告警 */
  --color-accent-blue: #4fc3f7; /* 数据/信息 */
  --color-accent-amber: #ffb74d; /* 警告 */

  /* 边框 */
  --color-border: #21262d;
  --color-border-active: #30363d;

  /* 动效 */
  --duration-fast: 150ms;
  --duration-normal: 300ms;
  --ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);

  /* 字体 */
  --font-mono: "Geist Mono", monospace;
  --font-sans: "Geist Sans", sans-serif;
}
```

### 9.3 组件设计原则

- **KPI 卡片**：大数字 + 翻牌/计数动画，趋势箭头，状态环
- **图表**：深色主题，绿色/蓝色配色方案，毛玻璃 tooltip
- **表格**：等宽字体，striped 行，hover 高亮，排序指示器
- **导航**：左侧图标导航 + 顶部面包屑
- **状态指示**：脉冲点（绿=健康，黄=警告，红=故障）

---

## 10. 数据流设计

### 10.1 实时数据通道

```text
┌──────────────────┐     Polling / SSE     ┌──────────────────┐
│  binance-server  │ ────────────────────► │  Frontend         │
│  :8090           │                      │                   │
│                  │  GET /metrics         │  Prometheus       │
│                  │ ────────────────────► │  /api/metrics     │
│                  │                      │                   │
│                  │  GET /healthz/readyz  │  Health Check     │
│                  │ ────────────────────► │  /api/health      │
│                  │                      │                   │
│                  │  GET /api/v1/market/* │  Market Data      │
│                  │ ────────────────────► │  /api/market      │
└──────────────────┘                      └──────────────────┘
```

### 10.2 数据获取策略

| 数据类型 | 策略            | 刷新间隔 |
| -------- | --------------- | :------: |
| KPI 指标 | Polling         |    5s    |
| 时序图表 | Polling（增量） |   15s    |
| 系统健康 | Polling         |   10s    |
| 行情数据 | Polling（按需） |    5s    |
| 告警列表 | Polling         |   30s    |
| 配置     | Fetch（按需）   |  Manual  |

### 10.3 API 代理

Vite dev server 代理转发到 binance-server，避免 CORS 问题：

```typescript
// vite.config.ts
export default defineConfig({
  server: {
    proxy: {
      "/api/v1/market": "http://jp1.internal:8090",
      "/healthz": "http://jp1.internal:8090",
      "/readyz": "http://jp1.internal:8090",
      "/metrics": "http://jp1.internal:8090",
    },
  },
});
```

---

## 11. 组件树

```text
App
├─ TopNav
│  ├─ Logo
│  ├─ NavLinks（Dashboard / Market / Health / Alerts / Admin）
│  ├─ TimeRangeSelector
│  └─ ThemeToggle
├─ Sidebar
│  ├─ ProductLineFilter
│  ├─ QuickStats
│  └─ SloStatus
└─ PageContent
   ├─ DashboardPage
   │  ├─ KpiCardGrid
   │  │  ├─ KpiCard（Events/s）
   │  │  ├─ KpiCard（Streams Active）
   │  │  ├─ KpiCard（Consumer Lag）
   │  │  └─ KpiCard（Reject Rate）
   │  ├─ TimeSeriesChart（Events by product_line）
   │  ├─ LatencyChart（P50/P95/P99）
   │  ├─ DeadletterPanel
   │  ├─ IdempotencyPanel
   │  └─ SloStatusPanel
   ├─ MarketPage
   │  ├─ SymbolSearch（Command Palette ⌘K）
   │  ├─ EventTypeTabs
   │  ├─ PriceChart（Candlestick/Line）
   │  ├─ DepthChart（Order Book）
   │  └─ RecentTradesTable
   ├─ HealthPage
   │  ├─ ProcessCard（client）
   │  ├─ ProcessCard（server）
   │  ├─ StreamStatusTable
   │  └─ InfraStatusGrid
   ├─ AlertsPage
   │  ├─ AlertFilters
   │  ├─ AlertList
   │  └─ AlertRuleConfig
   └─ AdminPage
      ├─ DeadletterManager
      └─ ConfigViewer
```

---

## 12. 实现计划

### 12.1 Phase 0：项目初始化（1-2 天）

| 任务                             | 产出                |
| -------------------------------- | ------------------- |
| 初始化 Vite + React + TypeScript | 项目骨架            |
| 配置 Tailwind CSS 4 + shadcn/ui  | 设计系统            |
| 配置 Biome（lint + format）      | 代码规范            |
| 配置 API 代理                    | 开发环境可调通 API  |
| 编写基础布局（TopNav, Sidebar）  | 布局框架            |
| 实现 Dark Trading Desk 主题      | 设计令牌 + 全局样式 |

### 12.2 Phase 1：Dashboard 核心（3-4 天）

| 任务                                | 产出         |
| ----------------------------------- | ------------ |
| KpiCard 组件 + 动画                 | 实时数字翻牌 |
| TimeSeriesChart（Recharts）         | 事件量时序图 |
| LatencyChart（P50/P95/P99）         | 延迟分布图   |
| ProductLineTabs + StreamStatusTable | 产品线筛选   |
| SloStatusPanel（进度环）            | SLO 可视化   |
| TanStack Query hooks（/metrics）    | 数据层       |
| 5s 轮询实时刷新                     | 实时更新     |

### 12.3 Phase 2：市场数据浏览器（3-4 天）

| 任务                        | 产出           |
| --------------------------- | -------------- |
| SymbolSearch（⌘K 命令面板） | Symbol 搜索    |
| CandlestickChart（K 线）    | Bar 数据可视化 |
| DepthChart（双向柱状图）    | 订单簿深度     |
| RecentTradesTable           | 逐笔成交       |
| FundingRateChart            | 资金费率       |
| MarkPriceChart              | 标记价格       |
| EventTypeTabs               | Tab 切换       |
| URL 状态持久化（nuqs）      | 分享链接       |

### 12.4 Phase 3：健康 + 告警 + Admin（2-3 天）

| 任务                         | 产出           |
| ---------------------------- | -------------- |
| ProcessCard（client/server） | 进程状态       |
| InfraStatusGrid              | 基础设施状态   |
| AlertList + AlertRuleConfig  | 告警管理       |
| DeadletterManager            | Dead-letter UI |
| ConfigViewer                 | 配置查看       |

### 12.5 Phase 4：打磨 + 部署（2 天）

| 任务                              | 产出           |
| --------------------------------- | -------------- |
| Loading/Skeleton/Error/Empty 四态 | 全状态覆盖     |
| 响应式适配（≥1024px）             | 桌面优化       |
| Playwright E2E 测试               | 关键流程测试   |
| Docker + nginx 静态部署           | 容器化         |
| 性能优化（bundle < 150KB gzip）   | Lighthouse 90+ |

---

## 13. 部署拓扑

```text
┌─ jp1 (84.247.154.45) ────────────────────────────────────┐
│                                                           │
│  nginx (:443)                                              │
│  ├─ /api/*        → proxy_pass http://127.0.0.1:8090      │
│  ├─ /healthz      → proxy_pass http://127.0.0.1:8090      │
│  ├─ /metrics      → proxy_pass http://127.0.0.1:8090      │
│  └─ /             → static files (frontend build)         │
│                                                           │
│  binance-server (:8090)                                    │
│  binance-client                                           │
│  frontend (nginx static)                                   │
└──────────────────────────────────────────────────────────┘
```

### nginx 配置

```nginx
server {
    listen 443 ssl;
    server_name binance-dashboard.internal;

    # API 代理
    location /api/   { proxy_pass http://127.0.0.1:8090; }
    location /healthz { proxy_pass http://127.0.0.1:8090; }
    location /readyz  { proxy_pass http://127.0.0.1:8090; }
    location /metrics { proxy_pass http://127.0.0.1:8090; }

    # 前端静态文件
    location / {
        root /opt/binance/dashboard;
        try_files $uri $uri/ /index.html;
    }
}
```

---

## 14. 风险与缓解

| 风险                   | 级别 | 缓解                                      |
| ---------------------- | :--: | ----------------------------------------- |
| API 认证绕过           | HIGH | nginx 统一认证；前端不直连 binance-server |
| 实时数据延迟           | MED  | 5s 轮询 + WebSocket 升级路径预留          |
| 大数据量图表卡顿       | MED  | 数据采样 + 虚拟化表格                     |
| 跨产品线 Symbol 名冲突 | LOW  | 前端 UI 用 product_line tag 区分          |
| 生产 /ingest 泄漏      | HIGH | nginx 禁止 `POST /ingest` 路由            |

---

## 15. 外部依赖集成

### 15.1 Grafana 仪表盘嵌入

```tsx
<iframe
  src="http://jp1.internal:3000/d-solo/binance-dashboard?theme=dark"
  className="w-full h-[600px] border-0 rounded-lg"
/>
```

### 15.2 Jaeger 追踪链接

```tsx
<a
  href={`http://jp1.internal:16686/trace/${traceId}`}
  target="_blank"
  rel="noopener noreferrer"
  className="text-accent-blue hover:underline"
>
  View Trace →
</a>
```

---

_[RULES I BROKE]: 无。本设计方案基于 binance 模块 SPEC v3.9.6 / OBSERVABILITY.md (9 metrics + 4 SLO) / DESIGN.md (interfaces) / DEPLOY.md 当前部署拓扑。_
