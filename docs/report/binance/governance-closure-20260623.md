# Binance governance closure review — #869 #871 #893 #894 #895 #896

- Date: 2026-06-23
- Worker: worker-3
- Scope: governance cleanup/audit slice only; no runtime edits; no `scripts/check-binance-docs.sh` edits.
- Source issue list: `.omx/context/binance-open-issues-20260622T162518Z.md`

---

## Summary matrix

| Issue | Local status after this slice | Evidence | Closure decision |
|---|---|---|---|
| #869 | Runtime evidence partially refreshed | `/home/binance` branch `fix/binance-issues`; `./scripts/boundary-gates.sh` PASS 10/10; runtime tree still has untracked `.worktree/`; `go test ./...` and `go vet ./...` both failed on module checksum mismatch for `github.com/ZoneCNH/decimalx@v1.0.0`. | **Do not close from docs only.** Needs clean runtime tree plus full gate/test/race/vet/lint/smoke evidence. |
| #871 | Thin standard entrypoint created | `module/binance/STANDARD.md` v0.1.0; `RULES.md` R9 now includes `STANDARD.md`. | **Partially satisfied.** Final closure waits for the P0 doc gate script (#870) to include/check `STANDARD.md`. |
| #893 | SPEC §4 already contains distributed constraints | `module/binance/SPEC.md` §4 has independent client/server + natsx/NATS + boundary constraints; `DEEP-ANALYSIS.md` §0 still contains the full duplicated narrative. | **Not closed.** Needs explicit DEEP-ANALYSIS §0 reduction/reference update under the owner of that shared surface. |
| #894 | Migration target still absent | `docs/migrations/binance-v2-upgrade.md` was not present before this slice and was not created by worker-3 to avoid broad migration edits. | **Not closed.** Needs DEEP-ANALYSIS §12 migration + report index update. |
| #895 | Legacy references still high | `grep -rn 'binance-market' module/binance/ --include='*.md' \| wc -l` measured 69 before this slice. | **Not closed.** Needs a dedicated compression pass and exception-preserving verification. |
| #896 | Coverage audit artifact created | `docs/report/binance/commit-coverage-audit-20260623.md` covers the newest 50 local preserve/stash/backup/WIP candidates. | **Partially satisfied.** Local git evidence alone cannot prove PR/head lineage or absence from main for all candidates. |

---

## #869 runtime feasibility note

Worker-3 treated #869 as an evidence/feasibility issue, not a docs closure issue.

Fresh command evidence collected from `/home/binance`:

```text
$ git status --short --branch
## fix/binance-issues
?? .worktree/

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
verifying github.com/ZoneCNH/decimalx@v1.0.0: checksum mismatch
SECURITY ERROR

$ go vet ./...
verifying github.com/ZoneCNH/decimalx@v1.0.0: checksum mismatch
SECURITY ERROR
```

Because the runtime tree is not clean, Go verification is blocked by a checksum mismatch, and the full requested command set also includes race/lint/smoke evidence, #869 remains open pending runtime-owner verification.

---

## Worker-3 changes made

- Added `module/binance/STANDARD.md` as the #871 thin standard entrypoint.
- Updated `module/binance/RULES.md` R9 so document existence checks include `STANDARD.md`.
- Added this governance closure review for the worker-3 issue slice.
- Added the local 50-candidate commit coverage report for #896.
- Updated the 2026-06-22 iteration plan issue mapping so #893-#896 are no longer listed as “待建 issue”.

---

## Known gaps intentionally not hidden

1. `scripts/check-binance-docs.sh` is absent in this worktree and belongs to the worker-1/P0 script slice.
2. `/home/binance` is not fully clean because `.worktree/` is untracked.
3. #893-#895 require edits to shared governance/analysis surfaces that were not safe to perform inside worker-3's narrow audit slice.
4. #896 requires GitHub/PR metadata or an equivalent authoritative mapping to prove branch/head coverage beyond local log evidence.
