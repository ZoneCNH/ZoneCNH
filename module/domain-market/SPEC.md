# domain-market v1.0.0 Spec

- Status: Approved
- Spec-Version: v1.0.0
Module-Version: v0.1.0 -> v1.0.0
Layer: L2.5 领域共享
Repository: https://github.com/ZoneCNH/domain-market
Source-Plan: /home/zone/Downloads/0615/ZoneCNH-v1.0.0-goal-execution-plans/domain-market-v1.0.0-goal-execution-plan.md
- Last-Updated: 2026-06-15

## 1. 范围

`domain-market` 定义市场数据领域模型与质量门禁，是上层行情采集、研究、回测、策略和执行服务共享的市场语义 SSOT。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | Tick、Quote、Bar、OrderBook、Instrument、Funding、OpenInterest、LongShortRatio、DataProvider、MarketDataQuality |
| Depends on | `kernel`、`decimalx` |
| Excludes | transport adapter、provider DTO、数据库 tag、策略/因子/回测逻辑、订单生命周期语义 |
| Boundary with domainx | `domainx` 拥有 OrderType、OrderSide、OrderState；`domain-market` 仅表达市场事件与行情侧方向语义 |

## 3. 功能需求

| ID | 需求 |
| --- | --- |
| FR-MKT-001 | 市场价格、数量、成交量、金额、费率等公开金融字段必须使用 `decimalx.Decimal` 或值对象。 |
| FR-MKT-002 | Tick、Quote、Bar、OrderBook 必须校验 symbol、timestamp、价格/数量边界和 bid/ask 关系。 |
| FR-MKT-003 | MarketDataQuality 必须 fail-closed，拒绝 dirty、stale、time-invalid 数据。 |
| FR-MKT-004 | Instrument 必须表达交易品种标识、市场类型、价格/数量精度和可交易状态。 |
| FR-MKT-005 | Funding、OpenInterest、LongShortRatio 必须有明确时间语义与数据来源。 |
| FR-MKT-006 | DataProvider contract 必须返回领域模型，不暴露 HTTP/WS/DB/vendor DTO。 |
| FR-MKT-007 | 与 `domainx` 重叠的订单枚举必须迁出或废弃，避免双 SSOT。 |

## 4. 非功能需求

- 质量优先：非法数据默认拒绝，不做静默修正。
- 领域纯净：公共模型中不得出现 transport、persistence 或 vendor schema tag。
- 下游稳定：v1.0.0 后公共字段含义和时间语义需保持兼容。

## 5. Non-Goals 与发布门禁

- 不实现 transport adapter（HTTP、WebSocket、Kafka 生产者/消费者）
- 不定义 provider DTO 或 vendor schema（Binance/OKX 响应格式属于 adapter/internal 层）
- 不承载持久化 tag（json/db/yaml/kafka tag 由 DTO 层添加，domain struct 禁止携带）
- 不实现策略、因子或回测逻辑（由上层策略域和回测引擎负责）
- 不管理订单生命周期语义（OrderType/OrderSide/OrderState 归 domainx）
- 不连接远程服务、不读取密钥、不操作存储层（Redis/Postgres/TDengine）
- 不实现数据采集调度或 provider 注册逻辑（由数据采集层负责）

### 发布门禁

| 门禁 | 要求 |
| --- | --- |
| 精度门禁 | public price/qty/money/rate fields 无 `float64`。 |
| 边界门禁 | 不含 HTTP/WS/DB/Kafka/TDengine/vendor DTO 泄漏。 |
| 质量门禁 | dirty/stale/time-invalid 数据有 fail-closed 测试。 |
| 下游门禁 | `domain-exchange` 可采用 market data types。 |

## 6. Consumers

- 策略/回测引擎：通过 MarketEventEnvelope 消费质量门禁后的市场数据
- `domain-exchange`：MarketReader 返回 domain-market 行情类型
- 因子引擎：基于 Tick/Bar/OrderBook 计算因子
- 数据采集层（provider）：构造 domain-market 值对象并通过 DataProvider 暴露
- 研究平台：查询历史 Bar/Tick 和 Instrument 信息

