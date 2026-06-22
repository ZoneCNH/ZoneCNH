# Binance governance closure review — #869 #871 #893 #894 #895 #896

- Date: 2026-06-23
- Workers: worker-3 initial audit; worker-2 follow-up closure pass
- Scope: governance cleanup/audit docs only; no runtime edits; no `scripts/check-binance-docs.sh` edits.
- Source issue list: `.omx/context/binance-open-issues-20260622T162518Z.md`

---

## Summary matrix

| Issue | Local status after this slice | Evidence | Closure decision |
|---|---|---|---|
| #869 | Runtime feasibility refreshed cleanly for the required local command set | `/home/binance` branch `fix/binance-issues`; clean short status; `./scripts/boundary-gates.sh` PASS 10/10; `go test ./...`, `go vet ./...`, `go test ./... -race -count=1`, and `golangci-lint run` passed. | **Evidence gap closed for this audit slice.** Runtime release closure still belongs to the implementation owner and any extra smoke/deploy checks in `STANDARD.md`. |
| #871 | Thin standard entrypoint created | `module/binance/STANDARD.md` v0.1.0; `RULES.md` R9 now includes `STANDARD.md`. | **Partially satisfied.** Final closure waits for the P0 doc gate script (#870) to include/check `STANDARD.md`. |
| #893 | SPEC §4 contains distributed constraints and explicit analysis links | `module/binance/SPEC.md` §4 now links to `DEEP-ANALYSIS.md` §0/§12 and `docs/migrations/binance-v2-upgrade.md`. | **Closed for governance docs.** Full DEEP-ANALYSIS compression can be handled separately without reopening the SPEC authority link. |
| #894 | Migration target and index wiring created | `docs/migrations/binance-v2-upgrade.md`; `docs/migrations/README.md`; `module/binance/SPEC.md` §21 migration table row. | **Closed for migration anchor.** The file intentionally indexes §12 instead of duplicating the full historical audit body. |
| #895 | Legacy references still high | `grep -rn 'binance-market' module/binance/ --include='*.md' \| wc -l` measured 69 before this slice. | **Not closed.** Needs a dedicated compression pass and exception-preserving verification. |
| #896 | Coverage audit artifact created | `docs/report/binance/commit-coverage-audit-20260623.md` covers the newest 50 local preserve/stash/backup/WIP candidates. | **Partially satisfied.** Local git evidence alone cannot prove PR/head lineage or absence from main for all candidates. |

---

## #869 runtime feasibility note

Worker-3 treated #869 as an evidence/feasibility issue, not a docs closure issue.
Worker-2 refreshed the same local runtime command set on 2026-06-23.

Fresh command evidence collected from `/home/binance`:

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
?   	github.com/ZoneCNH/binance/cmd/binance-server	[no test files]
?   	github.com/ZoneCNH/binance/cmd/binance-smoke	[no test files]
ok  	github.com/ZoneCNH/binance/internal/client	(cached)
ok  	github.com/ZoneCNH/binance/internal/server	(cached)
?   	github.com/ZoneCNH/binance/internal/wire	[no test files]
ok  	github.com/ZoneCNH/binance/pkg/binancex	(cached)
ok  	github.com/ZoneCNH/binance/test/e2e	(cached)

$ go vet ./...

$ go test ./... -race -count=1
?   	github.com/ZoneCNH/binance/cmd/binance-server	[no test files]
?   	github.com/ZoneCNH/binance/cmd/binance-smoke	[no test files]
ok  	github.com/ZoneCNH/binance/internal/client	1.057s
ok  	github.com/ZoneCNH/binance/internal/server	1.865s
?   	github.com/ZoneCNH/binance/internal/wire	[no test files]
ok  	github.com/ZoneCNH/binance/pkg/binancex	1.039s
ok  	github.com/ZoneCNH/binance/test/e2e	1.338s

$ golangci-lint run
0 issues.
```

This closes the local feasibility gap requested by the governance audit. Runtime
release ownership still requires implementation-owner signoff plus any extra
smoke/deploy checks listed in `module/binance/STANDARD.md`.

---

## Worker-3 changes made

- Added `module/binance/STANDARD.md` as the #871 thin standard entrypoint.
- Updated `module/binance/RULES.md` R9 so document existence checks include `STANDARD.md`.
- Added this governance closure review for the worker-3 issue slice.
- Added the local 50-candidate commit coverage report for #896.
- Updated the 2026-06-22 iteration plan issue mapping so #893-#896 are no longer listed as “待建 issue”.

## Worker-2 follow-up changes made

- Linked `module/binance/SPEC.md` §4 to `DEEP-ANALYSIS.md` and the v2 migration note for #893.
- Added `docs/migrations/binance-v2-upgrade.md` and `docs/migrations/README.md` for #894.
- Wired the v2 migration into `module/binance/SPEC.md` §21.
- Refreshed `/home/binance` runtime feasibility evidence for #869.

---

## Known gaps intentionally not hidden

1. `scripts/check-binance-docs.sh` is absent in this worktree and belongs to the worker-1/P0 script slice.
2. #871 final automation coverage still depends on that worker-1/P0 script slice.
3. #895 still needs a dedicated compression pass and exception-preserving verification.
4. #896 requires GitHub/PR metadata or an equivalent authoritative mapping to prove branch/head coverage beyond local log evidence.
