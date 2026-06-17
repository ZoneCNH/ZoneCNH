# domain-exchange 规格

- Status: Approved
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-15
- Layer: L2.5 领域共享
- Version: v1.0.0
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `kernel`, `decimalx`, `domain-market`, `domainx`

> 公开投影 caveat：Status=Approved 与 100.0% 覆盖证据不等同于 factory-grade；机器事实层保持 factory=false。

---

## 1. 摘要

`domain-exchange` 定义交易所领域接口和 adapter SPI，承接 venue capability、request、error、rate limit、registry 和 streaming 语义。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | Exchange SPI、Place/Cancel/Query request、VenueCapability、RateLimitPolicy、ExchangeError、Registry |
| Depends on | `kernel`、`decimalx`、`domain-market`、`domainx` |
| Excludes | 真实交易所客户端、订单状态 SSOT、市场数据值对象、策略/风控/账本逻辑 |
| Boundary with domainx | `domainx` 拥有 Order、Trade、Position、Portfolio、ExecutionReport、OrderSide/Type/State |
| Boundary with domain-market | `domain-market` 拥有 Kline/OrderBook/Funding/OpenInterest 等行情模型 |

## 3. 功能需求

| ID | 需求 |
| --- | --- |
| FR-EXC-001 | Exchange SPI 必须拆分读写能力接口，避免单个巨型 interface。 |
| FR-EXC-002 | 下单、撤单、查询请求必须表达 client id、idempotency、venue 与 instrument。 |
| FR-EXC-003 | ExchangeError 必须区分临时错误、永久错误、限速、认证、余额、精度和不支持能力。 |
| FR-EXC-004 | VenueCapability、RateLimitPolicy、VenueProfile 必须可静态描述并可测试。 |
| FR-EXC-005 | Registry 必须线程安全，支持 fake exchange 注入。 |
| FR-EXC-006 | MarketReader 必须返回 `domain-market` 类型，不重复定义行情模型。 |
| FR-EXC-007 | Order 相关返回必须采用 `domainx` 类型或短期兼容 alias，不建立第二套订单 SSOT。 |

## 4. 非功能需求

- Adapter 友好：SPI 稳定，但不绑定任何单一 vendor API。
- Fail-closed：未知能力、未知错误和不安全重试必须默认失败。
- 可测试：所有能力、错误和 retry/idempotency 语义必须可用 fake exchange 验证。

## 5. 非目标与发布门禁

- 不实现真实交易所客户端（Binance/OKX adapter 属于独立实现层）
- 不管理订单状态 SSOT（Order/ExecutionReport 归 domainx；domain-exchange 仅通过 SPI 传递）
- 不定义市场数据值对象（Kline/OrderBook/Funding 归 domain-market；domain-exchange 通过 MarketReader 返回 domain-market 类型）
- 不实现策略、风控或账本逻辑（由策略域和风控域负责）
- 不直接依赖 transport 层（HTTP client、WebSocket client 属于 adapter 实现）
- 不操作存储层（Redis/Postgres/TDengine）
- 不持有 API key/secret（由 adapter/infra 层管理）

### 发布门禁

| 门禁 | 要求 |
| --- | --- |
| 边界门禁 | 不重复拥有 `domainx` 和 `domain-market` 的公共模型。 |
| SPI 门禁 | 接口拆分后下游 adapter 可按能力实现。 |
| 错误门禁 | retry/idempotency/rate limit 有明确测试。 |
| 下游门禁 | fake exchange 与至少一个 downstream smoke 通过。 |

## 6. 消费者

- `order-engine`：通过 Exchange SPI 下单/撤单/查询
- `risk-engine`：通过 AccountReader 查询余额，通过 OrderPlacer 提交订单
- `binance`/`okx` 等 adapter：实现 Exchange SPI 接口
- 回测引擎：使用 fake exchange 模拟交易
- `domain-exchange` 的 Registry 供 kernel 启动时注册可用 venue

## 7. 功能需求

