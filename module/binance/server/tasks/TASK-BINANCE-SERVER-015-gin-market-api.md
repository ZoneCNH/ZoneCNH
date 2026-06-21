# TASK-BINANCE-SERVER-015 Gin Market API

> 版本：v2.0.0

## Objective

利用 `gin-gonic/gin` 实现 Binance 模块的 REST API 服务，作为 `market_data` 模块的**唯一数据接口**，提供最新 tick、历史 K 线、深度快照查询。

## 分布式约束

- Gin server 是 `binance-server` 进程的一部分（与 natsx consumer、kafkax dispatcher 共进程）
- `market_data` 通过 **HTTP** 调用，不共享进程或内存
- 禁止 `market_data` 直接访问 binance 的 taosx/postgresx 数据库

## Scope

```text
internal/server/api/
  router.go         ← Gin router 注册
  handler/
    market.go       ← /market/* 处理器
    health.go       ← /health 检查
  middleware/
    auth.go         ← API key 中间件（从 configx 读取）
    ratelimit.go    ← redisx 令牌桶限流
```

## REST API 端点

```
GET  /v1/market/ticks           查询最新 tick（最近 N 条或时间范围）
GET  /v1/market/ticks/{symbol}  查询指定 symbol 最新 tick
GET  /v1/market/klines          查询 K 线
GET  /v1/market/depth/{symbol}  查询当前深度快照（来自 redisx 缓存）
GET  /v1/health                 健康检查（taosx/redis/postgres 连通性）
```

### 请求参数（GET /v1/market/ticks）

| 参数 | 类型 | 说明 |
|------|------|------|
| symbol | string（必填）| e.g. BTCUSDT |
| product_line | string（必填）| spot / futures_usdt |
| start | RFC3339 | 开始时间 |
| end | RFC3339 | 结束时间（默认 now）|
| limit | int | 最大条数，默认 100，上限 10000 |

### 响应格式

```json
{
  "data": [...],
  "meta": {
    "symbol": "BTCUSDT",
    "product_line": "spot",
    "count": 100,
    "from": "2024-01-01T00:00:00Z",
    "to": "2024-01-01T01:00:00Z"
  }
}
```

## 接口设计

```go
// internal/server/api/router.go
package api

type Server struct {
    engine  *gin.Engine
    ts      timeseries.Store   // taosx
    cache   redisx.Client      // depth 快照缓存
    catalog catalog.Store      // postgresx
    cfg     APIConfig
}

func (s *Server) RegisterRoutes() {
    v1 := s.engine.Group("/v1")
    v1.Use(middleware.APIKey(s.cfg.APIKeys))
    v1.Use(middleware.RateLimit(s.cache, 1000))  // 1000 req/min per key
    {
        v1.GET("/market/ticks",          s.queryTicks)
        v1.GET("/market/ticks/:symbol",  s.latestTick)
        v1.GET("/market/klines",         s.queryKlines)
        v1.GET("/market/depth/:symbol",  s.depthSnapshot)
        v1.GET("/health",                s.health)
    }
}
```

## Functional Requirements

**FR-API-001**: `GET /v1/market/ticks` 从 taosx 查询，支持 symbol + time range + limit 过滤。

**FR-API-002**: `GET /v1/market/depth/:symbol` 从 redisx 读取最新深度快照（key: `binance:depth:{symbol}`），延迟 ≤1ms。

**FR-API-003**: API key 认证中间件从 `configx` 读取允许的 key 列表，无效 key 返回 401。

**FR-API-004**: redisx 令牌桶限流，超限返回 429 + Retry-After header。

**FR-API-005**: `/health` 返回 taosx + redisx + postgresx 三个组件的连通性状态，任一失败返回 503。

**FR-API-006**: 所有响应统一 JSON 格式，错误使用 `{"error": "message", "code": "SYMBOL_NOT_FOUND"}` 结构。

## Acceptance Criteria

| AC | 验证方式 |
|----|---------|
| /v1/market/ticks 返回 taosx 数据 | httptest + mock taosx，验证响应 JSON |
| /v1/market/depth 从 redisx 读 | mock redisx，验证 key 包含 symbol |
| 无效 API key → 401 | httptest 验证状态码 |
| 超限 → 429 + Retry-After | mock 令牌桶耗尽，验证响应头 |
| /health 连通性失败 → 503 | mock taosx 断连，验证 503 |

## Dependencies

| 依赖 | 版本 | 用途 |
|------|------|------|
| `github.com/gin-gonic/gin` | v1.10.x | HTTP router |
| `github.com/ZoneCNH/redisx` | v1.0.0 | 深度快照 + 限流 |
| `github.com/ZoneCNH/taosx` | v1.0.0 | 历史 tick 查询 |
| `github.com/ZoneCNH/postgresx` | v1.0.0 | 元数据查询 |
| `github.com/ZoneCNH/configx` | v1.0.0 | API key 配置 |
| `github.com/ZoneCNH/observex` | v1.0.0 | 请求日志/指标 |

## Non-scope

- 不做 WebSocket 推送（market_data 如需实时数据通过 natsx/kafkax 自行订阅）
- 不做 GraphQL
- 不做写接口（binance server 是只读 API 对外）
- 不做跨域 CORS（由 market_data 与 binance server 之间的内网调用，不需要浏览器跨域）
