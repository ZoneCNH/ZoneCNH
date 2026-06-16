# domain-market 规格

- Status: Approved
- Spec-Version: v1.1.0
- Last-Updated: 2026-06-17
- Layer: L2.5 领域共享
- Module-Version: v1.1.0
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `kernel`, `decimalx`

> 公开投影 caveat：Status=Approved 与 100.0% 覆盖证据不等同于 factory-grade；机器事实层保持 factory=false。

---

## 1. 摘要

`domain-market` 定义市场数据领域模型与质量门禁，是上层行情采集、研究、回测、策略和执行服务共享的市场语义 SSOT。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | Tick、Quote、Bar、OrderBook、Instrument、ProductLine、InstrumentKey、MarketFactEnvelope、Funding、OpenInterest、LongShortRatio、DataProvider、MarketDataQuality、MarketEventEnvelope（MarketFactEnvelope 的 deprecated 别名） |
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
| FR-MKT-015 | ProductLine 枚举必须覆盖 spot、um_perp、cm_perp、option 四产品线，提供 IsValid 校验。 |
| FR-MKT-016 | InstrumentKey 必须提供无碰撞标的身份，Symbol 不是全局唯一键。 |
| FR-MKT-017 | MarketFactEnvelope 必须定义 canonical wrapper 与时间语义。 |

## 4. 非功能需求

- 质量优先：非法数据默认拒绝，不做静默修正。
- 领域纯净：公共模型中不得出现 transport、persistence 或 vendor schema tag。
- 下游稳定：v1.0.0 后公共字段含义和时间语义需保持兼容。

## 5. 非目标与发布门禁

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

## 6. 消费者

- 策略/回测引擎：通过 MarketEventEnvelope 消费质量门禁后的市场数据
- `domain-exchange`：MarketReader 返回 domain-market 行情类型
- 因子引擎：基于 Tick/Bar/OrderBook 计算因子
- 数据采集层（provider）：构造 domain-market 值对象并通过 DataProvider 暴露
- 研究平台：查询历史 Bar/Tick 和 Instrument 信息

## 7. 功能需求

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
| FR-MKT-015 | product-line-canonical | 构造或校验 ProductLine | IsValid 对 spot/um_perp/cm_perp/option 返回 true，其他值返回 false |
| FR-MKT-016 | instrument-key-canonical | 构造或校验 InstrumentKey | Venue/ProductLine/Symbol 必填；期权须提供 Expiry/Strike/OptionType |
| FR-MKT-017 | market-fact-envelope | 构造或校验 MarketFactEnvelope | InstrumentKey/EventType/EventTime/ReceivedAt/Source/Quality 必填，缺失时 fail-closed |

## 8. 行为约束

| ID | 规则 |
|----|------|
| BR-MKT-001 | 所有价格/数量/金额/费率字段使用 decimalx.Decimal，Public API 禁止 float64 |
| BR-MKT-002 | domain struct 不含 transport/persistence/vendor tag |
| BR-MKT-003 | 非法数据默认拒绝，不做静默修正（fail-closed） |
| BR-MKT-004 | 策略层不直接消费 Bar/Tick 原始结构体，必须通过 MarketEventEnvelope |
| BR-MKT-005 | stale/future 数据 fail-closed，DegradeReason + metrics 暴露，不可靠数据不静默进入策略 |
| BR-MKT-006 | domain-market 仅表达行情语义，订单生命周期语义归 domainx |
| BR-MKT-008 | canonical event type 使用 exchange-neutral 命名；vendor stream 名称不得成为领域事件枚举 |


### Acceptance Criteria Registry