## 7. Functional Requirements

| ID | 需求 | WHEN | THEN |
|----|------|------|------|
| FR-MKT-001 | decimal-precision | 定义价格/数量/金额/费率字段 | 使用 decimalx.Decimal 或值对象，Public API 禁止 float64 |
| FR-MKT-002 | tick-validate | 构造或校验 Tick | Symbol/Venue/Price/Qty/Timestamp/Side/Quality 合法 |
| FR-MKT-003 | quote-validate | 构造或校验 Quote | bid/ask 非负，ask >= bid，timestamp 必填 |
| FR-MKT-004 | bar-validate | 构造或校验 Bar | High >= max(Open,Close,Low)，Low <= min(Open,Close,High)，OpenTime < CloseTime，Volume/Turnover 非负 |
| FR-MKT-005 | orderbook-validate | 构造或校验 OrderBook | Bids 价格降序，Asks 价格升序，bid < ask，数量非负，seq 连续 |
| FR-MKT-006 | instrument-validate | 构造或校验 Instrument | precision/tick/minQty/minNotional/status 合法 |
| FR-MKT-007 | derivative-validate | 构造或校验 Funding/OpenInterest/LongShortRatio | 时间必填，decimal 字段合法，来源质量标签完整 |
| FR-MKT-008 | quality-gate | 策略层消费市场数据 | 只能接受 MarketEventEnvelope；EventTime/ReceivedAt/Symbol/Venue 必填 |
| FR-MKT-009 | quality-metrics | 校验 MarketDataQuality | Channel/Latency/IsReliable 与 DegradeReason 一致 |
| FR-MKT-010 | provider-contract | 调用 DataProvider | 返回领域模型，不暴露 HTTP/WS/DB/vendor DTO |
| FR-MKT-011 | stale-gate | 数据超过 stale threshold | fail-closed，拒绝 stale 数据进入策略 |
| FR-MKT-012 | future-gate | EventTime 晚于 ReceivedAt/DecisionTime | 在容忍窗口外拒绝 |
| FR-MKT-013 | domain-no-transport | 定义 domain struct | 不含 json/db/yaml/kafka tag；transport schema 属 DTO 层 |
| FR-MKT-014 | domainx-boundary | 与 domainx 枚举归属 | Side 表达市场事件方向可保留；OrderType/OrderSide/OrderState 归 domainx |

## 8. Business Rules

| ID | 规则 |
|----|------|
| BR-MKT-001 | 所有价格/数量/金额/费率字段使用 decimalx.Decimal，Public API 禁止 float64 |
| BR-MKT-002 | domain struct 不含 transport/persistence/vendor tag |
| BR-MKT-003 | 非法数据默认拒绝，不做静默修正（fail-closed） |
| BR-MKT-004 | 策略层不直接消费 Bar/Tick 原始结构体，必须通过 MarketEventEnvelope |
| BR-MKT-005 | stale/future 数据 fail-closed，DegradeReason + metrics 暴露，不可靠数据不静默进入策略 |
| BR-MKT-006 | domain-market 仅表达行情语义，订单生命周期语义归 domainx |

## 9. Interface Contract

```go
type DataProvider interface {
    LatestQuote(ctx context.Context, symbol string) (Quote, error)
    LatestBar(ctx context.Context, symbol string, interval Interval) (Bar, error)
    HistoricalBars(ctx context.Context, req HistoricalBarsRequest) ([]Bar, error)
}

type HistoricalBarsRequest struct {
    Symbol   string
    Interval Interval
    Limit    int
    Start    time.Time
    End      time.Time
}

func (r HistoricalBarsRequest) Validate() error

type MarketEventEnvelope struct {
    Event      interface{}   // Bar 或 Tick 二选一
    EventTime  time.Time
    ReceivedAt time.Time
    Symbol     string
    Venue      Venue
    Quality    MarketDataQuality
}

func (e MarketEventEnvelope) Validate() error
```

## 10. Data Model

