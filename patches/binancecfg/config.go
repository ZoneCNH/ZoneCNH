// Package binancecfg provides typed configuration loading for the binance
// ingest pipeline. It reads from FOUNDATIONX_* environment variables and
// exposes conversion methods to server.ServerConfig and binancex.FeedConfig.
//
// Separation from cmd/: config loading is independently testable and reusable
// by storage_env, monitoring, and other subsystems.
package binancecfg

import (
	"fmt"
	"log/slog"
	"os"
	"strconv"
	"time"

	binance "github.com/ZoneCNH/runtime-patches/binance"
	"github.com/ZoneCNH/runtime-patches/binancex"
)

// Config holds all configuration for the binance ingest pipeline.
// Zero values are invalid — use DefaultConfig or LoadConfig.
type Config struct {
	// ---- Server ----
	StaleThreshold  time.Duration // FOUNDATIONX_BINANCE_STALE_THRESHOLD
	FutureTolerance time.Duration // FOUNDATIONX_BINANCE_FUTURE_TOLERANCE
	IdempotencyTTL  time.Duration // FOUNDATIONX_BINANCE_IDEMPOTENCY_TTL
	MaxStreams      int           // FOUNDATIONX_BINANCE_MAX_STREAMS
	DrainTimeout    time.Duration // FOUNDATIONX_BINANCE_DRAIN_TIMEOUT

	// ---- Feed ----
	WSEndpoint           string        // FOUNDATIONX_BINANCE_WS_ENDPOINT
	ReconnectBackoff     time.Duration // FOUNDATIONX_BINANCE_RECONNECT_BACKOFF
	MaxReconnectBackoff  time.Duration // FOUNDATIONX_BINANCE_MAX_RECONNECT_BACKOFF
	MaxReconnectAttempts int           // FOUNDATIONX_BINANCE_MAX_RECONNECT_ATTEMPTS
	ReadTimeout          time.Duration // FOUNDATIONX_BINANCE_READ_TIMEOUT
	PingInterval         time.Duration // FOUNDATIONX_BINANCE_PING_INTERVAL
	EventBufferSize      int           // FOUNDATIONX_BINANCE_EVENT_BUFFER_SIZE

	// ---- Shutdown ----
	ShutdownTimeout time.Duration // FOUNDATIONX_BINANCE_SHUTDOWN_TIMEOUT
}

// DefaultConfig returns production-safe defaults.
// All duration fields use conservative values suitable for Binance public streams.
func DefaultConfig() Config {
	return Config{
		WSEndpoint:           "wss://stream.binance.com:9443/ws",
		StaleThreshold:       30 * time.Second,
		FutureTolerance:      5 * time.Second,
		IdempotencyTTL:       24 * time.Hour,
		MaxStreams:           10,
		DrainTimeout:         30 * time.Second,
		ReconnectBackoff:     time.Second,
		MaxReconnectBackoff:  30 * time.Second,
		MaxReconnectAttempts: 10,
		ReadTimeout:          30 * time.Second,
		PingInterval:         3 * time.Minute,
		EventBufferSize:      256,
		ShutdownTimeout:      30 * time.Second,
	}
}

