package server

import (
	"context"
	"errors"
	"testing"
	"time"

	contracts "github.com/ZoneCNH/runtime-patches/contracts"
	domainmarket "github.com/ZoneCNH/runtime-patches/domain-market"
)

func TestDefaultValidatorRejectsMissingPayload(t *testing.T) {
	validator := NewDefaultValidator(DefaultServerConfig())
	req := validIngestRequest()
	req.Payload = nil

	err := validator.Validate(context.Background(), req)
	if err == nil {
		t.Fatal("expected missing payload to be rejected")
	}

	var reject *RejectError
	if !errors.As(err, &reject) {
		t.Fatalf("expected RejectError, got %T", err)
	}
	if reject.Code != contracts.RejectContractViolation {
		t.Fatalf("expected %s, got %s", contracts.RejectContractViolation, reject.Code)
	}
}

func TestAcceptedEventUsesCanonicalInstrumentKey(t *testing.T) {
	key := domainmarket.InstrumentKey{
		Venue:       "binance",
		ProductLine: domainmarket.ProductLineUMPerp,
		Symbol:      "BTCUSDT",
	}
	if err := key.Validate(); err != nil {
		t.Fatalf("canonical instrument key should be valid: %v", err)
	}

	event := AcceptedEvent{InstrumentKey: key}
	if event.InstrumentKey != key {
		t.Fatalf("accepted event should retain canonical instrument key: %#v", event.InstrumentKey)
	}
}

func validIngestRequest() IngestRequest {
	now := time.Now()
	return IngestRequest{
		RequestID:     "req-1",
		Source:        "binance",
		ProductLine:   "um_perp",
		EventType:     "trade",
		EventTime:     now.Add(-10 * time.Millisecond),
		ReceivedAt:    now,
		SchemaVersion: "v1",
		Payload:       []byte(`{"price":"50000"}`),
	}
}