| AC ID | FR/BR Ref | Criterion |
|-------|-----------|----------|
| AC-MKT-001 | FR-MKT-001 | TC-MKT-001 | `go vet` + `staticcheck` | |
| AC-MKT-002 | FR-MKT-002 | TC-MKT-002 | `go test -run TestTick` | |
| AC-MKT-004 | FR-MKT-006 | TC-MKT-004 | `go test -run TestInstrument` | |
| AC-MKT-005 | FR-MKT-007 | TC-MKT-005 | `go test -run "TestFunding\|TestOI\|TestLSR"` | |
| AC-MKT-003 | FR-MKT-008 | TC-MKT-004 | `go test -run TestMarketEventEnvelope` | |
| AC-MKT-006 | FR-MKT-010 | TC-MKT-005 | `staticcheck` boundary scan | |
| AC-MKT-007 | FR-MKT-014 | TC-MKT-006 | `compile smoke` + ADR | |
| AC-MKT-008 | FR-MKT-015 | TC-MKT-009 | `go test -run TestProductLine` | |
| AC-MKT-009 | FR-MKT-016 | TC-MKT-010 | `go test -run TestInstrumentKey` | |
| AC-MKT-010 | FR-MKT-017 | TC-MKT-011 | `go test -run TestMarketFactEnvelope` | |

## 9. 接口契约

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

// MarketEventEnvelope is deprecated; use MarketFactEnvelope.
type MarketEventEnvelope = MarketFactEnvelope
```

## 10. 数据模型

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


// ProductLine canonical 产品线枚举
type ProductLine string

const (
	ProductLineSpot   ProductLine = "spot"
	ProductLineUMPerp ProductLine = "um_perp"
	ProductLineCMPerp ProductLine = "cm_perp"
	ProductLineOption ProductLine = "option"
)

func (p ProductLine) IsValid() bool {
	switch p {
	case ProductLineSpot, ProductLineUMPerp, ProductLineCMPerp, ProductLineOption:
		return true
	default:
		return false
	}
}

// InstrumentKey 无碰撞标的身份
type InstrumentKey struct {
	Venue           string            // "binance"
	ProductLine     ProductLine
	InstrumentType  string            // spot/perpetual/future/option
	Symbol          string            // "BTCUSDT"
	BaseAsset       string
	QuoteAsset      string
	MarginAsset     string
	SettlementAsset string
	ContractCode    string
	Expiry          *time.Time
	Strike          *decimalx.Decimal
	OptionType      string            // "call"/"put"
}

func (k InstrumentKey) Validate() error {
	if k.Venue == "" || k.Symbol == "" {
		return fmt.Errorf("domain-market: InstrumentKey Venue/Symbol required")
	}
	if !k.ProductLine.IsValid() {
		return fmt.Errorf("domain-market: invalid ProductLine: %s", k.ProductLine)
	}
	if k.ProductLine == ProductLineOption && (k.Expiry == nil || k.Strike == nil || k.OptionType == "") {
		return fmt.Errorf("domain-market: options require Expiry/Strike/OptionType")
	}
	return nil
}

// MarketFactEnvelope canonical normalized market fact wrapper
type MarketFactEnvelope struct {
	EventID      string
	InstrumentKey InstrumentKey
	EventType    string            // trade/kline/bookTicker/depthUpdate/markPrice/fundingRate/openInterest/longShortRatio
	EventTime    time.Time
	ReceivedAt   time.Time
	AvailableAt  time.Time
	DecisionTime time.Time
	Payload      interface{}
	Quality      MarketDataQuality
	Source       string
}

func (e MarketFactEnvelope) Validate() error {
	if e.InstrumentKey.Venue == "" || e.EventType == "" || e.Source == "" {
		return fmt.Errorf("domain-market: MarketFactEnvelope required fields missing")
	}
	if e.EventTime.IsZero() || e.ReceivedAt.IsZero() {
		return fmt.Errorf("domain-market: MarketFactEnvelope time fields required")
	}
	return nil
}

// MarketEventEnvelope deprecated alias for MarketFactEnvelope
type MarketEventEnvelope = MarketFactEnvelope

type MarketDataQuality struct {
    Channel       string
    Latency       time.Duration
    IsReliable    bool
    IsRecovered   bool
    DegradeReason string
}
```

### 10.1 Binance C/S ingestion canonical 语义

本节定义 Binance C/S ingestion 链路必须使用的 canonical 语义。

#### ProductLine 映射

| Binance 产品线 | canonical | 说明 |
|---|---|---|
| Spot | `spot` | 现货 |
| USDⓈ-M Perpetual | `um_perp` | U 本位永续 |
| COIN-M Perpetual | `cm_perp` | 币本位永续 |
| Options | `option` | 期权 |

Adapter 不得使用 `usdm_futures`/`coinm_futures` 等非 canonical 命名。

#### InstrumentKey 最小维度

