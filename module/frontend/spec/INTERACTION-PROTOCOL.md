# Frontend-Backend Interaction Protocol

- Spec-Version: v1.1.0
- Last-Updated: 2026-07-01
- Domain: <https://www.wecode7.com>
- Applies to: all ZoneCNH backend modules

---

## 1. 架构原则

```
Browser (React SPA)
  https://www.wecode7.com
    │ TanStack Query → fetch(url) → polling
    ▼
nginx (jp1, TLS 1.3)
  ├─ /api/*      → backend:{port}
  ├─ /healthz    → backend:{port}
  ├─ /readyz     → backend:{port}
  ├─ /metrics    → backend:{port}
  └─ /*          → /opt/frontend/ (SPA)
    ▼
Backend Services
  binance-server :8081  (REST + Admin + Metrics)
  [future] modules      :8091+
```

| # | 原则 |
|:-:|------|
| 1 | **前端不直连后端** — 全部通过 nginx 代理，后端不暴露 CORS |
| 2 | **无状态 HTTP** — 纯 REST，认证由 nginx + Bearer token 处理 |
| 3 | **轮询优先** — TanStack Query 定时轮询；WebSocket 为未来升级路径 |
| 4 | **模块自治** — 每个后端独立部署、独立端口、独立 /metrics |
| 5 | **契约先行** — API 格式在 SPEC.md 定义，前端 hooks 对齐 |

---

## 2. URL 路由规范

### nginx 路由表

```
优先级: exact > prefix > SPA fallback

/api/*      → proxy_pass http://127.0.0.1:{port}
/healthz    → proxy_pass http://127.0.0.1:{port}
/readyz     → proxy_pass http://127.0.0.1:{port}
/metrics    → proxy_pass http://127.0.0.1:{port}
/assets/*   → static (immutable, 1y cache)
/*          → /opt/frontend/index.html (SPA fallback)
```

### 模块端口注册

| 模块 | 端口 | 状态 |
|------|:----:|:----:|
| binance-server | 8081 | ✅ active |
| market_data | 8091 | ⬜ planned |
| macro_data | 8092 | ⬜ planned |

### API URL 模式

```
GET /api/v1/{domain}/{product_line}/{symbol}/{kind}/range?start=&end=
GET /api/v1/{domain}/{product_line}/{symbol}/latest
GET /api/v1/{domain}/stats
GET /api/v1/{domain}/instrument/{product_line}

示例:
  /api/v1/market/spot/BTCUSDT/ticks/range?start=2026-07-01T00:00:00Z&end=2026-07-01T12:00:00Z
  /api/v1/market/um_perp/BTCUSDT/funding-rate/range?start=...&end=...
```

---

## 3. API 响应规范

### 字段命名

| 层级 | 规范 | 示例 |
|------|------|------|
| API 响应 | `snake_case` | `ask_price`, `product_line`, `update_id` |
| 前端类型 | `camelCase` | `askPrice`, `productLine`, `updateId` |
| 时间戳 | `ts` (ISO 8601 + tz) | `2026-07-01T08:00:00.514+08:00` |
| 查询参数 | `snake_case` query | `?start=...&end=...` |

### 成功响应

```json
// 数据列表
[{"ask_price":"58624.71","ask_qty":"1.33","bid_price":"58624.70",
  "bid_qty":"1.81","product_line":"spot","source":"binance",
  "symbol":"BTCUSDT","ts":"2026-07-01T08:00:00+08:00","update_id":96743181755}]

// 健康检查
{"status":"ok"}  /  {"ready":true}
```

### 错误响应

无数据时返回空数组 `[]`（非错误），参数错误时返回错误对象：

```json
// 无数据（正常情况）
[]

// 参数错误
{"code":"BNC_BAD_REQUEST","message":"start must be RFC3339","request_id":"req-..."}
{"code":"BNC_BACKEND_DOWN","message":"catalog unavailable","request_id":"req-..."}
```

### 错误码

| Code | HTTP | 含义 | 触发条件 |
|------|:----:|------|------|
| `BNC_BAD_REQUEST` | 400 | 参数格式错误 | 缺少/格式错误的时间参数 |
| `BNC_BACKEND_DOWN` | 503 | 后端依赖不可用 | 数据库/消息队列不可达 |
| `BNC_NOT_FOUND` | 404 | 数据不存在 | 无历史数据 |

### 数值精度

| 类型 | 传输格式 | 前端转换 |
|------|----------|----------|
| 价格 | `string` | `parseFloat()` → `number` |
| 数量 | `string` | `parseFloat()` → `number` |
| 费率 | `string` | `parseFloat()` × 100 → `%` |
| ID | `integer` | 直接使用 |

