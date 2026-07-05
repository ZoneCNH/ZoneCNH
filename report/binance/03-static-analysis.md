# 静态分析与安全审计

> **仓库**：`/home/workspace/binance`
> **方法**：ripgrep 模式扫描 + 关键文件逐行通读 + 跨包依赖追踪
> **验证**：所有关键发现已人工逐条验证

## 总览

| 严重级别 | 数量 |
|----------|------|
| 🔴 严重 | 1 |
| 🟠 高 | 5 |
| 🟡 中 | 8 |
| 🟢 低 | 6 |
| ℹ️ 信息 | 5 |

整体而言，该项目的**密钥管理、admin TLS 强制、goroutine panic 兜底**做得相当扎实；主要风险集中在**限频逻辑未接线**、**下单缺乏客户端校验**、**StreamExecutions 阻塞读不响应 ctx 取消**三处。

---

## 1. 异常处理

### [高] StreamExecutions 阻塞读不响应 ctx 取消

**位置**：`pkg/binancex/adapter.go:317-340`

```go
for {
    select {
    case <-ctx.Done():        // 只在循环顶部检查
        return ctx.Err()
    default:
    }
    _, msg, err := conn.ReadMessage()  // 原生 gorilla 阻塞读，不感知 ctx
```

`conn.ReadMessage()` 阻塞直到下一条消息或连接错误。若 ctx 在 `ReadMessage` 阻塞期间取消，goroutine 不会退出，直到 Binance 端推下一条消息或 pong 超时（最长 60s）。对比 `internal/client/spot.go:99-128` 的 `gorillaConn.ReadMessage(ctx)` 用 goroutine+select 正确实现了 ctx 可取消读取。**此处是 goroutine 泄漏 / 关闭延迟风险**。

### [中] ListExecutions 静默吞掉单品种错误

**位置**：`pkg/binancex/adapter.go:259-264`

```go
trades, err := svc.Do(ctx)
if err != nil {
    continue   // 无日志、无 metric
}
```

单品种 myTrades 查询失败被完全静默，运维无法发现某品种长期拉取失败。应至少 `slog.Warn` + 计数器。

### [中] 大量 `_ = saveSnapshot(...)` 忽略持久化错误

**位置**：`internal/client/history_lifecycle.go:458,484,632`

History 状态快照落盘失败被忽略。若磁盘满或权限问题，运行时状态与磁盘不一致，重启后丢失 backfill 进度。建议至少 `slog.Error`。

### [中] history_rest 429 退避忽略 Retry-After

**位置**：`internal/client/history_rest.go:226-229`

```go
if resp.StatusCode == http.StatusTooManyRequests {
    lastErr = fmt.Errorf("rate limited (429)")
    continue   // 固定指数退避，不读 Retry-After 头
```

Binance 429 响应带 `Retry-After`，应优先尊重；固定退避可能加重限频封禁。同样问题在 `exchangeinfo_fetch.go:129`。

### [低] parseBinanceTrade 构造 Trade 的 error 被忽略

**位置**：`pkg/binancex/adapter.go:420-428`

`domain.NewTrade` 返回的 error 被 `_` 丢弃，若构造失败会返回零值 `Trade`，下游可能写入脏数据。

### [低] http_ingest_endpoint 编码错误被忽略

**位置**：`internal/client/http_ingest_endpoint.go:47`

```go
_ = json.NewEncoder(&body).Encode(req)
```

### [信息] panic/recover 使用

- `internal/ingestcodec/instrumentkey.go:35` `MustMarshalInstrumentKey` panic — 文档约定仅用于测试 fixture，可接受。
- `internal/server/storage/pg_tx.go:62` `WithTx` 中 `recover() → Rollback → panic(p)` — 标准事务回滚模式，正确。
- 25 处 `recover()` 均在 goroutine 入口，防止 panic 杀掉整个进程，做法良好。

### [信息] SDK 调用全部传 ctx

`adapter.go` 中所有 `svc.Do(ctx)` 均透传上层 ctx，未发现 `context.Background()` 滥用。

---

## 2. 边界条件

### [严重] SubmitOrder 无任何客户端下单量/价格校验

**位置**：`pkg/binancex/adapter.go:135-172`

```go
qty, err := safeFloat64(req.Qty.String())   // 仅解析，不检查 >0、minQty、stepSize
svc.Quantity(qty)
```

- 无 `minQty / maxQty / stepSize` 校验（全仓 grep 零命中）
- 无 `MIN_NOTIONAL` 校验
- 无 `qty > 0` 校验（零或负数会直接发到交易所）
- 无 `req == nil` 校验（`req.Qty.String()` 会 nil panic）
- 无 `Symbol` 空值校验

