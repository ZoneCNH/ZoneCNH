package domainmarket

import (
	"encoding/json"
	"fmt"
	"time"
)

// ---- Canonical Types (SPEC v1.1.0) ----

// ProductLine 产品线枚举（跨模块 canonical 值）
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

func (p ProductLine) IsDerivative() bool {
	return p == ProductLineUMPerp || p == ProductLineCMPerp || p == ProductLineOption
}

func (p ProductLine) String() string { return string(p) }

// Decimal is a dependency-free decimal representation for canonical values.
// It preserves exact text form without pulling in a third-party decimal package.
type Decimal string

func (d Decimal) String() string { return string(d) }

// InstrumentKey 无碰撞标的身份
type InstrumentKey struct {
	Venue           string
	ProductLine     ProductLine
	InstrumentType  string // spot, perpetual, future, option
	Symbol          string
	BaseAsset       string
	QuoteAsset      string
	MarginAsset     string
	SettlementAsset string
	ContractCode    string
	Expiry          *time.Time
	Strike          *Decimal
	OptionType      string // "call" / "put"
}

func (k InstrumentKey) Validate() error {
	if k.Venue == "" {
		return fmt.Errorf("domain-market: InstrumentKey.Venue is required")
	}
	if k.Symbol == "" {
		return fmt.Errorf("domain-market: InstrumentKey.Symbol is required")
	}
	if !k.ProductLine.IsValid() {
		return fmt.Errorf("domain-market: invalid ProductLine: %s", k.ProductLine)
	}
	if k.ProductLine == ProductLineOption {
		if k.Expiry == nil {
			return fmt.Errorf("domain-market: options require Expiry")
		}
		if k.Strike == nil {
			return fmt.Errorf("domain-market: options require Strike")
		}
		if k.OptionType != "call" && k.OptionType != "put" {
			return fmt.Errorf("domain-market: options require OptionType=call|put, got %s", k.OptionType)
		}
	}
	return nil
}

func (k InstrumentKey) String() string {
	return fmt.Sprintf("%s:%s:%s", k.Venue, k.ProductLine, k.Symbol)
}

// EventType 跨交易所 canonical 事件类型（exchange-neutral 命名）
type EventType string

const (
	EventTypeTrade          EventType = "trade"
	EventTypeKline          EventType = "kline"
	EventTypeBookTicker     EventType = "bookTicker"
	EventTypeDepthUpdate    EventType = "depthUpdate"
	EventTypeMarkPrice      EventType = "markPrice"
	EventTypeFundingRate    EventType = "fundingRate"
	EventTypeOpenInterest   EventType = "openInterest"
	EventTypeLongShortRatio EventType = "longShortRatio"
)

func (e EventType) IsValid() bool {
	switch e {
	case EventTypeTrade, EventTypeKline, EventTypeBookTicker,
		EventTypeDepthUpdate, EventTypeMarkPrice, EventTypeFundingRate,
		EventTypeOpenInterest, EventTypeLongShortRatio:
		return true
	default:
		return false
	}
}

// MarketDataQuality carries source quality metadata.
type MarketDataQuality struct {
	Latency       time.Duration
	IsReliable    bool
	IsRecovered   bool
	DegradeReason string
}

// MarketFactEnvelope canonical normalized market fact wrapper
type MarketFactEnvelope struct {
	EventID       string
	InstrumentKey InstrumentKey
	EventType     EventType
	EventTime     time.Time
	ReceivedAt    time.Time
	AvailableAt   time.Time
	DecisionTime  time.Time
	Source        string
	Quality       MarketDataQuality
	Payload       json.RawMessage
}

func (e MarketFactEnvelope) Validate() error {
	if e.EventID == "" {
		return fmt.Errorf("domain-market: MarketFactEnvelope.EventID is required")
	}
	if err := e.InstrumentKey.Validate(); err != nil {
		return fmt.Errorf("domain-market: %w", err)
	}
	if !e.EventType.IsValid() {
		return fmt.Errorf("domain-market: invalid EventType: %s", e.EventType)
	}
	if e.EventTime.IsZero() {
		return fmt.Errorf("domain-market: EventTime is required")
	}
	if e.ReceivedAt.IsZero() {
		return fmt.Errorf("domain-market: ReceivedAt is required")
	}
	if e.Source == "" {
		return fmt.Errorf("domain-market: Source is required")
	}
	return nil
}

func (e MarketFactEnvelope) EventAge() time.Duration {
	return e.ReceivedAt.Sub(e.EventTime)
}

func (e MarketFactEnvelope) EndToEndLatency() time.Duration {
	return e.AvailableAt.Sub(e.EventTime)
}

// MarketEventEnvelope is deprecated; use MarketFactEnvelope.
type MarketEventEnvelope = MarketFactEnvelope
