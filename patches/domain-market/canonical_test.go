package domainmarket

import (
	"testing"
	"time"
)

func TestProductLine_IsValid(t *testing.T) {
	tests := []struct {
		name  string
		pl    ProductLine
		valid bool
	}{
		{"spot", ProductLineSpot, true},
		{"um_perp", ProductLineUMPerp, true},
		{"cm_perp", ProductLineCMPerp, true},
		{"option", ProductLineOption, true},
		{"empty", ProductLine(""), false},
		{"invalid", ProductLine("futures"), false},
		{"old_usdm", ProductLine("usdm_futures"), false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := tt.pl.IsValid(); got != tt.valid {
				t.Errorf("ProductLine(%q).IsValid() = %v, want %v", tt.pl, got, tt.valid)
			}
		})
	}
}

func TestProductLine_IsDerivative(t *testing.T) {
	tests := []struct {
		name string
		pl   ProductLine
		want bool
	}{
		{"spot", ProductLineSpot, false},
		{"um_perp", ProductLineUMPerp, true},
		{"cm_perp", ProductLineCMPerp, true},
		{"option", ProductLineOption, true},
		{"invalid", ProductLine("futures"), false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := tt.pl.IsDerivative(); got != tt.want {
				t.Errorf("ProductLine(%q).IsDerivative() = %v, want %v", tt.pl, got, tt.want)
			}
		})
	}
}

func TestDecimal_String(t *testing.T) {
	if got := Decimal("50000.125").String(); got != "50000.125" {
		t.Fatalf("Decimal.String() = %q, want %q", got, "50000.125")
	}
}

func TestInstrumentKey_Validate(t *testing.T) {
	validKey := InstrumentKey{
		Venue: "binance", ProductLine: ProductLineSpot, Symbol: "BTCUSDT",
	}
	if err := validKey.Validate(); err != nil {
		t.Errorf("valid key should pass: %v", err)
	}

	// missing venue
	if err := (InstrumentKey{Symbol: "BTCUSDT", ProductLine: ProductLineSpot}).Validate(); err == nil {
		t.Error("missing Venue should fail")
	}
	// missing symbol
	if err := (InstrumentKey{Venue: "binance", ProductLine: ProductLineSpot}).Validate(); err == nil {
		t.Error("missing Symbol should fail")
	}
	// invalid product line
	if err := (InstrumentKey{Venue: "binance", Symbol: "BTCUSDT", ProductLine: "futures"}).Validate(); err == nil {
		t.Error("invalid ProductLine should fail")
	}

	// options require expiry/strike/optionType
	now := time.Now()
	optKey := InstrumentKey{
		Venue: "binance", ProductLine: ProductLineOption, Symbol: "BTC-1231-50000-C",
		Expiry: &now, Strike: ptrDecimal(Decimal("50000")), OptionType: "call",
	}
	if err := optKey.Validate(); err != nil {
		t.Errorf("valid option key should pass: %v", err)
	}

	missingExpiry := optKey
	missingExpiry.Expiry = nil
	if err := missingExpiry.Validate(); err == nil {
		t.Error("option key missing Expiry should fail")
	}

	missingStrike := optKey
	missingStrike.Strike = nil
	if err := missingStrike.Validate(); err == nil {
		t.Error("option key missing Strike should fail")
	}

	invalidOptionType := optKey
	invalidOptionType.OptionType = "binary"
	if err := invalidOptionType.Validate(); err == nil {
		t.Error("option key with invalid OptionType should fail")
	}
}

func TestInstrumentKey_String(t *testing.T) {
	key := InstrumentKey{Venue: "binance", ProductLine: ProductLineOption, Symbol: "BTC-1231-50000-C"}
	if got, want := key.String(), "binance:option:BTC-1231-50000-C"; got != want {
		t.Fatalf("InstrumentKey.String() = %q, want %q", got, want)
	}
}

func TestEventType_IsValid(t *testing.T) {
	if !EventTypeTrade.IsValid() {
		t.Error("trade should be valid")
	}
	if !EventTypeKline.IsValid() {
		t.Error("kline should be valid")
	}
	if EventType("aggTrade").IsValid() {
		t.Error("vendor stream name should be invalid")
	}
	if EventType("").IsValid() {
		t.Error("empty should be invalid")
	}
}

func TestMarketFactEnvelope_Validate(t *testing.T) {
	now := time.Now()
	e := MarketFactEnvelope{
		EventID:       "evt-001",
		InstrumentKey: InstrumentKey{Venue: "binance", ProductLine: ProductLineSpot, Symbol: "BTCUSDT"},
		EventType:     EventTypeTrade, EventTime: now.Add(-100 * time.Millisecond),
		ReceivedAt: now, AvailableAt: now, Source: "binance",
	}
	if err := e.Validate(); err != nil {
		t.Errorf("valid envelope should pass: %v", err)
	}
	// missing EventID
	if err := (MarketFactEnvelope{EventType: EventTypeTrade, EventTime: now, ReceivedAt: now, Source: "binance"}).Validate(); err == nil {
		t.Error("missing EventID should fail")
	}
	// missing EventTime
	e2 := e
	e2.EventTime = time.Time{}
	if err := e2.Validate(); err == nil {
		t.Error("missing EventTime should fail")
	}
	// missing Source
	e3 := e
	e3.Source = ""
	if err := e3.Validate(); err == nil {
		t.Error("missing Source should fail")
	}
}

func TestMarketFactEnvelope_EventAge(t *testing.T) {
	now := time.Now()
	e := MarketFactEnvelope{EventTime: now.Add(-50 * time.Millisecond), ReceivedAt: now}
	age := e.EventAge()
	if age < 49*time.Millisecond || age > 51*time.Millisecond {
		t.Errorf("EventAge = %v, want ~50ms", age)
	}
}

func TestMarketFactEnvelope_EndToEndLatency(t *testing.T) {
	now := time.Now()
	e := MarketFactEnvelope{EventTime: now.Add(-75 * time.Millisecond), AvailableAt: now}
	latency := e.EndToEndLatency()
	if latency < 74*time.Millisecond || latency > 76*time.Millisecond {
		t.Errorf("EndToEndLatency = %v, want ~75ms", latency)
	}
}

func ptrDecimal(d Decimal) *Decimal { return &d }
