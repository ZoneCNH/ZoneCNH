# EVID-ORDERBOOK-SECOND-VENUE-CONFORMANCE-20260710

> Module: orderbook
> Goal: GOAL-20260709-001
> Date: 2026-07-10
> Evidence Type: Second venue-style conformance fixture
> OrderBook PR: `https://github.com/ZoneCNH/orderbook/pull/1`
> OrderBook Head Commit: `8ab4cee17514b805cb2c57c35e3a5477080bad23`
> OrderBook Merge Commit: `1276feb60295e7588280623a0a1ba159e2ba0303`
> Main CI Run: `https://github.com/ZoneCNH/orderbook/actions/runs/29036729299`

---

## 1. Scope

`orderbook` PR #1 added a second venue-style built-in conformance fixture and merged it into `main` after the `v0.1.0` release.[COMPUTED, HIGH]

The new fixture models `prev_link` sequence semantics distinct from the existing Binance-like range sequence fixture.[COMPUTED, HIGH]

This is fixture-level contract evidence only; it is not a real OKX, Bybit or other venue live adapter implementation.[COMPUTED, HIGH]

## 2. Implemented Evidence

| Area | Evidence |
| --- | --- |
| Built-in fixture set | `pkg/conformance.BuiltinFixtures` includes `binance-like-range` and `bybit-like-prev-link` cases.[COMPUTED, HIGH] |
| Binance-like policy | `BinanceLikeRangeFixture` validates range sequence continuity and stable replay hash.[COMPUTED, HIGH] |
| Bybit-like policy | `BybitLikePrevLinkFixture` validates previous-update-link continuity and stable replay hash.[COMPUTED, HIGH] |
| Negative proof | `TestBybitLikeFixtureRejectsBrokenPrevLink` rejects a broken `prev_link` transition.[COMPUTED, HIGH] |
| CI gate | `.github/workflows/ci.yml` runs `bash scripts/adapter-conformance-gate.sh` in main CI.[COMPUTED, HIGH] |

## 3. Validation

| Command / Check | Result |
| --- | --- |
| `GOWORK=off go vet ./...` | PASS |
| `GOWORK=off go test ./...` | PASS |
| `GOWORK=off go test -race ./...` | PASS |
| `bash scripts/boundary-gates.sh` | PASS |
| `bash scripts/adapter-conformance-gate.sh` | PASS |
| `bash scripts/replay-determinism-gate.sh` | PASS |
| `bash scripts/gap-injection-gate.sh` | PASS |
| GitHub Actions run `29036729299` | PASS |

Remote CI job `test` completed with success for Vet, Test, Race Test, Boundary Gate, Adapter Conformance Gate, Replay Determinism Gate and Gap Injection Gate.[COMPUTED, HIGH]

## 4. Stable Fixture Hashes

| Fixture | Expected Hash |
| --- | --- |
| `binance-like-range` | `f1cb3940b1df20fbb430e4451d3a18d4d00b3c52669da268f193148e3bede8d5` |
| `bybit-like-prev-link` | `4c51a7c39c9a0550d54690c7d6e2ff4c0cde29b8f14c1dcadc78d4ea060b6abc` |

## 5. Claim Boundary

This evidence closes the second venue-style conformance fixture follow-up on post-release `main`; it is not a new release tag.[COMPUTED, HIGH]

The module still cannot claim production cross-venue runtime completeness until a real second venue adapter or equivalent live integration passes the same contract gate.[INFERRED, HIGH]

Binance production runtime migration also remains separate from this fixture evidence.[COMPUTED, HIGH]

---

[RULES I BROKE]：无