| ID | 需求 | WHEN | THEN |
|----|------|------|------|
| FR-EXC-001 | spi-segmentation | 定义 Exchange 相关接口 | 拆分为 AccountReader、OrderPlacer、OrderCanceler、OrderQuerier、MarketReader、DerivativeReader、Streamer 能力接口 |
| FR-EXC-002 | place-order | 调用 OrderPlacer.PlaceOrder | PlaceOrderRequest 必须通过 Validate()；返回 domainx.ExecutionReport |
| FR-EXC-003 | cancel-order | 调用 OrderCanceler.CancelOrder | CancelOrderRequest 统一建模，避免裸参数 |
| FR-EXC-004 | query-order | 调用 OrderQuerier.QueryOrder | 返回 domainx.Order 或 typed error |
| FR-EXC-005 | capability-check | 请求交易所不支持的能力 | 返回 ErrUnsupportedCapability，不得 panic 或返回空值 |
| FR-EXC-006 | idempotency | prod/paper 下单 | ClientID 必填；backtest 可自动生成但必须可复现 |
| FR-EXC-007 | error-classification | 交易所返回错误 | ExchangeError 区分临时/永久/限速/认证/余额/精度/不支持 |
| FR-EXC-008 | retry-semantics | 调用方收到错误 | IsRetryable/RetryAfter/IsIdempotentSafe 可判断重试策略 |
| FR-EXC-009 | registry-safe | 并发注册/查询 Exchange | Registry 线程安全；重复注册返回错误；列表排序 deterministic |
| FR-EXC-010 | market-reader | 调用 MarketReader | 返回 domain-market 类型（Kline/TickerPrice/OrderBook），不重复定义 |
| FR-EXC-011 | stream-lifecycle | ctx cancel 或 stream 关闭 | Channel 可预测关闭；不支持 WS 的 venue 返回 ErrUnsupportedCapability |
| FR-EXC-012 | order-type-alignment | 返回订单/成交 | 使用 domainx.Order/ExecutionReport 或标注 deprecated alias |

## 8. 行为约束

| ID | 规则 |
|----|------|
| BR-EXC-001 | Exchange 不支持某 capability 时返回 typed error，不得 panic 或静默空值 |
| BR-EXC-002 | prod/paper 下单必须有 ClientID，保证幂等 |
| BR-EXC-003 | adapter 必须把交易所原始错误映射为 typed ExchangeError，不暴露原始 DTO |
| BR-EXC-004 | 所有 price/qty/balance 使用 decimalx.Decimal |
| BR-EXC-005 | Balance 的 Total = Free + Locked（可选计算规则） |
| BR-EXC-006 | Registry 重复注册返回错误，不允许覆盖 |
| BR-EXC-007 | WS channel 关闭规则：ctx cancel 后 channel 可预测关闭；不允许 goroutine leak |


### Acceptance Criteria Registry

| AC ID | FR/BR Ref | Criterion |
|-------|-----------|----------|
| AC-EXC-001 | FR-EXC-001 | TC-EXC-001 | `GOWORK=off go test ./...` | |
| AC-EXC-002 | FR-EXC-002 | TC-EXC-001 | `GOWORK=off go test -race ./...` | |
| AC-EXC-003 | FR-EXC-003 | TC-EXC-001 | `GOWORK=off go test ./...` | |
| AC-EXC-004 | FR-EXC-004 | TC-EXC-001 | `GOWORK=off go test ./...` | |
| AC-EXC-005 | FR-EXC-005 | TC-EXC-002 | `GOWORK=off go test -race ./...` | |
| AC-EXC-006 | FR-EXC-006 | TC-EXC-001 | `GOWORK=off go test ./...` | |
| AC-EXC-007 | FR-EXC-007 | TC-EXC-003 | `GOWORK=off go test ./...` | |
| AC-EXC-008 | FR-EXC-008 | TC-EXC-003 | `GOWORK=off go test ./...` | |
| AC-EXC-009 | FR-EXC-009 | TC-EXC-004 | `GOWORK=off go test -race ./...` | |
| AC-EXC-010 | FR-EXC-010 | TC-EXC-007 | `GOWORK=off go test ./...` | |
| AC-EXC-011 | FR-EXC-011 | TC-EXC-005, TC-EXC-006 | `GOWORK=off go test -race ./...` | |
| AC-EXC-012 | FR-EXC-012 | TC-EXC-007 | `GOWORK=off go test ./...` | |

## 9. 接口契约

