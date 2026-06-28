# binancecfg 规格

- Spec-Version: v0.1.0
- Runtime-Version: v0.1.0-patch
- Status: Draft（从 patches/binancecfg/config.go 反向提取）
- Last-Updated: 2026-06-29
- Source: `patches/binancecfg/config.go`

## 1. 摘要

`binancecfg` 为 binance ingest pipeline 提供类型化配置加载层。从 `FOUNDATIONX_BINANCE_*` 环境变量读取配置，提供 `DefaultConfig()` 生产安全默认值，并将统一 `Config` 转换为下游 `binance.ServerConfig` 和 `binancex.FeedConfig`。与 `cmd/` 分离，使配置加载可独立测试和复用。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | `Config` 结构体（13 字段）、`LoadConfig()` env var 读取、`DefaultConfig()` 默认值、`Validate()` 校验、`ServerConfig()`/`FeedConfig()` 转换 |
| Depends on | `runtime-patches/binance`（ServerConfig 类型）、`runtime-patches/binancex`（FeedConfig 类型） |
| Consumed by | `cmd`（组合根入口）、`assembly`、storage_env、monitoring 等子系统 |
| Excludes | 配置文件读取、配置中心集成、密钥管理、HTTP/gRPC server、业务逻辑 |

## 3. 术语

| 术语 | 定义 |
| --- | --- |
| FOUNDATIONX_BINANCE_* | 环境变量命名前缀，binance ingest pipeline 统一配置命名空间 |
| StaleThreshold | 事件陈旧阈值，EventTime 早于 now - threshold 时拒绝 |
| FutureTolerance | 未来事件容忍窗口，EventTime 超过 now + tolerance 时拒绝 |
| DrainTimeout | 优雅关闭最大等待时间 |

## 4. Config 结构体

```go
type Config struct {
    StaleThreshold        time.Duration // FOUNDATIONX_BINANCE_STALE_THRESHOLD
    FutureTolerance       time.Duration // FOUNDATIONX_BINANCE_FUTURE_TOLERANCE
    IdempotencyTTL        time.Duration // FOUNDATIONX_BINANCE_IDEMPOTENCY_TTL
    MaxStreams            int           // FOUNDATIONX_BINANCE_MAX_STREAMS
    DrainTimeout          time.Duration // FOUNDATIONX_BINANCE_DRAIN_TIMEOUT
    WSEndpoint            string        // FOUNDATIONX_BINANCE_WS_ENDPOINT
    ReconnectBackoff      time.Duration // FOUNDATIONX_BINANCE_RECONNECT_BACKOFF
    MaxReconnectBackoff   time.Duration // FOUNDATIONX_BINANCE_MAX_RECONNECT_BACKOFF
    MaxReconnectAttempts  int           // FOUNDATIONX_BINANCE_MAX_RECONNECT_ATTEMPTS
    ReadTimeout           time.Duration // FOUNDATIONX_BINANCE_READ_TIMEOUT
    PingInterval          time.Duration // FOUNDATIONX_BINANCE_PING_INTERVAL
    EventBufferSize       int           // FOUNDATIONX_BINANCE_EVENT_BUFFER_SIZE
    ShutdownTimeout       time.Duration // FOUNDATIONX_BINANCE_SHUTDOWN_TIMEOUT
}
```

### 4.1 DefaultConfig

`DefaultConfig()` 返回生产安全默认值。WS endpoint 默认指向 `wss://stream.binance.com:9443/ws`。Duration 默认值保守（StaleThreshold=30s, FutureTolerance=5s, IdempotencyTTL=24h, DrainTimeout=30s, ReconnectBackoff=1s, MaxReconnectBackoff=30s, ReadTimeout=30s, PingInterval=3m, ShutdownTimeout=30s）。整数默认值：MaxStreams=10, MaxReconnectAttempts=10, EventBufferSize=256。

### 4.2 LoadConfig

`LoadConfig()` 从环境变量读取，未设置字段回退到 DefaultConfig。Duration 接受 Go duration 字符串（"30s", "5m", "24h"）。Integer 接受十进制字符串（"10", "256"）。

### 4.3 转换方法

- `ServerConfig()`: Config -> binance.ServerConfig（5 字段映射：StaleThreshold/FutureTolerance/IdempotencyTTL/MaxStreams/DrainTimeout）
- `FeedConfig()`: Config -> binancex.FeedConfig（9 字段映射：WSEndpoint/ReconnectBackoff/MaxReconnectBackoff/MaxReconnectAttempts/ReadTimeout/PingInterval/EventBufferSize，不含 WriteTimeout/ErrorBufferSize）

## 5. 功能需求

| FR ID | Requirement |
| --- | --- |
| FR-BCFG-001 | LoadConfig — 读取 13 个 FOUNDATIONX_BINANCE_* 环境变量，未设置回退 DefaultConfig |
| FR-BCFG-002 | DefaultConfig — 返回生产安全默认值 |
| FR-BCFG-003 | Validate — 拒绝 MaxStreams <= 0、DrainTimeout <= 0、ShutdownTimeout <= 0，委托 FeedConfig.Validate |
| FR-BCFG-004 | ServerConfig() — Config -> binance.ServerConfig 5 字段映射 |
| FR-BCFG-005 | FeedConfig() — Config -> binancex.FeedConfig 9 字段映射 |
| FR-BCFG-006 | parseDurationEnv/parseIntEnv — 非法值记录 warn log，使用默认值，不 panic |

## 6. 行为约束

| BR ID | Rule |
| --- | --- |
| BR-BCFG-001 | 所有配置仅来自 FOUNDATIONX_BINANCE_* 环境变量 + DefaultConfig 回退 |
| BR-BCFG-002 | 非法环境变量值记录 structured log warning，使用默认值，绝不 panic |
| BR-BCFG-003 | Validate 拒绝零/负值关键参数 |
| BR-BCFG-004 | 与 cmd/ 分离，配置加载可独立测试和复用 |

## 7. 非功能需求

| NFR ID | Requirement |
| --- | --- |
| NFR-BCFG-001 | 不依赖外部系统，所有函数接受显式参数或环境变量，可纯单元测试 |
| NFR-BCFG-002 | 仅依赖 stdlib + runtime-patches/binance + runtime-patches/binancex |

## 8. Acceptance Criteria Registry

见 [TRACEABILITY.md §5](./TRACEABILITY.md)

## 9. 后续实现门禁

- Task Gate: TRACEABILITY.md FR/BR/NFR 全部闭合
- Test Gate: `go test ./... -count=1` 通过
- Vet Gate: `go vet ./...` 零警告
- Dependency Gate: `go list -deps` 无禁止依赖

## 变更历史

| 日期 | 变更 |
| --- | --- |
| 2026-06-29 | v0.1.0 Draft：从 patches/binancecfg/config.go 反向提取，初始化 SPEC |
