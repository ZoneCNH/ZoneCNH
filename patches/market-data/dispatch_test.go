package dispatch

import "testing"

func TestRejectReasonIsTerminal(t *testing.T) {
	tests := []struct {
		name   string
		reason RejectReason
		want   bool
	}{
		{name: "server unavailable is retryable", reason: RejectServerUnavailable, want: false},
		{name: "contract violation is terminal", reason: RejectContractViolation, want: true},
		{name: "quality rejected is terminal", reason: RejectQualityRejected, want: true},
		{name: "unknown is terminal safe default", reason: RejectReason("unknown"), want: true},
		{name: "empty is terminal safe default", reason: RejectReason(""), want: true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := tt.reason.IsTerminal(); got != tt.want {
				t.Fatalf("IsTerminal() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestMapBinanceReject(t *testing.T) {
	tests := []struct {
		name          string
		code          string
		subReason     RejectReason
		wantRetryable bool
		wantReason    RejectReason
	}{
		{name: "retryable", code: "retryable", wantRetryable: true},
		{name: "server unavailable", code: "server_unavailable", wantRetryable: true},
		{name: "terminal validation keeps sub reason", code: "terminal_validation", subReason: RejectOrderingViolation, wantReason: RejectOrderingViolation},
		{name: "terminal validation defaults sub reason", code: "terminal_validation", wantReason: RejectContractViolation},
		{name: "terminal conflict", code: "terminal_conflict", wantReason: RejectIdempotencyConflict},
		{name: "unauthorized", code: "unauthorized", wantReason: RejectUnauthorized},
		{name: "rate limited", code: "rate_limited", wantReason: RejectRateLimited},
		{name: "unknown defaults contract violation", code: "unexpected", wantReason: RejectContractViolation},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			outcome, reason := MapBinanceReject(tt.code, tt.subReason)
			if outcome.IsAccepted() {
				t.Fatal("reject mapping must not produce accepted outcomes")
			}
			if got := outcome.IsRetryable(); got != tt.wantRetryable {
				t.Fatalf("IsRetryable() = %v, want %v", got, tt.wantRetryable)
			}
			if reason != tt.wantReason {
				t.Fatalf("reason = %q, want %q", reason, tt.wantReason)
			}
		})
	}
}