| 维度 | Spot | UMPerp | CMPerp | Options |
|---|---|---|---|---|
| venue | ✅ | ✅ | ✅ | ✅ |
| product_line | ✅ | ✅ | ✅ | ✅ |
| instrument_type | ✅ | ✅ | ✅ | ✅ |
| symbol | ✅ | ✅ | ✅ | ✅ |
| base_asset | ✅ | ✅ | ✅ | ✅ |
| quote_asset | ✅ | ✅ | ✅ | ✅ |
| margin_asset | — | ✅ | ✅ | ✅ |
| settlement_asset | — | ✅ | ✅ | ✅ |
| contract_code | — | ✅ | ✅ | ✅ |
| expiry | — | — | — | ✅ |
| strike | — | — | — | ✅ |
| option_type | — | — | — | ✅ |

`symbol` 不是全局唯一键。缺必需维度时 adapter 必须拒绝或降级为 dirty。

**碰撞示例**：Spot `BTCUSDT` (spot) vs USDⓈ-M `BTCUSDT` (um_perp) → product_line 不同，不碰撞。

#### MarketFactEnvelope 事件类型映射

| Binance Stream | EventType | Payload |
|---|---|---|
| `aggTrade`/`trade` | `trade` | Tick |
| `kline_*` | `kline` | Bar |
| `depthUpdate` | `depthUpdate` | OrderBook |
| `bookTicker` | `bookTicker` | Quote |
| `markPrice` | `markPrice` | Funding |
| `fundingRate` | `fundingRate` | Funding |
| `openInterest` | `openInterest` | OpenInterest |
| `longShortRatio` | `longShortRatio` | LongShortRatio |

canonical event type 使用 exchange-neutral 命名（BR-MKT-008）。vendor stream 名称仅保留为 source metadata。

#### 时间语义

| 字段 | 语义 | 来源 |
|---|---|---|
| EventTime | 交易所事件时间 | Binance `E` 字段 |
| ReceivedAt | adapter 接收时间 | `time.Now()` on arrival |
| AvailableAt | quality gate 后可消费时间 | domain-market gate |
| DecisionTime | 策略决策时间点 | 回测引擎设置 |

质量规则：`InstrumentKey`/`EventType`/`EventTime`/`ReceivedAt`/`Source`/`Quality` 缺失时 `Validate` fail-closed。

## 11. 配置模式

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

## 12. 错误处理

| 错误 | 含义 | 调用方处理 |
|------|------|-----------|
| ErrInvalidSymbol | Symbol 为空或非法 | 检查 Symbol 格式 |
| ErrInvalidInterval | Interval 不合法 | 检查 Interval 枚举值 |
| ErrNoData | 无数据返回 | 确认时间范围和数据源 |
| ErrStaleData | 数据超过 stale threshold | 检查数据新鲜度或调整 threshold |
| ErrOutOfOrder | 数据时序错误 | 检查数据排序和 seq 连续性 |
| ErrQualityViolation | 数据质量不达标 | 查看 MarketDataQuality.DegradeReason |
| ErrFutureData | EventTime 晚于容忍窗口 | 检查时钟同步 |

## 13. 边界情况

- Bar 的 High 恰好等于 Open（High >= max(Open,Close,Low) 边界）
- OrderBook 无 Bid 或无 Ask（单边挂空）
- Tick 的 Price 为零（是否允许取决于 instrument 规则）
- MarketEventEnvelope 中 Bar 和 Tick 同时为空或同时非空
- HistoricalBarsRequest 的 Start > End
- IsFinal=false 的 Bar 被更新后 OHLC 不变量仍成立
- OrderBook seq 不连续（gap）时的处理策略
- 同一 Symbol 同一 Timestamp 收到多个 Tick

## 14. 目录结构

```text
module/domain-market/
  SPEC.md
  goal.md
  TRACEABILITY.md
  IMPLEMENTATION-PLAN.md
  tasks/
```

## 15. 依赖

- 允许：`kernel`（errors、contracts）
- 允许：`decimalx`（Price/Qty/金额/费率）
- 禁止：transport 层（HTTP、WS、Kafka schema）
- 禁止：存储层（Redis、Postgres、TDengine）
- 禁止：策略/因子/回测引擎
- 禁止：vendor DTO（Binance/OKX 响应格式）
- 禁止：domain 执行域（domainx 的 OrderType/OrderState）

