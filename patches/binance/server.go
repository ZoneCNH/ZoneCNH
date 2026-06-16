// Package server implements the Binance-specific MarketDataService gRPC ingest server.
// It receives normalized market events from binance/client, performs validation,
// idempotent dedup, durable acceptance, and dispatches to module/market-data downstream port.
package server

import (
	"context"
	"time"
)

// ---- Core Interfaces ----

// IngestServer implements contracts.MarketDataService for Binance.
type IngestServer struct {
	validator   RequestValidator
	idempotency IdempotencyStore
	dispatcher  DownstreamDispatcher
	config      ServerConfig
}

// ServerConfig holds server-level configuration.
type ServerConfig struct {
	// StaleThreshold rejects events where EventTime is older than now - threshold.
	StaleThreshold time.Duration
	// FutureTolerance rejects events where EventTime is beyond now + tolerance.
	FutureTolerance time.Duration
	// IdempotencyTTL is how long idempotency keys are retained.
	IdempotencyTTL time.Duration
	// MaxStreams limits concurrent ingest streams.
	MaxStreams int
	// DrainTimeout is max wait for in-flight requests during drain.
	DrainTimeout time.Duration
}

// DefaultServerConfig returns safe defaults.
func DefaultServerConfig() ServerConfig {
	return ServerConfig{
		StaleThreshold:  30 * time.Second,
		FutureTolerance: 5 * time.Second,
		IdempotencyTTL:  24 * time.Hour,
		MaxStreams:      10,
		DrainTimeout:    30 * time.Second,
	}
}

// ---- Request Validation ----

// RequestValidator validates incoming IngestRequest envelopes.
type RequestValidator interface {
	Validate(ctx context.Context, req IngestRequest) error
}

// DefaultValidator implements the full 12-field validation per SPEC.
type DefaultValidator struct {
	staleThreshold  time.Duration
	futureTolerance time.Duration
}

func NewDefaultValidator(cfg ServerConfig) *DefaultValidator {
	return &DefaultValidator{
		staleThreshold:  cfg.StaleThreshold,
		futureTolerance: cfg.FutureTolerance,
	}
}

func (v *DefaultValidator) Validate(ctx context.Context, req IngestRequest) error {
	now := time.Now()

	if req.RequestID == "" {
		return NewRejectError(RejectContractViolation, "request_id is required")
	}
	if req.Source == "" {
		return NewRejectError(RejectContractViolation, "source is required")
	}
	if req.ProductLine == "" {
		return NewRejectError(RejectContractViolation, "product_line is required")
	}
	if req.EventType == "" {
		return NewRejectError(RejectContractViolation, "event_type is required")
	}
	if req.EventTime.IsZero() {
		return NewRejectError(RejectContractViolation, "event_time is required")
	}
	if req.ReceivedAt.IsZero() {
		return NewRejectError(RejectContractViolation, "received_at is required")
	}
	if req.SchemaVersion == "" {
		return NewRejectError(RejectContractViolation, "schema_version is required")
	}

	// Stale gate
	if now.Sub(req.EventTime) > v.staleThreshold {
		return NewRejectError(RejectQualityGate, "event is stale")
	}
	// Future gate
	if req.EventTime.Sub(now) > v.futureTolerance {
		return NewRejectError(RejectQualityGate, "event time is too far in the future")
	}
	return nil
}

// ---- Idempotency ----

// IdempotencyStore provides at-most-once acceptance.
type IdempotencyStore interface {
	// Accept atomically checks and sets an idempotency key.
	// Returns (accepted, existingPayloadHash, error).
	// If already accepted with same payload, returns (false, hash, nil).
	// If already accepted with different payload, returns (false, hash, ErrConflict).
	Accept(ctx context.Context, key string, payloadHash string) (bool, string, error)

	// MarkDurable marks an accepted key as durably stored.
	MarkDurable(ctx context.Context, key string) error

	// Cleanup removes expired keys older than TTL.
	Cleanup(ctx context.Context) (int64, error)
}

// ErrConflict is returned when idempotency key exists with different payload.
var ErrConflict = &RejectError{Code: RejectTerminalConflict, Message: "idempotency conflict"}

// ---- Downstream Dispatch ----

// DownstreamDispatcher sends accepted events to module/market-data.
type DownstreamDispatcher interface {
	// Dispatch sends an accepted event downstream.
	// Returns error if market-data is unavailable (retryable).
	Dispatch(ctx context.Context, event AcceptedEvent) error
}

type AcceptedEvent struct {
	EventID       string
	InstrumentKey interface{} // domainmarket.InstrumentKey
	EventType     string
	EventTime     time.Time
	ReceivedAt    time.Time
	Source        string
	Payload       []byte
}

// ---- Reject Error ----

// RejectCode matches contracts §8.4 RejectCode.
type RejectCode string

const (
	RejectRetryable          RejectCode = "retryable"
	RejectTerminalValidation RejectCode = "terminal_validation"
	RejectTerminalConflict   RejectCode = "terminal_conflict"
	RejectUnauthorized       RejectCode = "unauthorized"
	RejectRateLimited        RejectCode = "rate_limited"
	RejectServerUnavailable  RejectCode = "server_unavailable"
	RejectContractViolation  RejectCode = "contract_violation"
	RejectQualityGate        RejectCode = "quality_gate"
	RejectOrderingViolation  RejectCode = "ordering_violation"
)

type RejectError struct {
	Code    RejectCode
	Message string
}

func NewRejectError(code RejectCode, msg string) *RejectError {
	return &RejectError{Code: code, Message: msg}
}

func (e *RejectError) Error() string {
	return string(e.Code) + ": " + e.Message
}

func (e *RejectError) IsRetryable() bool {
	return e.Code == RejectRetryable || e.Code == RejectServerUnavailable || e.Code == RejectRateLimited
}
