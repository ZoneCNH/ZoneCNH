# EVID-ORDERBOOK-BINANCE-ADAPTER-20260709

> Module: orderbook
> Goal: GOAL-20260709-001
> Date: 2026-07-09
> Evidence Type: Downstream adapter wrapper
> Binance PR: `https://github.com/ZoneCNH/binance/pull/479`
> Binance Branch: `feat/orderbook-contract-adapter`
> Binance Head Commit: `f46c17fd8297779c9f0c0931cc94b6f5ff1ed150`
> Binance Merge Commit: `b2547735e9df6b9bb4bb939baaeb74436260ce50`

---

## 1. Scope

The Binance repository merged PR #479, which maps Binance REST snapshots and depth events into the released `github.com/ZoneCNH/orderbook v0.1.0` contract types.[COMPUTED, HIGH]

The PR is a thin adapter wrapper only; it does not replace the existing Binance production order book state machine, reconnect loop, persistence path or downstream publish path.[COMPUTED, HIGH]

The adapter implementation introduced `go.mod`, `go.sum`, `internal/client/orderbook/contract_adapter.go` and `internal/client/orderbook/contract_adapter_test.go` changes in `/home/workspace/binance/.worktree/workspaces/feat/orderbook-contract-adapter`.[COMPUTED, HIGH]

The same PR later closed pre-existing Binance CI baseline failures in workflows, status consistency, vulnerability baseline, full-suite tests, Live E2E handling and benchmark stability so that the adapter branch could be merged.[COMPUTED, HIGH]

## 2. Implemented Contract Mapping

| Area | Evidence |
| --- | --- |
| Dependency | `github.com/ZoneCNH/orderbook v0.1.0` added to Binance `go.mod`.[COMPUTED, HIGH] |
| Snapshot mapping | `RESTSnapshotToContract` maps Binance REST levels into `event.Snapshot`.[COMPUTED, HIGH] |
| Diff mapping | `DepthEventToContract` maps Binance depth events into `event.DiffEvent`.[COMPUTED, HIGH] |
| Spot sequence policy | Spot and empty product lines use the `range` sequence policy.[COMPUTED, HIGH] |
| Futures sequence policy | Non-spot product lines use the `prev_link` sequence policy.[COMPUTED, HIGH] |
| Replay proof | Tests run the spot mapping through `replay.Runner`.[COMPUTED, HIGH] |
| Gap proof | Tests reject a broken futures `prev_link` transition.[COMPUTED, HIGH] |

## 3. Local Verification

| Command | Result |
| --- | --- |
| `GOWORK=off go test ./internal/client/orderbook` | PASS |
| `GOWORK=off go vet ./internal/client/orderbook` | PASS |
| `GOWORK=off GOTOOLCHAIN=auto go test ./...` | PASS |
| `GOWORK=off GOTOOLCHAIN=auto go test ./... -race -count=1` | PASS |
| `GOWORK=off GOTOOLCHAIN=auto go build ./...` | PASS |
| `GOWORK=off GOTOOLCHAIN=auto go vet ./...` | PASS |
| `GOWORK=off GOTOOLCHAIN=auto golangci-lint run` | PASS |
| `GOWORK=off GOTOOLCHAIN=auto go run golang.org/x/vuln/cmd/govulncheck@latest ./...` | PASS |
| `GOWORK=off GOTOOLCHAIN=auto bash scripts/benchmark-regression.sh --threshold 20` | PASS |
| `bash scripts/boundary-gates.sh` | PASS |
| `bash scripts/readiness-audit.sh` | PASS |
| `git diff --check -- go.mod go.sum internal/client/orderbook/contract_adapter.go internal/client/orderbook/contract_adapter_test.go` | PASS |

## 4. Remote PR Status

PR #479 was opened against `ZoneCNH/binance:main` from `feat/orderbook-contract-adapter`.[COMPUTED, HIGH]

After head commit `f46c17fd8297779c9f0c0931cc94b6f5ff1ed150`, GitHub reported PR #479 as `MERGEABLE`; the PR was merged at `2026-07-09T15:40:48Z` with merge commit `b2547735e9df6b9bb4bb939baaeb74436260ce50`.[COMPUTED, HIGH]

Remote `Build & Vet` passed.[COMPUTED, HIGH]

Remote `Unit Test & Race & Cover` passed.[COMPUTED, HIGH]

Remote `golangci-lint`, `govulncheck + go mod audit`, `Security`, `gitleaks`, `Status Consistency Check`, `Boundary Gates (15 gates)`, `Live E2E`, `Soak + Chaos (tagged)` and `Benchmark Regression` all passed in the final PR check set.[COMPUTED, HIGH]

Condition-gated `Integration Test`, `E2E Test` and `Gated Resilience Tests` were skipped by workflow condition in the final PR check set.[COMPUTED, HIGH]

After merge, Binance `main` CI runs for merge commit `b2547735e9df6b9bb4bb939baaeb74436260ce50` all completed with `success`, including Binance CI, Test, Build, Lint, Boundary Gates, Status Consistency, Secrets Scan, Security and Vulnerability Scan.[COMPUTED, HIGH]

## 5. Full-suite Baseline Closure

The earlier remote failures were triaged and fixed in the Binance PR branch before this evidence was finalized.[COMPUTED, HIGH]

The final Binance branch includes CI baseline fixes for Go `1.26.5`, `github.com/quic-go/quic-go v0.59.1`, status consistency, canonical `book_ticker` tests, circuit breaker assertions, reconnect queue race behavior, Live E2E `.env` handling and benchmark regression stability.[COMPUTED, HIGH]

The adapter package and the full Binance test baseline both passed local and remote verification after those fixes.[COMPUTED, HIGH]

## 6. Claim Boundary

This evidence closes the first adapter-wrapper implementation and merge step, not production migration.[COMPUTED, HIGH]

The second venue-style conformance fixture was later merged in `orderbook` PR #1; production cross-venue completeness still requires a real second venue adapter/live integration and an explicit Binance production runtime migration or equivalent production integration.[COMPUTED, HIGH]

---

[RULES I BROKE]：无
