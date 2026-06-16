// Package dispatch implements the exchange-neutral downstream dispatch receiving side.
// Adapters (e.g. binance/server) call DownstreamDispatchPort to submit
// AcceptedMarketEvents after normalization, validation, and dedup.
package dispatch

import (
	"context"
	"time"
)

// ---- DownstreamDispatchPort ----

// DownstreamDispatchPort is the receiving-side entry point for normalized market events.
// Exchange adapters submit events here after completing source normalization.
type DownstreamDispatchPort interface {
	// Dispatch submits a single accepted market event.
	// Returns DispatchAck on acceptance, DispatchReject on non-retryable failure,
	// or DispatchFailure on temporary unavailability.
	Dispatch(ctx context.Context, event AcceptedMarketEvent) (DispatchOutcome, error)

	// DispatchBatch submits multiple events. Each event gets an independent outcome.
	// A single failure does not discard the entire batch.
	DispatchBatch(ctx context.Context, events []AcceptedMarketEvent) ([]DispatchOutcome, error)
}

// ---- AcceptedMarketEvent ----

// AcceptedMarketEvent is an adapter-normalized event ready for downstream dispatch.
// All 12 fields follow the market-data SPEC v0.1.1 §4.2.
type AcceptedMarketEvent struct {
	// Venue identifies the exchange/source (e.g. "binance").
	Venue string
	// ProductLine is the canonical product line (spot/um_perp/cm_perp/option).
	ProductLine string
	// InstrumentKey is the canonical instrument identity.
	InstrumentKey string
	// Channel identifies the data channel (trade/kline/bookTicker/depth/funding).
	Channel string
	// EventTime is the exchange-assigned event timestamp.
	EventTime time.Time
	// ReceivedAt is the adapter-local receive time.
	ReceivedAt time.Time
	// SourceSequence is the optional monotonic sequence number from the source stream.
	SourceSequence int64
	// Payload carries the canonical market fact.
	Payload interface{}
	// Quality indicates source quality, latency, reliability, and degradation reasons.
	Quality DataQuality
	// IdempotencyKey is the stable dedup key.
	IdempotencyKey string
	// OrderingKey is the partition key for ordered processing.
	OrderingKey string
	// Source identifies the upstream adapter (e.g. "binance").
	Source string
}

// DataQuality carries source quality metadata.
type DataQuality struct {
	Latency       time.Duration
	IsReliable    bool
	IsRecovered   bool
	DegradeReason string
}

// ---- Dispatch Outcomes ----

// DispatchOutcome represents the result of a dispatch call.
type DispatchOutcome interface {
	IsAccepted() bool
	IsRetryable() bool
}

// DispatchAck confirms the event was accepted.
type DispatchAck struct {
	EventID       string
	IdempotencyKey string
	Durable       bool
}

func (a DispatchAck) IsAccepted() bool  { return true }
func (a DispatchAck) IsRetryable() bool { return false }

// DispatchReject means the event was rejected and should not be retried.
type DispatchReject struct {
	EventID        string
	IdempotencyKey string
	Reason         RejectReason
}

func (r DispatchReject) IsAccepted() bool  { return false }
func (r DispatchReject) IsRetryable() bool { return false }

// DispatchFailure means the receiver is temporarily unavailable; adapter should retry.
type DispatchFailure struct {
	EventID string
	Reason  string
}

func (f DispatchFailure) IsAccepted() bool  { return false }
func (f DispatchFailure) IsRetryable() bool { return true }

// ---- RejectReason (8 canonical reasons per SPEC §4.4) ----

type RejectReason string

const (
	RejectContractViolation  RejectReason = "contract_violation"
	RejectQualityRejected    RejectReason = "quality_rejected"
	RejectIdempotencyConflict RejectReason = "idempotency_conflict"
	RejectOrderingViolation  RejectReason = "ordering_violation"
	RejectUnsupportedChannel RejectReason = "unsupported_channel"
	RejectUnauthorized       RejectReason = "unauthorized"
	RejectRateLimited        RejectReason = "rate_limited"
	RejectServerUnavailable  RejectReason = "server_unavailable"
)

// IsTerminal returns true if retry will not help.
func (r RejectReason) IsTerminal() bool {
	switch r {
	case RejectServerUnavailable:
		return false
	default:
		return true
	}
}

// ---- Binance Reject Mapping (§4.4.1) ----

// MapBinanceReject maps binance-native reject codes to market-data outcomes.
// Returns (outcome, reason) for dispatch response.
func MapBinanceReject(binanceCode string) (DispatchOutcome, RejectReason) {
	switch binanceCode {
	case "retryable":
		return DispatchFailure{}, ""
	case "terminal_validation":
		return DispatchReject{}, RejectContractViolation
	case "terminal_conflict":
		return DispatchReject{}, RejectIdempotencyConflict
	case "unauthorized":
		return DispatchReject{}, RejectUnauthorized
	case "rate_limited":
		return DispatchReject{}, RejectRateLimited
	case "server_unavailable":
		return DispatchFailure{}, ""
	default:
		return DispatchReject{}, RejectContractViolation
	}
}

// ---- Observability Metrics ----

// DispatchMetrics provides per-dimension counters.
type DispatchMetrics struct {
	Venue       string
	ProductLine string
	Channel     string
	Outcome     string
	Reason      string
	Count       int64
	LatencyUs   int64
}
