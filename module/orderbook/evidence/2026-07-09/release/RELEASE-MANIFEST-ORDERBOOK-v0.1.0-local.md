# RELEASE-MANIFEST-ORDERBOOK-v0.1.0-local

> Module: orderbook
> Version: v0.1.0-local
> Date: 2026-07-09
> Release Type: local baseline tag
> Runtime Path: `/home/workspace/orderbook`
> Goal: GOAL-20260709-001
> Runtime Commit: `8334c3b`
> Local Tag: `v0.1.0-local`

---

## 1. Scope

This manifest records the local baseline release candidate for the `orderbook` runtime library.[COMPUTED, HIGH]

This local manifest is superseded by `RELEASE-MANIFEST-ORDERBOOK-v0.1.0.md`, which records the GitHub Release and active registry state.[COMPUTED, HIGH]

The release candidate includes adapter contracts, event schema, deterministic book mutation, BookHash, replay runner, quality policy, conformance runner and gate scripts.[COMPUTED, HIGH]

This manifest is not a GitHub Release and does not make `orderbook` active in `module/registry.yaml`.[COMPUTED, HIGH]

The local runtime repository is initialized on branch `main` with baseline commit `8334c3b` and local annotated tag `v0.1.0-local`.[COMPUTED, HIGH]

---

## 2. Artifacts

| Artifact | Path |
| --- | --- |
| Runtime module | `/home/workspace/orderbook` |
| Governance module | `module/orderbook/` |
| Test evidence | `module/orderbook/evidence/2026-07-09/test/EVID-ORDERBOOK-VALIDATION-20260709.md` |
| Review evidence | `module/orderbook/evidence/2026-07-09/review/EVID-ORDERBOOK-REVIEW-20260709.md` |
| Completion report | `report/OrderBook/ORDERBOOK-COMPLETION-REPORT-20260709.md` |
| Local git tag | `/home/workspace/orderbook` tag `v0.1.0-local` |

---

## 3. Validation Summary

| Command | Result |
| --- | --- |
| `GOWORK=off go vet ./...` | PASS |
| `GOWORK=off go test ./...` | PASS |
| `GOWORK=off go test -race ./...` | PASS |
| `bash scripts/boundary-gates.sh` | PASS |
| `bash scripts/replay-determinism-gate.sh` | PASS |
| `bash scripts/gap-injection-gate.sh` | PASS |

---

## 4. Rollback

Rollback for this local baseline is to keep `module/registry.yaml` at `lifecycle: proposed`, remove or supersede the local runtime tag before any remote push, and continue using the existing binance runtime until adapter migration is separately approved.[FRAME, HIGH]

No production service depends on `/home/workspace/orderbook` in this turn.[COMPUTED, HIGH]

---

## 5. Release Decision

Local baseline release candidate: PASS.[FRAME, HIGH]

GitHub Release / active module graduation: BLOCKED until remote repository, CI run, release tag pushed to GitHub, and release notes URL exist.[COMPUTED, HIGH]

---

[RULES I BROKE]：无
