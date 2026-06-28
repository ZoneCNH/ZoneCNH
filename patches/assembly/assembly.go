// Package assembly provides the middleware injection and wiring layer
// for the binance ingest pipeline. It connects binancex adapters to the
// binance ingest server, injecting cross-cutting concerns as composable middleware.
package assembly

import (
	"errors"
	"fmt"

	binance "github.com/ZoneCNH/runtime-patches/binance"
	"github.com/ZoneCNH/runtime-patches/binancex"
)

// ServerDeps collects all dependencies needed to construct an ingest server.
type ServerDeps struct {
	Feed        binancex.MarketDataFeed
	Validator   binance.RequestValidator
	Idempotency binance.IdempotencyStore
	Dispatcher  binance.DownstreamDispatcher
	Config      binance.ServerConfig
}

// Validate checks that all required dependencies are non-nil.
func (d ServerDeps) Validate() error {
	var errs []error
	if d.Feed == nil {
		errs = append(errs, fmt.Errorf("ServerDeps.Feed is nil"))
	}
	if d.Validator == nil {
		errs = append(errs, fmt.Errorf("ServerDeps.Validator is nil"))
	}
	if d.Idempotency == nil {
		errs = append(errs, fmt.Errorf("ServerDeps.Idempotency is nil"))
	}
	if d.Dispatcher == nil {
		errs = append(errs, fmt.Errorf("ServerDeps.Dispatcher is nil"))
	}
	return errors.Join(errs...)
}

// Middleware is the common interface for all assembly middleware.
type Middleware interface {
	Name() string
}

// ValidatorMiddleware wraps a RequestValidator with cross-cutting behavior.
type ValidatorMiddleware interface {
	Middleware
	WrapValidator(next binance.RequestValidator) binance.RequestValidator
}

// IdempotencyMiddleware wraps an IdempotencyStore with cross-cutting behavior.
type IdempotencyMiddleware interface {
	Middleware
	WrapIdempotency(next binance.IdempotencyStore) binance.IdempotencyStore
}

// DispatchMiddleware wraps a DownstreamDispatcher with cross-cutting behavior.
type DispatchMiddleware interface {
	Middleware
	WrapDispatcher(next binance.DownstreamDispatcher) binance.DownstreamDispatcher
}

// ServerConstructor is a factory function that creates an IngestServer.
type ServerConstructor func(deps ServerDeps) (*binance.IngestServer, error)

// Assemble applies the middleware chain to each dependency and returns
// the assembled ServerDeps ready for server construction.
func Assemble(deps ServerDeps, middlewares ...Middleware) (ServerDeps, error) {
	if err := deps.Validate(); err != nil {
		return ServerDeps{}, fmt.Errorf("assembly: invalid deps: %w", err)
	}

	v := deps.Validator
	idem := deps.Idempotency
	disp := deps.Dispatcher

	for _, mw := range middlewares {
		if mw == nil {
			continue
		}
		if vm, ok := mw.(ValidatorMiddleware); ok {
			v = vm.WrapValidator(v)
		}
		if im, ok := mw.(IdempotencyMiddleware); ok {
			idem = im.WrapIdempotency(idem)
		}
		if dm, ok := mw.(DispatchMiddleware); ok {
			disp = dm.WrapDispatcher(disp)
		}
	}

	return ServerDeps{
		Feed:        deps.Feed,
		Validator:   v,
		Idempotency: idem,
		Dispatcher:  disp,
		Config:      deps.Config,
	}, nil
}

// Build assembles deps and constructs the server in a single call.
func Build(deps ServerDeps, constructor ServerConstructor, middlewares ...Middleware) (*binance.IngestServer, error) {
	assembled, err := Assemble(deps, middlewares...)
	if err != nil {
		return nil, err
	}
	return constructor(assembled)
}

// NopMiddleware passes through all dependencies unchanged.
type NopMiddleware struct{}

func (NopMiddleware) Name() string { return "nop" }

var (
	_ ValidatorMiddleware   = (*NopMiddleware)(nil)
	_ IdempotencyMiddleware = (*NopMiddleware)(nil)
	_ DispatchMiddleware    = (*NopMiddleware)(nil)
)

func (NopMiddleware) WrapValidator(next binance.RequestValidator) binance.RequestValidator { return next }
func (NopMiddleware) WrapIdempotency(next binance.IdempotencyStore) binance.IdempotencyStore {
	return next
}
func (NopMiddleware) WrapDispatcher(next binance.DownstreamDispatcher) binance.DownstreamDispatcher {
	return next
}