```go
// 基础身份与能力
type Venue string
type Capability string

type VenueProfile struct {
    Venue        Venue
    Capabilities []Capability
    RateLimit    RateLimitPolicy
    TimeSync     bool
}

// SPI 拆分
type AccountReader interface {
    Balances(ctx context.Context) ([]Balance, error)
}

type OrderPlacer interface {
    PlaceOrder(ctx context.Context, req PlaceOrderRequest) (domainx.ExecutionReport, error)
}

type OrderCanceler interface {
    CancelOrder(ctx context.Context, req CancelOrderRequest) (domainx.ExecutionReport, error)
}

type OrderQuerier interface {
    QueryOrder(ctx context.Context, req QueryOrderRequest) (domainx.Order, error)
}

type MarketReader interface {
    Klines(ctx context.Context, symbol string, interval domainmarket.Interval, limit int) ([]domainmarket.Bar, error)
    TickerPrice(ctx context.Context, symbol string) (domainmarket.Quote, error)
    OrderBook(ctx context.Context, symbol string, depth int) (domainmarket.OrderBook, error)
}

type DerivativeReader interface {
    Funding(ctx context.Context, symbol string) (domainmarket.Funding, error)
    OpenInterest(ctx context.Context, symbol string) (domainmarket.OpenInterest, error)
}

type Streamer interface {
    WatchOrderBook(ctx context.Context, symbol string) (<-chan domainmarket.OrderBook, error)
    WatchTrades(ctx context.Context, symbol string) (<-chan domainmarket.Tick, error)
}

type Exchange interface {
    Name() string
    Venue() Venue
    Capabilities() VenueProfile
}
```

## 10. 数据模型

```go
type PlaceOrderRequest struct {
    Symbol   string
    Side     domainx.OrderSide
    Type     domainx.OrderType
    Qty      decimalx.Qty
    Price    decimalx.Price   // limit order 必填
    ClientID string           // prod/paper 必填
    Venue    Venue
}

func (r PlaceOrderRequest) Validate() error

type CancelOrderRequest struct {
    Symbol   string
    OrderID  string
    ClientID string
    Venue    Venue
}

type QueryOrderRequest struct {
    Symbol  string
    OrderID string
    Venue   Venue
}

type Balance struct {
    Asset  string
    Free   decimalx.Decimal
    Locked decimalx.Decimal
}

func (b Balance) Total() decimalx.Decimal

type RateLimitPolicy struct {
    RequestsPerSecond int
    Burst             int
}

type VenueProfile struct {
    Venue        Venue
    Capabilities []Capability
    RateLimit    RateLimitPolicy
    TimeSync     bool
}
```

## 11. 配置模式

```yaml
domain_exchange:
  venues:
    - name: binance
      capabilities: [spot, perp, ws, funding, open_interest]
      rate_limit:
        requests_per_second: 10
        burst: 20
      time_sync: true
    - name: okx
      capabilities: [spot, perp, ws, funding, open_interest, margin]
      rate_limit:
        requests_per_second: 8
        burst: 15
      time_sync: true
```

## 12. 错误处理

| 错误 | 含义 | 调用方处理 |
|------|------|-----------|
| ErrUnsupportedCapability | venue 不支持请求的能力 | 检查 VenueProfile.Capabilities 或降级到 REST |
| ErrInvalidRequest | 请求参数验证失败 | 修正请求参数后重试 |
| ErrRejected | 交易所拒绝下单（余额不足等） | 检查余额/精度/权限 |
| ErrRateLimited | 触发限频 | 等待 RetryAfter 后重试 |
| ErrTemporary | 临时性错误（网络超时等） | 按 RetryAfter 重试 |
| ErrUnauthorized | 认证失败 | 检查 API key/secret 配置 |
| ErrNotFound | 订单/余额不存在 | 确认订单 ID 或资产 |
| ErrClockSkew | 时间偏差过大 | 同步本地时钟 |
| ErrStreamClosed | WS stream 已关闭 | 重新订阅或检查连接状态 |

## 13. 边界情况

- 交易所返回未知错误码：ExchangeError 包装原始 venue code，调用方可 errors.Is 判断已知类型
- WS stream 断连重连：adapter 层可重连，但 domain-exchange 必须暴露错误/质量信号
- 并发注册同一 venue 到 Registry：第二次注册返回错误
- partial fill 场景：fake exchange 必须支持脚本化 partial fill 响应
- ctx cancel 后 WS channel 未关闭：需 leak test 保证无 goroutine leak
- ClientID 空字符串在 prod/paper 模式：Validate() 必须拒绝

