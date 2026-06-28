package binancex

import (
	"testing"
	"time"
)

func TestDefaultFeedConfig(t *testing.T) {
	cfg := DefaultFeedConfig()

	if cfg.ReconnectBackoff <= 0 {
		t.Error("ReconnectBackoff should be positive")
	}
	if cfg.MaxReconnectBackoff <= 0 {
		t.Error("MaxReconnectBackoff should be positive")
	}
	if cfg.ReadTimeout <= 0 {
		t.Error("ReadTimeout should be positive")
	}
	if cfg.PingInterval <= 0 {
		t.Error("PingInterval should be positive")
	}
	if cfg.EventBufferSize <= 0 {
		t.Error("EventBufferSize should be positive")
	}
}

func TestFeedConfigValidateValid(t *testing.T) {
	cfg := FeedConfig{
		Endpoint:        "wss://example.com",
		ReadTimeout:     30 * time.Second,
		PingInterval:    3 * time.Minute,
		EventBufferSize: 256,
	}
	if err := cfg.Validate(); err != nil {
		t.Fatalf("valid config should not error: %v", err)
	}
}

func TestFeedConfigValidateMissingEndpoint(t *testing.T) {
	cfg := FeedConfig{
		ReadTimeout:     30 * time.Second,
		PingInterval:    3 * time.Minute,
		EventBufferSize: 256,
	}
	if err := cfg.Validate(); err == nil {
		t.Fatal("expected error for missing Endpoint")
	}
}

func TestFeedConfigValidateZeroReadTimeout(t *testing.T) {
	cfg := FeedConfig{
		Endpoint:        "wss://example.com",
		ReadTimeout:     0,
		PingInterval:    3 * time.Minute,
		EventBufferSize: 256,
	}
	if err := cfg.Validate(); err == nil {
		t.Fatal("expected error for zero ReadTimeout")
	}
}

func TestFeedConfigValidateZeroPingInterval(t *testing.T) {
	cfg := FeedConfig{
		Endpoint:        "wss://example.com",
		ReadTimeout:     30 * time.Second,
		PingInterval:    0,
		EventBufferSize: 256,
	}
	if err := cfg.Validate(); err == nil {
		t.Fatal("expected error for zero PingInterval")
	}
}

func TestFeedConfigValidateZeroEventBuffer(t *testing.T) {
	cfg := FeedConfig{
		Endpoint:        "wss://example.com",
		ReadTimeout:     30 * time.Second,
		PingInterval:    3 * time.Minute,
		EventBufferSize: 0,
	}
	if err := cfg.Validate(); err == nil {
		t.Fatal("expected error for zero EventBufferSize")
	}
}

func TestFeedConfigError(t *testing.T) {
	e := &FeedConfigError{Field: "Endpoint", Message: "is required"}
	if e.Error() == "" {
		t.Error("error string should not be empty")
	}
}