```go
type Tick struct {
    Symbol    string
    Venue     Venue
    Price     decimalx.Price
    Qty       decimalx.Qty
    Side      Side
    Timestamp time.Time
    Quality   MarketDataQuality
}

type Quote struct {
    Symbol    string
    Venue     Venue
    BidPrice  decimalx.Price
    BidQty    decimalx.Qty
    AskPrice  decimalx.Price
    AskQty    decimalx.Qty
    Timestamp time.Time
    Quality   MarketDataQuality
}

type Bar struct {
    Symbol     string
    Venue      Venue
    Interval   Interval
    OpenTime   time.Time
    CloseTime  time.Time
    Open       decimalx.Price
    High       decimalx.Price
    Low        decimalx.Price
    Close      decimalx.Price
    Volume     decimalx.Decimal
    Turnover   decimalx.Decimal
    IsFinal    bool
    Quality    MarketDataQuality
}

type OrderBook struct {
    Symbol    string
    Venue     Venue
    Bids      []PriceLevel
    Asks      []PriceLevel
    Seq       int64
    Timestamp time.Time
    Quality   MarketDataQuality
}

type PriceLevel struct {
    Price decimalx.Price
    Qty   decimalx.Qty
}

type Instrument struct {
    Symbol      string
    Venue       Venue
    BaseAsset   string
    QuoteAsset  string
    PriceTick   decimalx.Decimal
    QtyStep     decimalx.Decimal
    MinQty      decimalx.Decimal
    MinNotional decimalx.Decimal
    Status      InstrumentStatus
}

type Funding struct {
    Symbol    string
    Venue     Venue
    Rate      decimalx.Decimal
    Timestamp time.Time
    Quality   MarketDataQuality
}

type OpenInterest struct {
    Symbol    string
    Venue     Venue
    Value     decimalx.Decimal
    Timestamp time.Time
    Quality   MarketDataQuality
}

type LongShortRatio struct {
    Symbol    string
    Venue     Venue
    LongRatio decimalx.Decimal
    Timestamp time.Time
    Quality   MarketDataQuality
}

type MarketDataQuality struct {
    Channel       string
    Latency       time.Duration
    IsReliable    bool
    IsRecovered   bool
    DegradeReason string
}
```

## 11. Config Schema

```yaml
domain_market:
  quality_gate:
    stale_threshold_sec: 30
    future_tolerance_sec: 5
    fail_closed: true
  provider:
    default_limit: 500
  metrics:
    stale_data_rejected: true
    future_data_rejected: true
    quality_violation: true
```

## 12. Error Handling

| 错误 | 含义 | 调用方处理 |
|------|------|-----------|
| ErrInvalidSymbol | Symbol 为空或非法 | 检查 Symbol 格式 |
| ErrInvalidInterval | Interval 不合法 | 检查 Interval 枚举值 |
| ErrNoData | 无数据返回 | 确认时间范围和数据源 |
| ErrStaleData | 数据超过 stale threshold | 检查数据新鲜度或调整 threshold |
| ErrOutOfOrder | 数据时序错误 | 检查数据排序和 seq 连续性 |
| ErrQualityViolation | 数据质量不达标 | 查看 MarketDataQuality.DegradeReason |
| ErrFutureData | EventTime 晚于容忍窗口 | 检查时钟同步 |

## 13. Edge Cases

- Bar 的 High 恰好等于 Open（High >= max(Open,Close,Low) 边界）
- OrderBook 无 Bid 或无 Ask（单边挂空）
- Tick 的 Price 为零（是否允许取决于 instrument 规则）
- MarketEventEnvelope 中 Bar 和 Tick 同时为空或同时非空
- HistoricalBarsRequest 的 Start > End
- IsFinal=false 的 Bar 被更新后 OHLC 不变量仍成立
- OrderBook seq 不连续（gap）时的处理策略
- 同一 Symbol 同一 Timestamp 收到多个 Tick

## 14. Directory Structure

```text
module/domain-market/
  SPEC.md
  goal.md
  TRACEABILITY.md
  IMPLEMENTATION-PLAN.md
  tasks/
```

## 15. Dependencies

