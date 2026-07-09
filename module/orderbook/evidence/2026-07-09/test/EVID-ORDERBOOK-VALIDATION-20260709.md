# EVID-ORDERBOOK-VALIDATION-20260709

> Goal: GOAL-20260709-001
> Module: orderbook
> Date: 2026-07-09
> Runtime Path: `/home/workspace/orderbook`
> Commit Context: ZoneCNH working tree `docs/binance_production_readiness_report`
> Runtime Baseline Commit: `8334c3b`
> Runtime Release Commit: `2258726269fb3b7162c78af95acb1de3ef739319`
> Runtime Local Tag: `v0.1.0-local`
> Runtime Release Tag: `v0.1.0`
> GitHub Release: `https://github.com/ZoneCNH/orderbook/releases/tag/v0.1.0`

---

## 1. Commands

| Command | Result |
| --- | --- |
| `GOWORK=off go vet ./...` | PASS |
| `GOWORK=off go test ./...` | PASS |
| `GOWORK=off go test -race ./...` | PASS |
| `bash scripts/boundary-gates.sh` | PASS |
| `bash scripts/replay-determinism-gate.sh` | PASS |
| `bash scripts/gap-injection-gate.sh` | PASS |
| `bash docs/goal/tools/goal-workflow.sh validate` | PASS |
| GitHub Actions `main` CI | PASS |
| GitHub Actions `v0.1.0` CI | PASS |

---

## 2. Test Output Summary

```text
ok github.com/ZoneCNH/orderbook/pkg/adapter
ok github.com/ZoneCNH/orderbook/pkg/book
ok github.com/ZoneCNH/orderbook/pkg/conformance
ok github.com/ZoneCNH/orderbook/pkg/quality
ok github.com/ZoneCNH/orderbook/pkg/replay
?  github.com/ZoneCNH/orderbook/pkg/event [no test files]
?  github.com/ZoneCNH/orderbook/pkg/sync [no test files]
```

Boundary gate output:

```text
boundary gate passed
```

Replay and gap gate output:

```text
ok github.com/ZoneCNH/orderbook/pkg/replay
```

Goal workflow output:

```text
goal validation passed (strict)
Matrix check-only: 75 edges, 64 terminal, 11 non-terminal, 0 missing required fields, 0 illegal relations, 85% coverage
```

Remote CI:

```text
main: https://github.com/ZoneCNH/orderbook/actions/runs/29020604242
v0.1.0: https://github.com/ZoneCNH/orderbook/actions/runs/29020608940
```

---

## 3. AC Coverage

| AC | Evidence |
| --- | --- |
| AC-OB-001 | `pkg/adapter` tests cover range sequence and prev-link sequence. |
| AC-OB-002 | `pkg/replay` fixture completes deterministic alignment. |
| AC-OB-003 | `TestReplayGapMakesQualityUnreliable` verifies sequence break produces unreliable result. |
| AC-OB-004 | `pkg/book` test verifies `qty=0` deletion. |
| AC-OB-005 | `pkg/event` schema compiles and is consumed by runtime packages. |
| AC-OB-006 | `TestReplayDeterministicHash` replays fixture 100 times with stable hash. |
| AC-OB-007 | Replay result includes state, hash and quality timeline. |
| AC-OB-008 | Adapter and replay tests cover missing/out-of-order/prev-link gap classes. |
| AC-OB-009 | `pkg/quality` test verifies stale fail-closed quality. |
| AC-OB-010 | `pkg/conformance` validates a Binance-like fixture. |
| AC-OB-011 | `scripts/boundary-gates.sh` passes. |
| AC-OB-012 | This evidence file records command, result, fixture scope and residual risk. |

---

## 4. Residual Risks

`orderbook` is now `lifecycle: active` after GitHub Release v0.1.0 and remote CI evidence were created.[COMPUTED, HIGH]

Global `bash docs/goal/tools/goal-workflow.sh validate` passes after schema allow-list, module count, workflow-step and gate score/verdict corrections.[COMPUTED, HIGH]

The `orderbook` module count and pipeline workflow-step drift found during post-onboarding validation were corrected before this evidence was finalized.[COMPUTED, HIGH]

Second venue adapter is not implemented; cross venue platform claim remains bounded to contract/conformance readiness, not production multi-venue runtime.[COMPUTED, HIGH]

---

[RULES I BROKE]：无
