# Goal: Binance module from spec reference to releasable C/S reference

- [COMPUTED, HIGH] Date: 2026-06-22
- [COMPUTED, HIGH] Reconciled: 2026-06-23
- [COMPUTED, HIGH] Sources: `docs/report/binance/iteration-plan-20260622.md`, `docs/report/binance/deep-analysis-20260622-v2.md`, `docs/report/binance/deep-analysis-20260622-v3.md`, `docs/report/binance/deep-analysis-20260622-v4.md`, `docs/report/binance/business-types-coverage-20260622.md`, and issues #866~#873 / #893~#896.

---

## Goal

[INFERRED, HIGH] Upgrade `module/binance` from a partially governed specification reference to a release-ready Binance C/S reference implementation path by 2026-09-30.

Target score:

```text
Current governance score: 82/100
Target governance score: 95+/100
```

The score target is not a release claim. Release readiness requires local evidence, remote CI evidence, live smoke/deploy evidence, and a release tag or equivalent owner-approved snapshot.

---

## Acceptance Criteria

| AC | Target | 2026-06-23 status | Evidence |
|---|---|---|---|
| AC-1 | Close governance drift #866/#867/#868/#872/#873 | PASS(local) | `scripts/check-binance-docs.sh` passes; root version, 4x4 natsx/Kafka matrix, task filenames, and layered runtime status are aligned. |
| AC-2 | Add executable doc consistency script #870 | PASS(local) | `scripts/check-binance-docs.sh`; CI draft in `module/binance/ci-workflow.yaml`. |
| AC-3 | Add FR-012~FR-024 lifecycle discussion draft | PASS(local) | `module/binance/DATA-LIFECYCLE.md`; `scripts/check-binance-data-lifecycle.sh` covers 13 FR anchors. |
| AC-4 | Define runtime control plane for FR-012~FR-015 | NOT COMPLETE | Discussion draft exists; implementation/spec fold remains future work. |
| AC-5 | Define historical lifecycle for FR-016~FR-019 | NOT COMPLETE | Discussion draft exists; implementation/spec fold remains future work. |
| AC-6 | Define funding / mark price / reconciliation / rehydration for FR-020~FR-022 | NOT COMPLETE | Discussion draft exists; event_type expansion and MAJOR bump are not claimed complete. |
| AC-7 | Define governance APIs for FR-023~FR-024 | NOT COMPLETE | Discussion draft exists; dynamic hot reload evidence is not claimed complete. |
| AC-8 | Refresh local runtime evidence #869 | PASS(local) | `/home/binance` boundary gates, `go test ./...`, `go vet ./...`, race test, and `golangci-lint run` passed in the 2026-06-23 worker evidence set. |
| AC-9 | Satisfy Release DoD | NOT COMPLETE | Remote CI, live smoke/deploy, authoritative PR/head lineage, and release tag evidence remain outside this local audit. |

---

## Issue Execution State

| Issue | Execution state | Closure boundary |
|---|---|---|
| #866 | CLOSED(local) | NATS 4x4 matrix complete in docs and script check. |
| #867 | CLOSED(local) | Root README version aligns with SPEC. |
| #868 | CLOSED(local) | Kafka topics use `binance.{product_line}.{event_type}.v1`; aggregate legacy topics are absent from checked docs. |
| #869 | LOCAL-EVIDENCE CLOSED | Local runtime command set passes; release/live smoke remains owner-gated. |
| #870 | CLOSED(local) | `scripts/check-binance-docs.sh` is executable and passing. |
| #871 | CLOSED(local) | `module/binance/STANDARD.md` exists and is wired through `RULES.md` R9. |
| #872 | CLOSED(local) | Runtime status wording stays layered from docs readiness. |
| #873 | CLOSED(local) | RULES task filenames resolve to existing docs. |
| #893 | CLOSED(local) | SPEC §4 links distributed constraints and analysis sources. |
| #894 | CLOSED(local) | Migration anchor exists in `docs/migrations/binance-v2-upgrade.md` and the migration index. |
| #895 | CLOSED(local) | README, goal, and SPEC overview prose now point to BR-001 / Appendix B rather than repeating legacy module detail. |
| #896 | PARTIAL(local audit) | Local newest-50 coverage audit exists; authoritative GitHub PR/head lineage is still required. |

---

## Phase Route

| Phase | Scope | 2026-06-23 state |
|---|---|---|
| 0 | Governance drift #866/#867/#868/#872/#873 | PASS(local) |
| 1 | Script and report index #870 | PASS(local) |
| 2 | DATA-LIFECYCLE discussion draft | PASS(local) |
| 3 | Realtime control FR-012~FR-015 | FUTURE |
| 4 | Historical lifecycle FR-016~FR-019 | FUTURE |
| 5 | Periodic data and reconciliation FR-020~FR-022 | FUTURE |
| 6 | Governance observability and doc cleanup #871/#893/#894/#895/#896 | PASS(local) except #896 external lineage |
| 7 | Runtime evidence #869 | PASS(local); release evidence still external |

---

## Verification Commands

Local docs verification:

```bash
bash -n scripts/check-binance-docs.sh
bash scripts/check-binance-docs.sh
bash -n scripts/check-binance-data-lifecycle.sh
bash scripts/check-binance-data-lifecycle.sh
node scripts/check.mjs
git diff --check
```

Runtime verification from `/home/binance`:

```bash
./scripts/boundary-gates.sh
go test ./...
go vet ./...
go test ./... -race -count=1
golangci-lint run
```

---

## Remaining Gates

1. [COMPUTED, HIGH] #896 cannot be fully closed from local git evidence alone; it needs authoritative GitHub PR/head metadata or an equivalent owner-approved mapping.
2. [COMPUTED, HIGH] Release DoD is not complete without remote CI, live smoke/deploy evidence, and a release tag or owner-approved release snapshot.
3. [INFERRED, MED] FR-012~FR-024 should stay in discussion/spec-fold state until the owner approves the implementation sequence and version bump plan.

[RULES I BROKE]：无
