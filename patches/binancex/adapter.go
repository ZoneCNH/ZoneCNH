// Package binancex defines the exchange SDK abstraction layer.
// It extracts the feed/session interface from binance/server so that
// the ingest pipeline depends on an interface rather than a concrete SDK.
//
// Benefits:
//   - Mock-based testing without real WebSocket connections
//   - Multi-exchange adapter polymorphism (Binance, Bybit, OKX share the same contract)
//   - Clean separation between transport (SDK) and ingest logic (server)
package binancex

import (
	"context"
	"time"

	domainmarket "github.com/ZoneCNH/runtime-patches/domain-market"
)

// MarketDataFeed is the exchange-agnostic interface for consuming market data.
// Each exchange (Binance, Bybit, OKX) provides its own implementation that wraps
// the vendor SDK and normalizes events into the canonical FeedEvent shape.
type MarketDataFeed interface {
	// Connect opens the underlying transport and starts delivering events.
	Connect(ctx context.Context) error

	// Close initiates a graceful shutdown.
	Close() error

	// Subscribe registers interest in one or more logical streams.
	Subscribe(ctx context.Context, specs []StreamSpec) error

	// Unsubscribe removes interest in the given streams.
	Unsubscribe(ctx context.Context, specs []StreamSpec) error

	// Events returns a read-only channel of normalized feed events.
	Events() <-chan FeedEvent

	// Errors returns a read-only channel of non-fatal operational errors.
	Errors() <-chan error
}

// FeedEvent is a normalized market event produced by a MarketDataFeed adapter.
type FeedEvent struct {
	EventID       string
	InstrumentKey domainmarket.InstrumentKey
	EventType     domainmarket.EventType
	EventTime     time.Time
	ReceivedAt    time.Time
	Source        string
	SchemaVersion string
	Payload       any
	Sequence      int64
	OrderingKey   string
}

// StreamSpec describes a logical stream subscription.
type StreamSpec struct {
	InstrumentKey domainmarket.InstrumentKey
	Channel       string
	Interval      string
}

// FeedConfig holds transport-level configuration for a MarketDataFeed.
type FeedConfig struct {
	Endpoint             string
	ReconnectBackoff     time.Duration
	MaxReconnectBackoff  time.Duration
	MaxReconnectAttempts int
	ReadTimeout          time.Duration
	WriteTimeout         time.Duration
	PingInterval         time.Duration
	EventBufferSize      int
	ErrorBufferSize      int
}

// DefaultFeedConfig returns production-safe defaults.
func DefaultFeedConfig() FeedConfig {
	return FeedConfig{
		ReconnectBackoff:     time.Second,
		MaxReconnectBackoff:  30 * time.Second,
		MaxReconnectAttempts: 10,
		ReadTimeout:          30 * time.Second,
		WriteTimeout:         10 * time.Second,
		PingInterval:         3 * time.Minute,
		EventBufferSize:      256,
		ErrorBufferSize:      16,
	}
}

// Validate checks FeedConfig for invalid values.
func (c FeedConfig) Validate() error {
	if c.Endpoint == "" {
		return &FeedConfigError{Field: "Endpoint", Message: "is required"}
	}
	if c.ReadTimeout <= 0 {
		return &FeedConfigError{Field: "ReadTimeout", Message: "must be positive"}
	}
	if c.PingInterval <= 0 {
		return &FeedConfigError{Field: "PingInterval", Message: "must be positive"}
	}
	if c.EventBufferSize <= 0 {
		return &FeedConfigError{Field: "EventBufferSize", Message: "must be positive"}
	}
	return nil
}

// FeedConfigError describes an invalid FeedConfig field.
type FeedConfigError struct {
	Field   string
	Message string
}

func (e *FeedConfigError) Error() string {
	return "binancex: invalid FeedConfig." + e.Field + ": " + e.Message
}
