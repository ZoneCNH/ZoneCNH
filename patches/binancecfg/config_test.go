package binancecfg

import (
	"os"
	"testing"
	"time"
)

func TestDefaultConfig(t *testing.T) {
	cfg := DefaultConfig()

	if cfg.WSEndpoint == "" {
		t.Error("WSEndpoint should not be empty")
	}
	if cfg.StaleThreshold <= 0 {
		t.Error("StaleThreshold should be positive")
	}
	if cfg.FutureTolerance <= 0 {
		t.Error("FutureTolerance should be positive")
	}
	if cfg.IdempotencyTTL <= 0 {
		t.Error("IdempotencyTTL should be positive")
	}
	if cfg.MaxStreams <= 0 {
		t.Error("MaxStreams should be positive")
	}
	if cfg.DrainTimeout <= 0 {
		t.Error("DrainTimeout should be positive")
	}
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
	if cfg.ShutdownTimeout <= 0 {
		t.Error("ShutdownTimeout should be positive")
	}
}

func TestLoadConfigDefaults(t *testing.T) {
	for _, key := range configEnvKeys() {
		os.Unsetenv(key)
	}

	cfg := LoadConfig()
	def := DefaultConfig()

	if cfg.WSEndpoint != def.WSEndpoint {
		t.Errorf("WSEndpoint: got %q, want %q", cfg.WSEndpoint, def.WSEndpoint)
	}
	if cfg.MaxStreams != def.MaxStreams {
		t.Errorf("MaxStreams: got %d, want %d", cfg.MaxStreams, def.MaxStreams)
	}
}

func TestLoadConfigFromEnv(t *testing.T) {
	os.Setenv("FOUNDATIONX_BINANCE_WS_ENDPOINT", "wss://test.example.com/ws")
	os.Setenv("FOUNDATIONX_BINANCE_MAX_STREAMS", "50")
	os.Setenv("FOUNDATIONX_BINANCE_STALE_THRESHOLD", "15s")
	defer func() {
		for _, key := range configEnvKeys() {
			os.Unsetenv(key)
		}
	}()

	cfg := LoadConfig()

	if cfg.WSEndpoint != "wss://test.example.com/ws" {
		t.Errorf("WSEndpoint: got %q, want %q", cfg.WSEndpoint, "wss://test.example.com/ws")
	}
	if cfg.MaxStreams != 50 {
		t.Errorf("MaxStreams: got %d, want 50", cfg.MaxStreams)
	}
	if cfg.StaleThreshold != 15*time.Second {
		t.Errorf("StaleThreshold: got %v, want 15s", cfg.StaleThreshold)
	}
}

func TestValidateValid(t *testing.T) {
	cfg := DefaultConfig()
	if err := cfg.Validate(); err != nil {
		t.Fatalf("default config should be valid: %v", err)
	}
}

func TestValidateInvalidMaxStreams(t *testing.T) {
	cfg := DefaultConfig()
	cfg.MaxStreams = 0
	if err := cfg.Validate(); err == nil {
		t.Fatal("expected error for MaxStreams=0")
	}
}

func TestValidateInvalidDrainTimeout(t *testing.T) {
	cfg := DefaultConfig()
	cfg.DrainTimeout = 0
	if err := cfg.Validate(); err == nil {
		t.Fatal("expected error for DrainTimeout=0")
	}
}

func TestValidateInvalidShutdownTimeout(t *testing.T) {
	cfg := DefaultConfig()
	cfg.ShutdownTimeout = 0
	if err := cfg.Validate(); err == nil {
		t.Fatal("expected error for ShutdownTimeout=0")
	}
}

func TestValidateDelegatesToFeedConfig(t *testing.T) {
	cfg := DefaultConfig()
	cfg.WSEndpoint = ""
	if err := cfg.Validate(); err == nil {
		t.Fatal("expected error when FeedConfig validation fails")
	}
}