---

## 4. 数据获取策略

### 轮询间隔

| 类型 | 间隔 | 原因 |
|------|:----:|------|
| `/metrics` | 5s | 实时监控 |
| ticks | 5s | 实时行情 |
| trades | 3s | 高频成交 |
| depth | 5s | 订单簿 |
| bars | 15s | K 线聚合 |
| funding-rate | 30s | 低频 |
| mark-price | 30s | 低频 |
| healthz/readyz | 10s | 健康检查 |

### 缓存

```typescript
staleTime: 5_000           // 5s 内新鲜
refetchOnWindowFocus: false
placeholderData: prev => prev  // 刷新时保留旧数据
```

### 错误降级

| 场景 | 行为 |
|------|------|
| 网络不可达 | Error state card |
| HTTP 4xx | 返回 `[]`，静默降级 |
| HTTP 5xx | TanStack Query 自动重试 3 次 |
| 超时 | AbortController 30s |
| 空数据 | Dashed border + 引导文字 |

---

## 5. WebSocket 实时推送 (v1.1.0)

### 架构

```
Browser ←wss://→ nginx (:443) → WS Relay (:8095) → poll → binance-server (:8081)
```

WS 中继 (`ws-relay/server.cjs`) 作为 REST→WebSocket 桥接层，浏览器优先使用 WebSocket 接收实时推送，断线时自动降级到 HTTP 轮询。

### 端点

| URL | 角色 |
|-----|------|
| `wss://www.wecode7.com/ws` | WebSocket 入口 (nginx → :8095) |

### 消息格式

```json
{"type":"update","ts":"2026-07-01T13:00:00.000Z","metrics":"# HELP ...\n..."}
```

### 前端集成

```typescript
// useMetricsWs() — 自动重连，WS 优先，轮询降级
const { data, isConnected, latency } = useMetricsWs()
// isConnected=true → WS 推送 (3s), latency 显示延迟
// isConnected=false → 自动降级到 HTTP 轮询 (5s)
```

---

## 6. Prometheus /metrics 规范

### 暴露要求

每个后端模块必须通过 `/metrics` 暴露 Prometheus text-format。

### 命名规范

```
{module}_{metric}_{unit}

binance_ingest_events_total{result="accepted|rejected",status="..."}
binance_deadletter_total
binance_dispatch_total{result="success"}
binance_stream_state{state="active",...}
binance_clock_skew_seconds
```

### 前端解析链

```
fetch('/metrics')
  → parseMetricsText()     // text → MetricSample[]
  → aggregateMetrics()     // MetricSample[] → ParsedMetrics
  → Dashboard KPI / Health table / Alerts
```

---

## 7. 安全规范

```
TLS:            HTTPS only, Let's Encrypt certbot (verified 2026-07-01)
HTTP → HTTPS:   301 redirect
Security headers (all verified):
  X-Content-Type-Options: nosniff
  X-Frame-Options: DENY
  Referrer-Policy: strict-origin-when-cross-origin
  Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
  Permissions-Policy: camera=(), microphone=(), geolocation=()
Auth (future):  nginx auth_request + httpOnly JWT cookie
```

---

## 8. 部署拓扑

```
www.wecode7.com → 84.247.154.45 (jp1)

nginx (:443)
├─ /api/*       → 127.0.0.1:8081 (binance-server)
├─ /healthz     → 127.0.0.1:8081
├─ /metrics     → 127.0.0.1:8081
└─ /*           → /opt/frontend/ (SPA)

binance-server (systemd)  :8081  REST + Admin + Metrics
binance-client (systemd)  :8082  Admin
Infra: NATS:4222 Redis:6379 PG:5432 TDengine:6030 Kafka:9092 ClickHouse:9000
```

---

## 9. 新模块接入清单

| # | 步骤 | 文件 |
|:-:|------|------|
| 1 | 注册 `ModuleDefinition` | `src/modules/registry.ts` |
| 2 | 添加 `<Route>` | `src/App.tsx` |
| 3 | 创建页面组件 | `src/modules/{name}/pages/` |
| 4 | 编写 API hooks | `src/hooks/use{Module}Data.ts` |
| 5 | nginx 添加路由 | jp1 `/etc/nginx/sites-enabled/www.wecode7.com` |
| 6 | 创建模块文档 | `module/{name}/` in ZoneCNH |
| 7 | 注册架构状态 | `ARCHITECTURE.md` |

---

## 10. 变更历史

| Version | Date | Change |
|---------|------|--------|
| v1.1.0 | 2026-07-01 | WebSocket real-time push (§5 WS relay architecture) |
| v1.0.0 | 2026-07-01 | Initial — binance module interaction standard |