## 14. 目录结构

```text
module/domain-exchange/
  SPEC.md
  goal.md
  TRACEABILITY.md
  IMPLEMENTATION-PLAN.md
  tasks/
```

## 15. 依赖

- 允许：`kernel`（errors、contracts、lifecycle）
- 允许：`decimalx`（Price/Qty/金额）
- 允许：`domain-market`（Kline/Quote/OrderBook/Funding/OpenInterest/Tick）
- 允许：`domainx`（Order/ExecutionReport/OrderSide/OrderType/OrderState）
- 禁止：transport 层直接依赖（HTTP client、WS client）
- 禁止：存储层（Redis、Postgres、TDengine）
- 禁止：策略/风控/因子模块

## 16. 测试

- 单元测试：每个 SPI 接口独立可测
- 集成测试：PlaceOrder → CancelOrder → QueryOrder 端到端
- Contract 测试：任何 adapter 必须复用同一套 tests
- Error golden 测试：错误 wrapping 可被 errors.Is/As 识别
- Fake exchange：支持脚本化响应、延迟、错误、乱序 stream、partial fill

### 16.1 Traceability Test Cases

**TC-EXC-001:** PlaceOrderRequest 缺少 ClientID → Validate() 失败。
**TC-EXC-002:** 不支持的 capability → 返回 ErrUnsupportedCapability。
**TC-EXC-003:** 错误可分类为 retryable / non-retryable / auth / rate limit。
**TC-EXC-004:** Registry 并发注册安全且 deterministic。
**TC-EXC-005:** Fake exchange 覆盖成功、拒单、限频、partial fill、stream close。
**TC-EXC-006:** ctx cancel 后 WS channel 关闭可预测，无 goroutine leak。
**TC-EXC-007:** 返回订单/成交语义对齐 domainx 类型。

## 17. 性能预算

| 指标 | 目标 |
|------|------|
| Registry 查询 | < 1μs（内存 map） |
| PlaceOrderValidate | < 10μs |
| Error 分类 | < 1μs |

## 18. 可观测性

- 无运行时指标（领域接口层）
- ExchangeError 包含 venue code 可被上层 observex 包装
- VenueProfile 描述静态能力，供监控面板读取

## 19. 安全

- 不存储 API key/secret（由 adapter/infra 管理）
- 不连接远程服务（SPI 定义层不含网络调用）
- ClientID 幂等防止重复下单
- RateLimitPolicy 防止误操作导致限频

## 20. CI 门禁

- `GOWORK=off go test ./...`
- `GOWORK=off go test -race ./...`
- `GOWORK=off go test ./... -count=100`
- `staticcheck ./...`
- `govulncheck ./...`
- `GOWORK=off make adoption-check`（如接入 xlib-standard）
- `GOWORK=off make release-check`

## 21. 升级兼容性

- v1 SPI 接口名称和签名保持稳定
- 新增 Capability 常量为追加，不删除旧常量
- ExchangeError 子类型只可追加，不可删除或改语义
- domainexchange.Order deprecated alias 保留到 v2，迁移路径写入 MIGRATION.md

## 22. 发布 DoD

- [ ] SPEC Approved
- [ ] 所有 FR 实现并测试
- [ ] ADR-0001 订单/执行语义归属 domainx 或有明确 alias/deprecation
- [ ] Exchange capability 不支持时返回 typed error
- [ ] 下单请求有 Validate 和幂等策略
- [ ] 错误可分类为 retryable / non-retryable / auth / rate limit
- [ ] Registry 并发安全且 deterministic
- [ ] Fake exchange 覆盖成功、拒单、限频、partial fill、stream close
- [ ] 下游 order-engine/risk-engine 可基于 v1 smoke
- [ ] Version 更新为 v1.0.0
- [ ] CHANGELOG.md、MIGRATION.md、release manifest 齐全

## 23. 待解决问题

- 旧 Exchange 大接口是否保留为兼容 facade？
- domainexchange.Order 的 deprecated alias 保留到 v1.x 还是 v2？
- WS stream gap/reconnect 完整语义是否推迟到 infra 层？
- Adapter certification suite 是否纳入 v1.1？

---

### 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-15 | v1.0.0 | 初始版本：L2.5 交易所领域接口与 adapter SPI | ZoneCNH |