虽然 Binance 服务端会拒绝非法参数，但交易路径客户端零校验属于高风险，会浪费 weight 配额、放大限频风险，且 local/testnet 行为不一致。**建议**：从 exchangeInfo 加载 symbol 过滤器，下单前本地校验。

### [高] decimalx.MustFromString 在生产路径上 panic

**位置**：`pkg/binancex/adapter.go:109,110,386,387,392,415,416,417,461,464`（共 10 处）

`MustFromString` 解析失败直接 `panic`。这些调用位于 `GetBalances`、`parseExecutionReport`（WebSocket 实时回调）、`parseBinanceTrade` 等生产路径。若 Binance 返回异常字段（空字符串、非数字），进程 panic。`parseBinanceOrderResponse:494` 已对 `exQty` 做了空值保护，但其余 9 处没有。

### [中] exchangeinfo_option strike 解析失败默认 0

**位置**：`internal/client/exchangeinfo_option.go:78`

```go
strike, _ := strconv.ParseFloat(sym.StrikePrice, 64)
```

失败时 strike=0，会写入错误的 InstrumentKey，影响期权品种识别。

### [中] kline 数组解析 `len(row) < 12` 静默跳过

**位置**：`internal/client/history_rest.go:336`

坏行被 `continue` 无日志，历史回补静默丢数据。

### [低] unixMilliFromUint64 溢出保护到位

**位置**：`pkg/binancex/adapter.go:525-529`

正确检查 `ms > MaxInt64`，是正面案例。

### [低] spot.go collect 事件丢弃无回压告警

**位置**：`internal/client/spot.go:484-489`

channel 满时 `default: drop`，有 `noteBackpressureDrop()` 计数，但无实时告警阈值。

### [低] WebSocket 重连退避无抖动

**位置**：`internal/client/spot.go:372-378`

```go
backoff *= 2
if backoff > sc.policy.MaxBackoff { backoff = sc.policy.MaxBackoff }
```

纯指数退避无 jitter，多实例同时断线会同步重连（thundering herd）。建议加 ±20% 随机抖动。

---

## 3. 限频 (rate limit) 处理

### [高] ThrottleManager 已实现但从未在真实请求路径上调用

**位置**：`internal/client/throttle.go` + `internal/client/runtime.go:229`

```go
throttle, err := NewThrottleManager(ThrottleConfig{...})  // runtime.go:229 创建
```

全仓 grep `\.Allow\(|RecordSuccess|RecordBackoff` 在非测试代码中**零命中**。`ThrottleManager` 被创建并注入 admin server 供快照展示，但 `history_rest.go` 的 `fetchPage` 和 `exchangeinfo_fetch.go` 的请求路径**完全没有调用 `throttle.Allow()`**。即：限频预算系统在 admin UI 上"有数"，但实际不阻断任何请求。

### [高] WeightGate / RetryBudget / ClockSkewDetector 同样未接线

**位置**：`internal/server/controlplane_binding.go:32` + `internal/server/assembly/assemble.go:133-137`

```go
serverConfig.ControlPlane = &server.ControlPlaneBindings{
    Registry:  registry,
    Lifecycle: lifecycle,
    // Weight / Retry / Skew 全部为 nil
}
```

`ControlPlaneBindings` 只装配了 Registry 和 Lifecycle，`Weight *WeightGate`、`Retry *RetryBudget`、`Skew *ClockSkewDetector` 均为 nil。`WeightGate.Admit()` 在非测试代码中零调用。

### [中] 429 / 418 处理不完整

- `history_rest.go:227` 处理 429 但不读 `Retry-After`（见 §1）。
- **418（IP 自动封禁）全仓零处理** — grep `418|StatusIAmATeapot` 无命中。Binance 在持续违反限频后会返回 418 长期封禁，当前代码会把它当普通非 2xx 错误重试 3 次后放弃，不会触发 AIMD backoff 或告警。
- `exchangeinfo_fetch.go:129` 把 429 分类为 retryable 但不重试。

### [中] AIMD 退避无上限恢复时间

**位置**：`internal/client/throttle.go:243-260`

`RecordBackoff` 在 5s cooldown 后 `currentRate *= 0.5`，连续 backoff 会指数级压低速率；`RecordSuccess` 每次 +1 缓慢恢复。若连续触发 10 次 backoff，速率从 120 降到 0.06（floor 1.0），恢复需 119 次成功。无时间维度的自动恢复。