func TestServerConfigConversion(t *testing.T) {
	cfg := Config{
		StaleThreshold:  10 * time.Second,
		FutureTolerance: 3 * time.Second,
		IdempotencyTTL:  time.Hour,
		MaxStreams:      20,
		DrainTimeout:    15 * time.Second,
	}

	sc := cfg.ServerConfig()

	if sc.StaleThreshold != cfg.StaleThreshold {
		t.Errorf("StaleThreshold: got %v, want %v", sc.StaleThreshold, cfg.StaleThreshold)
	}
	if sc.FutureTolerance != cfg.FutureTolerance {
		t.Errorf("FutureTolerance: got %v, want %v", sc.FutureTolerance, cfg.FutureTolerance)
	}
	if sc.IdempotencyTTL != cfg.IdempotencyTTL {
		t.Errorf("IdempotencyTTL: got %v, want %v", sc.IdempotencyTTL, cfg.IdempotencyTTL)
	}
	if sc.MaxStreams != cfg.MaxStreams {
		t.Errorf("MaxStreams: got %d, want %d", sc.MaxStreams, cfg.MaxStreams)
	}
	if sc.DrainTimeout != cfg.DrainTimeout {
		t.Errorf("DrainTimeout: got %v, want %v", sc.DrainTimeout, cfg.DrainTimeout)
	}
}

func TestFeedConfigConversion(t *testing.T) {
	cfg := Config{
		WSEndpoint:           "wss://example.com",
		ReconnectBackoff:     time.Second,
		MaxReconnectBackoff:  time.Minute,
		MaxReconnectAttempts: 5,
		ReadTimeout:          20 * time.Second,
		PingInterval:         2 * time.Minute,
		EventBufferSize:      512,
	}

	fc := cfg.FeedConfig()

	if fc.Endpoint != cfg.WSEndpoint {
		t.Errorf("Endpoint: got %q, want %q", fc.Endpoint, cfg.WSEndpoint)
	}
	if fc.ReconnectBackoff != cfg.ReconnectBackoff {
		t.Errorf("ReconnectBackoff: got %v, want %v", fc.ReconnectBackoff, cfg.ReconnectBackoff)
	}
	if fc.MaxReconnectAttempts != cfg.MaxReconnectAttempts {
		t.Errorf("MaxReconnectAttempts: got %d, want %d", fc.MaxReconnectAttempts, cfg.MaxReconnectAttempts)
	}
	if fc.ReadTimeout != cfg.ReadTimeout {
		t.Errorf("ReadTimeout: got %v, want %v", fc.ReadTimeout, cfg.ReadTimeout)
	}
	if fc.EventBufferSize != cfg.EventBufferSize {
		t.Errorf("EventBufferSize: got %d, want %d", cfg.EventBufferSize, cfg.EventBufferSize)
	}
}

func TestLoadConfigAllEnvVars(t *testing.T) {
	os.Setenv("FOUNDATIONX_BINANCE_WS_ENDPOINT", "wss://all.example.com")
	os.Setenv("FOUNDATIONX_BINANCE_STALE_THRESHOLD", "20s")
	os.Setenv("FOUNDATIONX_BINANCE_FUTURE_TOLERANCE", "10s")
	os.Setenv("FOUNDATIONX_BINANCE_IDEMPOTENCY_TTL", "48h")
	os.Setenv("FOUNDATIONX_BINANCE_MAX_STREAMS", "100")
	os.Setenv("FOUNDATIONX_BINANCE_DRAIN_TIMEOUT", "60s")
	os.Setenv("FOUNDATIONX_BINANCE_RECONNECT_BACKOFF", "5s")
	os.Setenv("FOUNDATIONX_BINANCE_MAX_RECONNECT_BACKOFF", "2m")
	os.Setenv("FOUNDATIONX_BINANCE_MAX_RECONNECT_ATTEMPTS", "20")
	os.Setenv("FOUNDATIONX_BINANCE_READ_TIMEOUT", "45s")
	os.Setenv("FOUNDATIONX_BINANCE_PING_INTERVAL", "10m")
	os.Setenv("FOUNDATIONX_BINANCE_EVENT_BUFFER_SIZE", "1024")
	os.Setenv("FOUNDATIONX_BINANCE_SHUTDOWN_TIMEOUT", "90s")
	defer func() {
		for _, key := range configEnvKeys() {
			os.Unsetenv(key)
		}
	}()

	cfg := LoadConfig()

	tests := []struct {
		field string
		got   any
		want  any
	}{
		{"WSEndpoint", cfg.WSEndpoint, "wss://all.example.com"},
		{"StaleThreshold", cfg.StaleThreshold, 20 * time.Second},
		{"FutureTolerance", cfg.FutureTolerance, 10 * time.Second},
		{"IdempotencyTTL", cfg.IdempotencyTTL, 48 * time.Hour},
		{"MaxStreams", cfg.MaxStreams, 100},
		{"DrainTimeout", cfg.DrainTimeout, 60 * time.Second},
		{"ReconnectBackoff", cfg.ReconnectBackoff, 5 * time.Second},
		{"MaxReconnectBackoff", cfg.MaxReconnectBackoff, 2 * time.Minute},
		{"MaxReconnectAttempts", cfg.MaxReconnectAttempts, 20},
		{"ReadTimeout", cfg.ReadTimeout, 45 * time.Second},
		{"PingInterval", cfg.PingInterval, 10 * time.Minute},
		{"EventBufferSize", cfg.EventBufferSize, 1024},
		{"ShutdownTimeout", cfg.ShutdownTimeout, 90 * time.Second},
	}
	for _, tt := range tests {
		if tt.got != tt.want {
			t.Errorf("%s: got %v, want %v", tt.field, tt.got, tt.want)
		}
	}
}

