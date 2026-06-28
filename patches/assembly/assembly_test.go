package assembly

import (
	"context"
	"errors"
	"testing"
	"time"

	binance "github.com/ZoneCNH/runtime-patches/binance"
	"github.com/ZoneCNH/runtime-patches/binancex"
)

// ---- Mocks ----

type mockFeed struct{ connectErr error }

func (m *mockFeed) Connect(ctx context.Context) error                        { return m.connectErr }
func (m *mockFeed) Close() error                                             { return nil }
func (m *mockFeed) Subscribe(ctx context.Context, s []binancex.StreamSpec) error  { return nil }
func (m *mockFeed) Unsubscribe(ctx context.Context, s []binancex.StreamSpec) error { return nil }
func (m *mockFeed) Events() <-chan binancex.FeedEvent                            { return nil }
func (m *mockFeed) Errors() <-chan error                                         { return nil }

type mockValidator struct{ validateErr error }

func (m *mockValidator) Validate(ctx context.Context, req binance.IngestRequest) error {
	return m.validateErr
}

type mockIdempotency struct{}

func (m *mockIdempotency) Accept(ctx context.Context, key, hash string) (bool, string, error) {
	return true, "", nil
}
func (m *mockIdempotency) MarkDurable(ctx context.Context, key string) error { return nil }
func (m *mockIdempotency) Cleanup(ctx context.Context) (int64, error)        { return 0, nil }

type mockDispatcher struct{ dispatchErr error }

func (m *mockDispatcher) Dispatch(ctx context.Context, e binance.AcceptedEvent) error {
	return m.dispatchErr
}

// ---- Tests ----

func TestServerDepsValidateAllNil(t *testing.T) {
	deps := ServerDeps{}
	err := deps.Validate()
	if err == nil {
		t.Fatal("expected error for all-nil deps")
	}
}

func TestServerDepsValidateFeedNil(t *testing.T) {
	deps := ServerDeps{
		Validator:   &mockValidator{},
		Idempotency: &mockIdempotency{},
		Dispatcher:  &mockDispatcher{},
	}
	err := deps.Validate()
	if err == nil {
		t.Fatal("expected error for nil Feed")
	}
}

func TestServerDepsValidateAllPresent(t *testing.T) {
	deps := ServerDeps{
		Feed:        &mockFeed{},
		Validator:   &mockValidator{},
		Idempotency: &mockIdempotency{},
		Dispatcher:  &mockDispatcher{},
	}
	if err := deps.Validate(); err != nil {
		t.Fatalf("all-present deps should be valid: %v", err)
	}
}

func TestAssembleValidDeps(t *testing.T) {
	deps := validDeps()
	assembled, err := Assemble(deps)
	if err != nil {
		t.Fatalf("Assemble should succeed: %v", err)
	}
	if assembled.Validator == nil {
		t.Error("assembled Validator should not be nil")
	}
}

func TestAssembleInvalidDeps(t *testing.T) {
	_, err := Assemble(ServerDeps{})
	if err == nil {
		t.Fatal("Assemble should fail for invalid deps")
	}
}

func TestAssembleWithNopMiddleware(t *testing.T) {
	deps := validDeps()
	assembled, err := Assemble(deps, NopMiddleware{})
	if err != nil {
		t.Fatalf("Assemble with nop middleware should succeed: %v", err)
	}
	if assembled.Validator != deps.Validator {
		t.Error("NopMiddleware should not change Validator")
	}
}

func TestAssembleWithNilMiddleware(t *testing.T) {
	deps := validDeps()
	assembled, err := Assemble(deps, nil)
	if err != nil {
		t.Fatalf("Assemble with nil middleware should succeed: %v", err)
	}
	if assembled.Validator != deps.Validator {
		t.Error("nil middleware should not change deps")
	}
}

func TestNopMiddlewareName(t *testing.T) {
	mw := NopMiddleware{}
	if mw.Name() != "nop" {
		t.Error("NopMiddleware name should be 'nop'")
	}
}

func TestNopMiddlewareInterfaceSatisfaction(t *testing.T) {
	var m Middleware = NopMiddleware{}
	if m.Name() != "nop" {
		t.Error("NopMiddleware should satisfy Middleware")
	}
}

func TestBuild(t *testing.T) {
	deps := validDeps()
	deps.Config = binance.ServerConfig{
		StaleThreshold: 30 * time.Second,
		MaxStreams:     10,
		DrainTimeout:   30 * time.Second,
	}

	constructor := func(d ServerDeps) (*binance.IngestServer, error) {
		return binance.NewServer(d.Validator, d.Idempotency, d.Dispatcher, d.Config), nil
	}

	srv, err := Build(deps, constructor)
	if err != nil {
		t.Fatalf("Build should succeed: %v", err)
	}
	if srv == nil {
		t.Fatal("Build should return non-nil server")
	}
}

func TestBuildInvalidDeps(t *testing.T) {
	constructor := func(d ServerDeps) (*binance.IngestServer, error) {
		return nil, errors.New("should not be called")
	}
	_, err := Build(ServerDeps{}, constructor)
	if err == nil {
		t.Fatal("Build should fail for invalid deps")
	}
}

func validDeps() ServerDeps {
	return ServerDeps{
		Feed:        &mockFeed{},
		Validator:   &mockValidator{},
		Idempotency: &mockIdempotency{},
		Dispatcher:  &mockDispatcher{},
	}
}
