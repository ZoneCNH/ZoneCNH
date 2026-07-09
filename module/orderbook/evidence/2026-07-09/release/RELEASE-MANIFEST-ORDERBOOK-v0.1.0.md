# RELEASE-MANIFEST-ORDERBOOK-v0.1.0

> Module: orderbook
> Version: v0.1.0
> Date: 2026-07-09
> Release Type: GitHub Release
> Runtime Path: `/home/workspace/orderbook`
> Runtime Repository: `https://github.com/ZoneCNH/orderbook`
> Goal: GOAL-20260709-001
> Runtime Commit: `2258726269fb3b7162c78af95acb1de3ef739319`
> Release Tag: `v0.1.0`
> Release URL: `https://github.com/ZoneCNH/orderbook/releases/tag/v0.1.0`

---

## 1. Scope

This manifest records the first GitHub Release for the `orderbook` runtime library.[COMPUTED, HIGH]

The release includes adapter contracts, event schema, deterministic book mutation, BookHash, replay runner, quality policy, conformance runner, CI workflow and gate scripts.[COMPUTED, HIGH]

`module/registry.yaml` records `orderbook` as `lifecycle: active` after this release evidence was created.[COMPUTED, HIGH]

---

## 2. Artifacts

| Artifact | Path / URL |
| --- | --- |
| Runtime repository | `https://github.com/ZoneCNH/orderbook` |
| Runtime local path | `/home/workspace/orderbook` |
| GitHub Release | `https://github.com/ZoneCNH/orderbook/releases/tag/v0.1.0` |
| Release tag | `v0.1.0` |
| Release commit | `2258726269fb3b7162c78af95acb1de3ef739319` |
| Governance module | `module/orderbook/` |
| Test evidence | `module/orderbook/evidence/2026-07-09/test/EVID-ORDERBOOK-VALIDATION-20260709.md` |
| Review evidence | `module/orderbook/evidence/2026-07-09/review/EVID-ORDERBOOK-REVIEW-20260709.md` |
| Retrospective evidence | `module/orderbook/evidence/2026-07-09/retrospective/RETRO-ORDERBOOK-v0.1.0.md` |

---

## 3. Validation Summary

| Command / Gate | Result | Evidence |
| --- | --- | --- |
| `GOWORK=off go vet ./...` | PASS | local and remote CI |
| `GOWORK=off go test ./...` | PASS | local and remote CI |
| `GOWORK=off go test -race ./...` | PASS | local and remote CI |
| `bash scripts/boundary-gates.sh` | PASS | local and remote CI |
| `bash scripts/replay-determinism-gate.sh` | PASS | local and remote CI |
| `bash scripts/gap-injection-gate.sh` | PASS | local and remote CI |
| `bash docs/goal/tools/goal-workflow.sh validate` | PASS | local ZoneCNH governance validation |

Remote CI runs:

- main: `https://github.com/ZoneCNH/orderbook/actions/runs/29020604242`.[COMPUTED, HIGH]
- tag `v0.1.0`: `https://github.com/ZoneCNH/orderbook/actions/runs/29020608940`.[COMPUTED, HIGH]

---

## 4. Rollback

Rollback is to keep the GitHub Release as historical evidence, publish a superseding patch release if the library contract is wrong, and downgrade `module/registry.yaml` lifecycle only through a separate governance decision.[FRAME, HIGH]

No production service depends on `/home/workspace/orderbook` in this turn; Binance runtime migration remains a separate follow-up task.[COMPUTED, HIGH]

---

## 5. Release Decision

GitHub Release v0.1.0: PASS.[FRAME, HIGH]

GOB-10 Release Gate: PASS.[FRAME, HIGH]

[RULES I BROKE]：无
