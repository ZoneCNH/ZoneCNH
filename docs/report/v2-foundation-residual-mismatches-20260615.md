# v2 Foundation Trust Hardening — Residual Mismatch Report (2026-06-15)

## Purpose

Task 2 scope is report-only: identify residual mismatches that still need follow-up after the P0 trust-alignment pass, without changing the fact layer, release manifests, or CI guard logic.

## Sources checked

- `.foundationx/status/index.json`
- `.foundationx/blockers.json`
- `.foundationx/repo-contract.json`
- `docs/report/v2-trust-alignment-p0-20260614.md`
- `docs/report/v2-trust-alignment-p1-p4-roadmap-20260614.md`

## Residual mismatch ledger

| Area | Residual mismatch | Evidence | Follow-up owner/action |
| --- | --- | --- | --- |
| Release projection | Six modules remain `release=false`: `xlib-harness`, `xlib-evidence`, `clickhousex`, `contracts`, `transportx`, `domainx`. | `.foundationx/status/index.json` → `trust_hardening.release_false_modules` | Keep public projections below the fact layer until release evidence exists or cross-repo identity work lands. |
| Factory gate | Ten modules remain factory-blocked in the status fact layer: `clickhousex`, `contracts`, `domainx`, `natsx`, `ossx`, `postgresx`, `taosx`, `transportx`, `xlib-evidence`, `xlib-harness`. | `.foundationx/status/index.json` → `trust_hardening.factory_blocking_modules`; summary `factory_grade=9/20` | Do not raise `factory=true` for any listed module without closing its release/open-blocker reason first. |
| Open blocker projection | Five modules have open blockers: `clickhousex`, `natsx`, `ossx`, `postgresx`, `taosx`. | `.foundationx/blockers.json` → `factory_blocking_modules`; open IDs `BLK-001`, `BLK-002`, `BLK-003`, `BLK-006`, `BLK-007`, `BLK-008` | Keep factory projections gated until the listed blockers move to `resolved` with evidence. |
| Release-vs-factory semantics | `natsx`, `postgresx`, `taosx`, and `ossx` are `release=true` but `factory=false` because quality/security/evidence blockers remain open. | `.foundationx/status/index.json` module rows; `.foundationx/blockers.json` open blocker categories | Treat this as an intentional trust-hardening state, not a release regression; docs should explain release publication is weaker than factory readiness. |
| Blocker-index terminology | `.foundationx/blockers.json` lists only open-blocker factory blockers, while `.foundationx/status/index.json` lists open blockers plus release-false modules as factory-blocking modules. | `blockers.json` factory list has 5 modules; `status/index.json` trust-hardening factory list has 10 modules | Future reports should name the two scopes explicitly: “open-blocker factory blockers” vs “all status factory blockers.” |
| Resolved-in-repo identity work | `contracts` and `transportx` blockers are resolved locally, but the P0 report records remaining source-repo PR work. | `BLK-004`, `BLK-005` are `resolved`; P0 report “未修复项(P1-P4)” mentions source repo identity cleanup | Keep them out of open-blocker counts, but do not claim cross-repo identity completion until source repos are updated. |
| Roadmap staleness risk | The P0/P1-P4 reports still carry older residual items that are not all represented as open blockers. | `docs/report/v2-trust-alignment-p0-20260614.md`; `docs/report/v2-trust-alignment-p1-p4-roadmap-20260614.md` | Reconcile report-only residuals with the machine fact layer before using those reports as release gates. |

## Current blocker IDs to preserve in downstream work

- `BLK-001` / `BLK-002` — `natsx`: four-source arbiter archive and production TLS gate.
- `BLK-003` — `clickhousex`: public GitHub release missing.
- `BLK-006` — `postgresx`: coverage and Docker integration gap.
- `BLK-007` — `taosx`: SPEC score below gate.
- `BLK-008` — `ossx`: public engineering assets too thin.

## Recommended next safe slice

1. Keep this report as the human residual ledger.
2. If implementation is requested next, change only one high-sensitivity source at a time (`.foundationx/blockers.json`, `.foundationx/status/index.json`, or `module/FOUNDATION-DEPS.yaml`).
3. After each source change, run the fact-layer guard and public projection guard before touching public docs.