// LoadConfig reads configuration from FOUNDATIONX_BINANCE_* environment
// variables, falling back to DefaultConfig for unset values.
//
// Duration values accept Go duration strings (e.g. "30s", "5m", "24h").
// Integer values accept decimal strings (e.g. "10", "256").
func LoadConfig() Config {
	cfg := DefaultConfig()

	if v := os.Getenv("FOUNDATIONX_BINANCE_WS_ENDPOINT"); v != "" {
		cfg.WSEndpoint = v
	}
	if v := parseDurationEnv("FOUNDATIONX_BINANCE_STALE_THRESHOLD"); v > 0 {
		cfg.StaleThreshold = v
	}
	if v := parseDurationEnv("FOUNDATIONX_BINANCE_FUTURE_TOLERANCE"); v > 0 {
		cfg.FutureTolerance = v
	}
	if v := parseDurationEnv("FOUNDATIONX_BINANCE_IDEMPOTENCY_TTL"); v > 0 {
		cfg.IdempotencyTTL = v
	}
	if v := parseIntEnv("FOUNDATIONX_BINANCE_MAX_STREAMS"); v > 0 {
		cfg.MaxStreams = v
	}
	if v := parseDurationEnv("FOUNDATIONX_BINANCE_DRAIN_TIMEOUT"); v > 0 {
		cfg.DrainTimeout = v
	}
	if v := parseDurationEnv("FOUNDATIONX_BINANCE_RECONNECT_BACKOFF"); v > 0 {
		cfg.ReconnectBackoff = v
	}
	if v := parseDurationEnv("FOUNDATIONX_BINANCE_MAX_RECONNECT_BACKOFF"); v > 0 {
		cfg.MaxReconnectBackoff = v
	}
	if v := parseIntEnv("FOUNDATIONX_BINANCE_MAX_RECONNECT_ATTEMPTS"); v > 0 {
		cfg.MaxReconnectAttempts = v
	}
	if v := parseDurationEnv("FOUNDATIONX_BINANCE_READ_TIMEOUT"); v > 0 {
		cfg.ReadTimeout = v
	}
	if v := parseDurationEnv("FOUNDATIONX_BINANCE_PING_INTERVAL"); v > 0 {
		cfg.PingInterval = v
	}
	if v := parseIntEnv("FOUNDATIONX_BINANCE_EVENT_BUFFER_SIZE"); v > 0 {
		cfg.EventBufferSize = v
	}
	if v := parseDurationEnv("FOUNDATIONX_BINANCE_SHUTDOWN_TIMEOUT"); v > 0 {
		cfg.ShutdownTimeout = v
	}

	return cfg
}

// Validate checks Config for invalid values.
func (c Config) Validate() error {
	fc := c.FeedConfig()
	if err := fc.Validate(); err != nil {
		return fmt.Errorf("binancecfg: %w", err)
	}
	if c.MaxStreams <= 0 {
		return fmt.Errorf("binancecfg: MaxStreams must be positive, got %d", c.MaxStreams)
	}
	if c.DrainTimeout <= 0 {
		return fmt.Errorf("binancecfg: DrainTimeout must be positive, got %v", c.DrainTimeout)
	}
	if c.ShutdownTimeout <= 0 {
		return fmt.Errorf("binancecfg: ShutdownTimeout must be positive, got %v", c.ShutdownTimeout)
	}
	return nil
}

// ServerConfig converts Config to binance.ServerConfig.
func (c Config) ServerConfig() binance.ServerConfig {
	return binance.ServerConfig{
		StaleThreshold:  c.StaleThreshold,
		FutureTolerance: c.FutureTolerance,
		IdempotencyTTL:  c.IdempotencyTTL,
		MaxStreams:      c.MaxStreams,
		DrainTimeout:    c.DrainTimeout,
	}
}

// FeedConfig converts Config to binancex.FeedConfig.
func (c Config) FeedConfig() binancex.FeedConfig {
	return binancex.FeedConfig{
		Endpoint:             c.WSEndpoint,
		ReconnectBackoff:     c.ReconnectBackoff,
		MaxReconnectBackoff:  c.MaxReconnectBackoff,
		MaxReconnectAttempts: c.MaxReconnectAttempts,
		ReadTimeout:          c.ReadTimeout,
		PingInterval:         c.PingInterval,
		EventBufferSize:      c.EventBufferSize,
	}
}

// ---- Helpers ----

func parseDurationEnv(key string) time.Duration {
	v := os.Getenv(key)
	if v == "" {
		return 0
	}
	d, err := time.ParseDuration(v)
	if err != nil {
		slog.Warn("invalid duration env, using default", "key", key, "value", v, "err", err)
		return 0
	}
	return d
}

func parseIntEnv(key string) int {
	v := os.Getenv(key)
	if v == "" {
		return 0
	}
	n, err := strconv.Atoi(v)
	if err != nil {
		slog.Warn("invalid int env, using default", "key", key, "value", v, "err", err)
		return 0
	}
	return n
}
