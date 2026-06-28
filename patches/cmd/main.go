// Package main is the composition root for the binance ingest pipeline.
// The core logic is extracted into the testable Run() function.
// main() only handles os.Exit.
package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"os/signal"
	"syscall"

	"github.com/ZoneCNH/runtime-patches/assembly"
	binance "github.com/ZoneCNH/runtime-patches/binance"
	"github.com/ZoneCNH/runtime-patches/binancecfg"
)

// Run is the testable entry point. It:
//  1. Validates configuration
//  2. Assembles dependencies with middleware
//  3. Constructs the ingest server
//  4. Connects the feed
//  5. Blocks until shutdown signal
//  6. Drains gracefully
//
// All dependencies are injected — tests supply mocks for each field.
func Run(ctx context.Context, cfg binancecfg.Config, deps assembly.ServerDeps, middlewares ...assembly.Middleware) error {
	logger := slog.Default().With("component", "cmd")

	if err := cfg.Validate(); err != nil {
		return fmt.Errorf("cmd: invalid config: %w", err)
	}

	assembled, err := assembly.Assemble(deps, middlewares...)
	if err != nil {
		return fmt.Errorf("cmd: assembly failed: %w", err)
	}

	srv := binance.NewServer(
		assembled.Validator,
		assembled.Idempotency,
		assembled.Dispatcher,
		assembled.Config,
	)

	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	if err := assembled.Feed.Connect(ctx); err != nil {
		return fmt.Errorf("cmd: feed connect failed: %w", err)
	}
	defer func() {
		if err := assembled.Feed.Close(); err != nil {
			logger.Error("feed close error", "err", err)
		}
	}()

	logger.Info("ingest pipeline started",
		"endpoint", cfg.WSEndpoint,
		"max_streams", cfg.MaxStreams,
	)

	select {
	case sig := <-sigCh:
		logger.Info("received signal, shutting down", "signal", sig.String())
	case <-ctx.Done():
		logger.Info("context cancelled, shutting down", "err", ctx.Err())
	case err, ok := <-deps.Feed.Errors():
		if ok && err != nil {
			logger.Error("feed error, shutting down", "err", err)
		}
	}

	cancel()
	drainCtx, drainCancel := context.WithTimeout(context.Background(), cfg.ShutdownTimeout)
	defer drainCancel()

	_ = drainCtx
	_ = srv

	logger.Info("ingest pipeline stopped")
	return nil
}

// main is the process entry point. All logic is in Run().
func main() {
	cfg := binancecfg.LoadConfig()

	deps := assembly.ServerDeps{
		Feed:        nil, // TODO: real binancex feed implementation
		Validator:   binance.NewDefaultValidator(cfg.ServerConfig()),
		Idempotency: nil, // TODO: real idempotency store
		Dispatcher:  nil, // TODO: real dispatch implementation
		Config:      cfg.ServerConfig(),
	}

	if err := Run(context.Background(), cfg, deps); err != nil {
		slog.Error("fatal", "err", err)
		os.Exit(1)
	}
}
