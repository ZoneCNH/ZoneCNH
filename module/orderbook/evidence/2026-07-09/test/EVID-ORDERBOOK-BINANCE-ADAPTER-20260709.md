# EVID-ORDERBOOK-BINANCE-ADAPTER-20260709

> Module: orderbook
> Goal: GOAL-20260709-001
> Date: 2026-07-09
> Evidence Type: Downstream adapter wrapper
> Binance PR: `https://github.com/ZoneCNH/binance/pull/479`
> Binance Branch: `feat/orderbook-contract-adapter`
> Binance Commit: `8f8ee93653e1a0eaf40c687978f194cf3c018132`

---

## 1. Scope

The Binance repository now has an open PR that maps Binance REST snapshots and depth events into the released `github.com/ZoneCNH/orderbook v0.1.0` contract types.[COMPUTED, HIGH]

The PR is a thin adapter wrapper only; it does not replace the existing Binance production order book state machine, reconnect loop, persistence path or downstream publish path.[COMPUTED, HIGH]

The PR changed `go.mod`, `go.sum`, `internal/client/orderbook/contract_adapter.go` and `internal/client/orderbook/contract_adapter_test.go` in `/home/workspace/binance/.worktree/workspaces/feat/orderbook-contract-adapter`.[COMPUTED, HIGH]

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
| `bash scripts/boundary-gates.sh` | PASS |
| `git diff --check -- go.mod go.sum internal/client/orderbook/contract_adapter.go internal/client/orderbook/contract_adapter_test.go` | PASS |

## 4. Remote PR Status

PR #479 was opened against `ZoneCNH/binance:main` from `feat/orderbook-contract-adapter`.[COMPUTED, HIGH]

Remote `Boundary Gates (15 gates)` passed on the PR event observed after creation.[COMPUTED, HIGH]

Remote `Status Consistency Check` failed because Binance `README` declares `release_closeable=YES` while matching `status.txt` evidence is missing and `release/evidence/binance/20260708/status.txt` contains FAIL entries.[COMPUTED, HIGH]

Remote `govulncheck + go mod audit` failed on existing Binance code paths because the workflow used `crypto/tls@go1.26.4` where the advisory is fixed in `go1.26.5`, and `github.com/quic-go/quic-go@v0.59.0` where the advisory is fixed in `v0.59.1`.[COMPUTED, HIGH]

Remote `Build & Vet` failed in the same non-target packages seen locally: `internal/client`, `internal/server/api`, `internal/server/cache` and `internal/server/storage`; the PR log shows `internal/client/orderbook` passed.[COMPUTED, HIGH]

Remote `Unit Test & Race & Cover` failed in the same non-target package set; the PR log again shows `internal/client/orderbook` passed.[COMPUTED, HIGH]

Remote `Live E2E` failed before live tests ran because `.env` was missing in the GitHub Actions job.[COMPUTED, HIGH]

Remote `Benchmark Regression` failed with exit code 2 after the benchmark run; this remains a Binance CI baseline to triage separately from the adapter wrapper.[COMPUTED, MED]

These remote failures are not caused by the new adapter files, but they still block a green Binance PR until the Binance repository fixes its governance status, vulnerability baseline, full-suite test baseline, live-test environment and benchmark baseline.[INFERRED, HIGH]

## 5. Full-suite Residual

`GOWORK=off go test ./...` from the clean Binance feature worktree still fails outside the new adapter package in `internal/client`, `internal/server/api`, `internal/server/cache` and `internal/server/storage`.[COMPUTED, HIGH]

The adapter package itself passed targeted test and vet verification.[COMPUTED, HIGH]

## 6. Claim Boundary

This evidence closes the first adapter-wrapper implementation step, not production migration.[COMPUTED, HIGH]

The OrderBook module still cannot claim production cross-venue completeness until a second venue conformance fixture passes and the Binance PR is merged or superseded by an equivalent production integration.[INFERRED, HIGH]

---

[RULES I BROKE]：无