## 16. 测试

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
**TC-MKT-009:** ProductLine IsValid 对合法产品线返回 true，其他值返回 false。
**TC-MKT-010:** InstrumentKey Validate 各维度组合正确拒绝或通过。
**TC-MKT-011:** MarketFactEnvelope Validate 缺失必填字段 fail-closed。

## 17. 性能预算

| 指标 | 目标 |
|------|------|
| Tick Validate | < 500ns |
| Bar Validate | < 1μs |
| OrderBook Validate（100 levels） | < 5μs |
| MarketEventEnvelope Validate | < 1μs |
| FilterMacroPointsForBacktest（1000 点） | < 1ms |

## 18. 可观测性

- Metrics：stale_data_rejected、future_data_rejected、quality_violation、data_freshness
- MarketDataQuality.DegradeReason 暴露降级原因
- 证据报告格式：JSON
- 数据质量指标 Prometheus adapter 放 adapter 层，不在 domain 内

## 19. 安全

- 不读取密钥
- 不连接远程服务
- Fail-closed 默认策略：非法数据、时序错误、质量不达标均返回错误
- Validate 引入后旧数据不通过时：提供 ValidateStrict/ValidateLegacy 分层，但策略入口必须 strict

## 20. CI 门禁

- `GOWORK=off go test ./...`
- `GOWORK=off go test -race ./...`
- `GOWORK=off go test ./... -count=100`
- `staticcheck ./...`
- `govulncheck ./...`
- Lint：domain struct 禁止 tag；price/qty 禁止 float
- `GOWORK=off make adoption-check`（如接入 xlib-standard）

## 21. 升级兼容性

- v1 值对象字段语义保持稳定
- 新增枚举值为追加，不删除旧枚举
- ValidateStrict/ValidateLegacy 可共存，v2 删除 Legacy
- domainx 枚举迁移（OrderType/Side）为破坏性变更，须 deprecated alias + MIGRATION.md

## 22. 发布 DoD

- [ ] SPEC Approved
- [ ] 所有 FR 实现并测试
- [ ] 所有价格/数量/金额/费率字段使用 decimalx（compile check + lint）
- [ ] domain struct 不带 transport/db tag（lint test）
- [ ] Bar/Quote/OrderBook 不变量有 Validate 和测试
- [ ] 策略入口只能消费 MarketEventEnvelope（tests + docs）
- [ ] DataProvider 契约稳定，fake provider 可复用
- [ ] 与 domainx 无执行枚举重复归属（ADR + compile smoke）
- [ ] 发布 manifest 含 CI 证据
- [ ] Version 更新为 v1.1.0
- [ ] CHANGELOG.md、MIGRATION.md、release manifest 齐全

## 23. 待解决问题

- Side 枚举归属：domain-market 仅表达市场事件方向，还是统一到 domainx？
- 交易所 interval 映射表是否纳入 v1.1？
- 深度增量 merge helper 是否纳入 v1.1？
- 数据质量指标 Prometheus adapter 是否在 adapter 层实现？

---

### 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-15 | v1.0.0 | 初始版本：L2.5 市场数据领域模型与质量门禁 | ZoneCNH |
| 2026-06-17 | v1.0.1 | 审计修复：补充 ProductLine、InstrumentKey、MarketFactEnvelope（MarketEventEnvelope 别名）类型定义 | ZoneCNH |
| 2026-06-17 | v1.1.0 | canonical 类型规范化：ProductLine 枚举 spot/um_perp/cm_perp/option；InstrumentKey 13维+Validate；MarketFactEnvelope canonical wrapper+时间语义；§10.1 Binance C/S ingestion 语义；FR-MKT-017/BR-MKT-008/AC/TC 补齐 | ZoneCNH |
| 2026-06-17 | v1.1.0 | canonical 类型重构：ProductLine 枚举值对齐跨模块规范（um_perp/cm_perp/option 替代 usdm_futures/coinm_futures/options）；新增 IsValid()；InstrumentKey 重构为 Venue/InstrumentType 维度矩阵；新增 BR-MKT-008 exchange-neutral 命名约束 | ZoneCNH |