- 允许：`kernel`（errors、contracts）
- 允许：`decimalx`（Price/Qty/金额/费率）
- 禁止：transport 层（HTTP、WS、Kafka schema）
- 禁止：存储层（Redis、Postgres、TDengine）
- 禁止：策略/因子/回测引擎
- 禁止：vendor DTO（Binance/OKX 响应格式）
- 禁止：domain 执行域（domainx 的 OrderType/OrderState）

## 16. Testing

- 单元测试：每个值对象 Validate 的 valid/invalid table tests
- 质量门禁测试：MarketEventEnvelope.Validate、stale/future/recovered gate
- Fuzz 测试：Bar OHLC、OrderBook sorting、Interval parse、QualityGate envelope
- Race 测试：并发读取同一 Bar/Tick/OrderBook
- Golden/回归测试：历史 bug case 固化
- Lint 测试：domain struct 禁止 tag；price/qty 禁止 float

### 16.1 Traceability Test Cases

**TC-MKT-001:** 价格/数量字段使用 decimalx（compile check + lint）。
**TC-MKT-002:** domain struct 不含 transport/db tag。
**TC-MKT-003:** Bar/Quote/OrderBook 不变量 Validate 和测试通过。
**TC-MKT-004:** 策略入口只能消费 MarketEventEnvelope。
**TC-MKT-005:** DataProvider 契约稳定，fake provider 可复用。
**TC-MKT-006:** 与 domainx 无执行枚举重复归属。
**TC-MKT-007:** stale data 被 fail-closed 拒绝。
**TC-MKT-008:** future data 在容忍窗口外被拒绝。

## 17. Performance Budget

| 指标 | 目标 |
|------|------|
| Tick Validate | < 500ns |
| Bar Validate | < 1μs |
| OrderBook Validate（100 levels） | < 5μs |
| MarketEventEnvelope Validate | < 1μs |
| FilterMacroPointsForBacktest（1000 点） | < 1ms |

## 18. Observability

- Metrics：stale_data_rejected、future_data_rejected、quality_violation、data_freshness
- MarketDataQuality.DegradeReason 暴露降级原因
- 证据报告格式：JSON
- 数据质量指标 Prometheus adapter 放 adapter 层，不在 domain 内

## 19. Security

- 不读取密钥
- 不连接远程服务
- Fail-closed 默认策略：非法数据、时序错误、质量不达标均返回错误
- Validate 引入后旧数据不通过时：提供 ValidateStrict/ValidateLegacy 分层，但策略入口必须 strict

## 20. CI Gate

- `GOWORK=off go test ./...`
- `GOWORK=off go test -race ./...`
- `GOWORK=off go test ./... -count=100`
- `staticcheck ./...`
- `govulncheck ./...`
- Lint：domain struct 禁止 tag；price/qty 禁止 float
- `GOWORK=off make adoption-check`（如接入 xlib-standard）

## 21. Upgrade Compatibility

- v1 值对象字段语义保持稳定
- 新增枚举值为追加，不删除旧枚举
- ValidateStrict/ValidateLegacy 可共存，v2 删除 Legacy
- domainx 枚举迁移（OrderType/Side）为破坏性变更，须 deprecated alias + MIGRATION.md

## 22. Release DoD

- [ ] SPEC Approved
- [ ] 所有 FR 实现并测试
- [ ] 所有价格/数量/金额/费率字段使用 decimalx（compile check + lint）
- [ ] domain struct 不带 transport/db tag（lint test）
- [ ] Bar/Quote/OrderBook 不变量有 Validate 和测试
- [ ] 策略入口只能消费 MarketEventEnvelope（tests + docs）
- [ ] DataProvider 契约稳定，fake provider 可复用
- [ ] 与 domainx 无执行枚举重复归属（ADR + compile smoke）
- [ ] 发布 manifest 含 CI 证据
- [ ] Version 更新为 v1.0.0
- [ ] CHANGELOG.md、MIGRATION.md、release manifest 齐全

## 23. Open Questions

- Side 枚举归属：domain-market 仅表达市场事件方向，还是统一到 domainx？
- 交易所 interval 映射表是否纳入 v1.1？
- 深度增量 merge helper 是否纳入 v1.1？
- 数据质量指标 Prometheus adapter 是否在 adapter 层实现？