### [信息] 已有的正面设计

- `ThrottleManager` 用 weight-aware token bucket，正确解决了"窗口计数不感知真实 weight"问题。
- `WeightGate` 窗口累计 weight 设计正确（`reliability.go:225-242`）。
- `internal/server/api/query.go:222-237` 对外 API 有完整 redisx 固定窗口限流 + `Retry-After` 头。

---

## 4. 密钥安全性

### [信息] 密钥管理整体良好

- 所有凭据走 `configx.SecretString`（`pkg/binancecfg/config.go:310-325`），`String()` 返回 `*****` 掩码，`MarshalJSON/MarshalText` 也返回掩码。
- `config.go:7-9,183` 注释明确禁止 `os.Getenv` 直接读凭据。
- `.env` 在 `.gitignore` 中。
- `.gitleaks.toml` 配置完整，CI 有 gitleaks 当前提交扫描 + scheduled 全历史扫描 + govulncheck。
- `SECURITY.md` 完整，明确禁止提交凭据。

### [低] SecretString 在内存中明文

`type SecretString string` + `Reveal() string { return string(s) }`。Go string 不可清零，GC 前内存中是明文。这是 Go 生态通用妥协，当前实现与 Go 标准库一致，可接受。

### [低] Reveal() 调用点多

`internal/server/assembly/storage.go:91,102,126,166,203,236,237` + `assemble.go:263` + `dispatcher.go:134`。Reveal 后明文传入第三方 driver，明文生命周期超出 SecretString 控制。属不可避免的集成现实。

### [低] CSRF token 与 Admin token 同值

**位置**：`internal/client/admin.go:158-163`

CSRF 校验用的是 admin bearer token 本身。语义上 CSRF token 应是会话级独立 token。在 machine-to-machine admin 场景可接受，但削弱了 CSRF 防护意义。用了 `subtle.ConstantTimeCompare` 防时序攻击，正面。

### [信息] TLS 强制到位

**位置**：`internal/server/admin.go:228-243`

非 loopback admin bind 强制 `ADMIN_TLS_CERT + ADMIN_TLS_KEY + ADMIN_TOKEN`，`tls.Config{MinVersion: tls.VersionTLS12}`。Binance 端点全为 `https://` / `wss://`。

---

## 5. 并发安全

### [中] wsActiveConns 是全局而非 per-connector

**位置**：`internal/client/stream_control.go:390-415`

`MaxConnections`（默认 10）是全进程所有产品线共享的上限。若同时启用 spot+um+cm+options 4 条产品线，每条各 10 连接的理论上限实际是 10 全局。配置项命名易误解。

### [中] fan-in goroutine 依赖 connector 退出关闭 channel

**位置**：`internal/client/runtime.go:355-388`

逻辑正确：所有 fan-in goroutine 退出后 close(merged)。但若某 source ch 永不关闭（connector 泄漏），merged 永不 close，下游永久阻塞。依赖 connector.run 在 ctx 取消时关闭 events。

### [低] catalog.go Add 错误被忽略

**位置**：`internal/client/catalog.go:81,94`

```go
_ = c.Add(e)
```

### [低] closeOnce 保护到位（正面案例）

**位置**：`internal/client/spot.go:152-158`

`gorillaConn.Close` 用 `sync.Once` 保护，防止并发 double close。

### [信息] mutex 使用

`SpotConnector` 拆分 5 把锁（connMu/stateMu/controlMu/auditMu + atomic），锁粒度细且无嵌套调用，未发现死锁风险。`ThrottleManager` 单 mu，简单正确。

---

## 关键修复建议（按优先级）

| 优先级 | 建议 |
|--------|------|
| P0 | `SubmitOrder` 加入 minQty/maxQty/stepSize/notional 客户端校验，至少校验 `qty > 0`、`req != nil`、`symbol != ""` |
| P1 | `ThrottleManager.Allow()` 接入 `history_rest.fetchPage` 和 `exchangeinfo_fetch` 实际请求前 |
| P1 | `WeightGate` 在 `assemble.go` 装配，并在请求 Binance 的路径上调用 `Admit` |
| P1 | `StreamExecutions` 改用 ctx 可取消的读取（仿 `spot.go` 的 goroutine+select 模式） |
| P1 | `MustFromString` 在生产路径替换为 `FromString` + error 处理 |
| P2 | `history_rest` 429 读取 `Retry-After` 头；新增 418 处理 |
| P2 | `ListExecutions` 单品种失败加日志 + metric |
| P2 | 重连退避加 jitter |
