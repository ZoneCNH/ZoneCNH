# Binance governance closure review — #869 #871 #893 #894 #895 #896

- Date: 2026-06-23
- Worker: worker-3
- Scope: governance cleanup/audit slice only; no runtime edits; no `scripts/check-binance-docs.sh` edits.
- Source issue list: `.omx/context/binance-open-issues-20260622T162518Z.md`

---

## Summary matrix

| Issue | Local status after this slice | Evidence | Closure decision |
|---|---|---|---|
| #869 | Runtime feasibility refreshed cleanly for the required local command set | `/home/binance` branch `fix/binance-issues`; clean short status; `./scripts/boundary-gates.sh` PASS 10/10; `go test ./...`, `go vet ./...`, `go test ./... -race -count=1`, and `golangci-lint run` passed. | **Evidence gap closed for this audit slice.** Runtime release closure still belongs to the implementation owner and any extra smoke/deploy checks in `STANDARD.md`. |
| #871 | Thin standard entrypoint verified | `module/binance/STANDARD.md` v0.1.0; `RULES.md` R9 includes `STANDARD.md`. | **Closed for standard entrypoint.** Automation coverage remains tracked by separate P0 doc gate script work (#870). |
| #893 | SPEC §4 contains distributed constraints and explicit analysis links | `module/binance/SPEC.md` §4 now links to `DEEP-ANALYSIS.md` §0/§12 and `docs/migrations/binance-v2-upgrade.md`. | **Closed for governance docs.** Full DEEP-ANALYSIS compression can be handled separately without reopening the SPEC authority link. |
| #894 | Migration target and index wiring created | `docs/migrations/binance-v2-upgrade.md`; `docs/migrations/README.md`; `module/binance/SPEC.md` §21 migration table row. | **Closed for migration anchor.** The file intentionally indexes §12 instead of duplicating the full historical audit body. |
| #895 | Active prose compressed | `module/binance/README.md`, `module/binance/goal.md`, and `module/binance/SPEC.md` front matter now point to BR-001 / Appendix B instead of repeating legacy module detail. | **Closed for the requested compression pass.** Canonical gate, migration, task, changelog, and report references remain intentionally literal. |
| #896 | Coverage audit artifact created | `docs/report/binance/commit-coverage-audit-20260623.md` covers the newest 50 local preserve/stash/backup/WIP candidates. | **Partially satisfied.** Local git evidence alone cannot prove PR/head lineage or absence from main for all candidates. |

---

## #869 runtime feasibility note

Worker-3 treated #869 as an evidence/feasibility issue, not a docs-only closure issue. Worker-2 then refreshed the runtime command set from `/home/binance` and closed the local feasibility gap.

Fresh command evidence collected from `/home/binance` on 2026-06-23:

```text
$ git status --short --branch
## fix/binance-issues

$ ./scripts/boundary-gates.sh
=== binance boundary-gates (10 gates) ===
PASS  §2  no legacy binance-market
PASS  §3  client must not import server internals
PASS  §4  server must not import client internals
PASS  §5  no cs package as runtime dependency
PASS  §6  no same-process C/S communication
PASS  §7  server owns binance-specific storage only
PASS  §8  wire contract externality
PASS  §9  domain_market is semantic source
PASS  §10  admin surface boundary
PASS  §11  go.mod dependency compliance

Results: 10 passed, 0 failed

$ go test ./...
PASS

$ go vet ./...
PASS

$ go test ./... -race -count=1
PASS

$ golangci-lint run
PASS
```

#869 is closed for local runtime feasibility evidence. Release closure still requires any live smoke/deploy evidence that the runtime owner treats as release-gating.

---

## Worker-3 changes made

- Added `module/binance/STANDARD.md` as the #871 thin standard entrypoint.
- Updated `module/binance/RULES.md` R9 so document existence checks include `STANDARD.md`.
- Added this governance closure review for the worker-3 issue slice.
- Added the local 50-candidate commit coverage report for #896.
- Updated the 2026-06-22 iteration plan issue mapping so #893-#896 are no longer listed as “待建 issue”.
- Compressed active `binance-market` prose in README, goal, and SPEC overview sections for #895 while preserving canonical gate/migration literals.

---

## Known gaps intentionally not hidden

1. #896 requires GitHub/PR metadata or an equivalent authoritative mapping to prove branch/head coverage beyond local log evidence.
2. Runtime release closure still needs any live smoke/deploy checks required by the implementation owner before a release DoD claim.
3. Remote CI and release tag evidence are not proven by this local audit.