func TestParseDurationEnvValid(t *testing.T) {
	os.Setenv("TEST_DURATION", "5m")
	defer os.Unsetenv("TEST_DURATION")

	d := parseDurationEnv("TEST_DURATION")
	if d != 5*time.Minute {
		t.Errorf("got %v, want 5m", d)
	}
}

func TestParseDurationEnvInvalid(t *testing.T) {
	os.Setenv("TEST_DURATION_BAD", "notaduration")
	defer os.Unsetenv("TEST_DURATION_BAD")

	d := parseDurationEnv("TEST_DURATION_BAD")
	if d != 0 {
		t.Errorf("got %v, want 0", d)
	}
}

func TestParseDurationEnvEmpty(t *testing.T) {
	d := parseDurationEnv("NONEXISTENT_ENV_VAR")
	if d != 0 {
		t.Errorf("got %v, want 0", d)
	}
}

func TestParseIntEnvValid(t *testing.T) {
	os.Setenv("TEST_INT", "42")
	defer os.Unsetenv("TEST_INT")

	n := parseIntEnv("TEST_INT")
	if n != 42 {
		t.Errorf("got %d, want 42", n)
	}
}

func TestParseIntEnvInvalid(t *testing.T) {
	os.Setenv("TEST_INT_BAD", "notanumber")
	defer os.Unsetenv("TEST_INT_BAD")

	n := parseIntEnv("TEST_INT_BAD")
	if n != 0 {
		t.Errorf("got %d, want 0", n)
	}
}

func TestParseIntEnvEmpty(t *testing.T) {
	n := parseIntEnv("NONEXISTENT_INT_VAR")
	if n != 0 {
		t.Errorf("got %d, want 0", n)
	}
}

func configEnvKeys() []string {
	return []string{
		"FOUNDATIONX_BINANCE_WS_ENDPOINT",
		"FOUNDATIONX_BINANCE_STALE_THRESHOLD",
		"FOUNDATIONX_BINANCE_FUTURE_TOLERANCE",
		"FOUNDATIONX_BINANCE_IDEMPOTENCY_TTL",
		"FOUNDATIONX_BINANCE_MAX_STREAMS",
		"FOUNDATIONX_BINANCE_DRAIN_TIMEOUT",
		"FOUNDATIONX_BINANCE_RECONNECT_BACKOFF",
		"FOUNDATIONX_BINANCE_MAX_RECONNECT_BACKOFF",
		"FOUNDATIONX_BINANCE_MAX_RECONNECT_ATTEMPTS",
		"FOUNDATIONX_BINANCE_READ_TIMEOUT",
		"FOUNDATIONX_BINANCE_PING_INTERVAL",
		"FOUNDATIONX_BINANCE_EVENT_BUFFER_SIZE",
		"FOUNDATIONX_BINANCE_SHUTDOWN_TIMEOUT",
	}
}
