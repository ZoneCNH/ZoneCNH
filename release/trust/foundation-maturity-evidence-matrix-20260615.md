# Foundation Maturity Evidence Matrix — release evidence reconciliation

Generated: 2026-06-15T09:57Z
Scope: safe local validation commands for proving current FoundationX maturity claims; only evidence-backed local release reconciliation is allowed, while open blockers and external proof dimensions stay non-✅.

## Governance boundary

- Read constraints from `/home/ZoneCNH/.omx/context/foundation-maturity-green-20260615T100835Z.md`, `AGENTS.md`, and `CONSTITUTION.md`.
- No edits on `main`, no push, no GitHub release publication, no external-repo edits, no credential-gated actions.
- `release=false` implies `factory=false`; open blockers force `factory=false`; open release blockers force `release=false`.
- `scripts/audit-status.py` is a projection consistency guard only; `release/trust/index.json` explicitly says `claim_policy.audit_status_factory_grade_proof=false`.

## Worker-2 release evidence reconciliation — 2026-06-15T10:45Z

- Release evidence reconciliation audited `xlib-harness`, `xlib-evidence`, `clickhousex`, `contracts`, `transportx`, and `domainx`.
  - Integrated finding: `xlib-harness`, `xlib-evidence`, `clickhousex`, `contracts`, and `transportx` remain `release=false` / `factory=false` in the local fact layer and public projections.
  - `domainx` is the separated case with `release=true` and `factory=false`.
  - Evidence boundary: `xlib-harness` and `xlib-evidence` lack public tag/GitHub Release proof; `clickhousex` still has open release blocker `BLK-003`; `contracts` and `transportx` require upstream source-repo tag/release alignment before local projection changes; `domainx` must keep factory non-✅ until adoption/factory evidence is archived.
- `Kuhn` (`019ecac4-4ac1-7da1-a66d-2eb365ec86cb`) audited factory blockers for `natsx`, `postgresx`, `taosx`, and `ossx`.
  - Integrated finding: `BLK-001`, `BLK-002`, `BLK-003`, `BLK-006`, `BLK-007`, and `BLK-008` remain open.
  - Evidence boundary: `natsx` still lacks four-source arbiter and production TLS/SLO evidence; `postgresx` and `taosx` have local remediation paths but no fresh closure evidence; `ossx` still needs a complete public-facing release/evidence trail.
- Decision: do not modify `.foundationx/status/index.json`, `.foundationx/blockers.json`, or `release/trust/index.json`; the machine facts are already aligned, and this task records the no-overclaim evidence boundary only.
- Projection cross-check: `STATUS.md`, `README.md`, `ARCHITECTURE.md`, `foundation-bom.yaml`, `release/trust/index.json`, and `release/manifest/latest.json` require no fact flips after reconciliation; local guards still prove `release_published=15`, six open blockers, and no trust-manifest drift.


## Worker-2 factory blocker closure packets — 2026-06-15T11:10Z

Source of truth: `/home/ZoneCNH/.omx/context/foundation-maturity-green-20260615T110330Z.md`, `.foundationx/status/index.json`, `.foundationx/blockers.json`, `foundation-bom.yaml`, `STATUS.md`, and local module probes under `/home/{module}`. This packet records the exact remaining proof needed to close Worker-2's factory blockers without changing the authoritative fact layer.

| Blocker | Local evidence inspected | Closure decision | Required closure packet before `factory=true` |
| --- | --- | --- | --- |
| `BLK-001` `natsx` four-source arbiter | `/home/natsx@dca851c`; `release/evidence/goalcli/GOAL-20260603-XLIB-GOALCLI-001.json`; module docs and release templates. Subagent probe found strong embedded behavior evidence but explicitly partial traceability / formal release proof. | Keep open. No committed four-source 98+ arbiter archive was found. | Archive the missing Codex + Copilot arbiter verdicts alongside the existing human/rules sources, record the composite score `>=98`, and attach hashes/paths for the final verdict bundle. |
| `BLK-002` `natsx` production TLS gate | `/home/natsx@dca851c`; no committed production TLS/mTLS/SLO closure artifact surfaced in the local evidence-name probe. Subagent probe confirmed live-dev smoke exists but production TLS breadth and SLO thresholds remain missing. | Keep open. Local smoke/dev integration cannot substitute for credentialed production TLS evidence. | Archive production TLS profile evidence covering good CA, bad CA, and mTLS cases, plus explicit SLO threshold results and release-governance signoff. |
| `BLK-006` `postgresx` coverage + Docker integration | `/home/postgresx@d250032`; Docker workflow/compose/toolchain files and `release/manifest/v1.0.0.json` exist, but no `v1.0.1` or release-history closure path was found. Subagent probe confirmed the blocker context still records 52.4% coverage and skipped Docker integration. | Keep open. Existing `v1.0.0` evidence is not enough to prove the requested coverage uplift, unskipped Docker integration, or successor release trail. | Archive fresh unit-coverage evidence at the required threshold, unskipped Docker integration logs, release-history/manifest ancestry reconciliation, and successor release evidence such as `v1.0.1` unless an explicit retag/manifest-contract decision is authorized. |
| `BLK-007` `taosx` SPEC/tasks quality | `/home/taosx@bf69c39`; scorecard/spec/release-quality files exist, but the authoritative fact layer and subagent probe still identify SPEC score `67` / tasks quality gap. | Keep open. Existing tooling does not prove the required SPEC WHEN/THEN remediation or refreshed four-source score. | Archive the repaired SPEC/tasks artifacts, a four-source score with composite `>=98`, and updated task evidence showing the prior low-score condition is resolved. |
| `BLK-008` `ossx` public evidence archive | `/home/ossx@4309046`; CI workflow, coverage outputs, `README.md` with 2 lines, and `docs/identity.md` with 25 lines. No full API docs, integration evidence, quickstart, or release-manifest archive was found. | Keep open. Local coverage/CI presence is insufficient for the public-evidence blocker. | Archive public API docs, quickstart, integration-test evidence, release manifest, and any CI/workflow evidence needed to connect those artifacts to a release-quality proof. |

Decision: preserve `factory=false` for `natsx`, `postgresx`, `taosx`, and `ossx`; do not edit `.foundationx/status/index.json`, `.foundationx/blockers.json`, `STATUS.md`, or `foundation-bom.yaml` for this lane. The only local change is this closure-packet evidence record so future work can close the blockers with concrete artifacts rather than inferred green status.

### `BLK-002` natsx production TLS closure packet

Governance decision: keep `BLK-002` open until the production TLS packet below is archived. The existing `/home/natsx` live-dev smoke proves redacted auth loading and secret-safe test output only; it is not production TLS evidence and must not be used to flip release/factory projections.

Required archive before closure:

- Authorized endpoint provenance: production NATS URL class, environment owner, collection timestamp, and approver; store only redacted endpoint details when hostnames are sensitive.
- Good CA profile: successful TLS connection using the approved CA bundle, with TLS version/cipher, certificate SAN/issuer/expiry summary, and secret-safe command output.
- Bad CA profile: failed connection using an intentionally untrusted CA bundle, proving certificate verification is enforced.
- mTLS profile: client-certificate success/failure evidence when mTLS is part of the production profile, with certificate paths and subjects redacted as needed.
- SLO threshold results: explicit publish/request/JetStream threshold results from the same authorized profile, linked to the natsx benchmark/SLO gate.
- Governance signoff: release-governance reviewer, SRE/environment approver, artifact paths, and hashes for all logs; logs must exclude credentials, tokens, payloads, and credential-bearing endpoints.

Suggested safe command shape for the good-CA smoke:

```sh
NATSX_LIVE_INTEGRATION=1 \
FOUNDATIONX_NATS_URL=<redacted-production-tls-url> \
FOUNDATIONX_NATS_USERNAME=<redacted-or-empty> \
FOUNDATIONX_NATS_PASSWORD=<redacted-or-empty> \
FOUNDATIONX_NATS_TOKEN=<redacted-or-empty> \
FOUNDATIONX_NATS_NKEY=<redacted-or-empty> \
FOUNDATIONX_NATS_CA_FILE=<authorized-ca-file> \
GOWORK=off go test ./pkg/natsx -run TestLiveNATSIntegration -count=1 -v
```

Run this command only from an authorized environment with approved credentials. Store the resulting redacted log in the release evidence archive and cross-link it from `module/natsx/TRACEABILITY.md`; until then, no local documentation edit closes `BLK-002`.

## Minimal evidence matrix

| Claim / dimension | Fact source paths | Safe local command | Local result | What this proves | What it does not prove |
| --- | --- | --- | --- | --- | --- |
| Branch/edit safety | `AGENTS.md`, `.git` | `git branch --show-current`; `git status --short --branch`; `git diff --check` | detached worker worktree; `git diff --check` exit 0 | Work occurred off `main`; patch has no whitespace errors | Remote branch state, CI, push/release status |
| Foundation fact-layer consistency | `.foundationx/status/index.json`, `.foundationx/blockers.json`, `.foundationx/repo-contract.json`, `scripts/audit-status.py` | `python3 scripts/audit-status.py --foundationx-only` | `Summary: 22 passed, 0 failed` | Machine facts obey local invariants: 20 modules, 20 spec complete, 20 impl complete, 15 release, 7 live, 9 factory, release/blocker forcing rules | Factory-grade proof; freshness of external release/CI/runtime evidence |
| Public projection consistency | `README.md`, `ARCHITECTURE.md`, `STATUS.md`, `module/README.md`, `.foundationx/*`, `scripts/audit-status.py` | `python3 scripts/audit-status.py` | `Summary: 49 passed, 0 failed`; 404 check skipped unless `--network` | Public status rows match fact-layer release/factory values; factory ✅ rows have no open blockers | Network reachability, GitHub release existence, external CI results |
| Status CI gate | `.github/ci/status-consistency-check.sh`, `STATUS.md`, `.foundationx/*` | `bash .github/ci/status-consistency-check.sh` | exit 0; status consistency and FoundationX guard passed | Repo status tables, counts, and fact-layer projections are locally consistent | Remote CI execution on GitHub |
| Task topology gate | `.github/ci/task-spec-validate.sh`, `module/*/tasks/*.md` | `bash .github/ci/task-spec-validate.sh` | exit 0; `146` tasks validated | Task IDs, spec refs, AC coverage, dependencies, and in-progress file-conflict checks pass locally | Human PR review or cross-repo task completion |
| Spec lint gate | `.github/ci/spec-lint.sh`, `module/*/SPEC.md` | `bash .github/ci/spec-lint.sh` | exit 1 with pre-existing spec issues | Identifies remaining spec-format defects that block broader governance proof | Cannot be counted as green until listed defects are remediated |
| Traceability gate | `.github/ci/traceability-check.sh`, `module/*/TRACEABILITY.md` | `TRACEABILITY_STRICT=1 bash .github/ci/traceability-check.sh` | exit 1 with pre-existing traceability defects | Shows many Foundation modules trace locally, but strict repo-wide traceability is not fully green | Cannot prove all modules' FR↔evidence↔TC closure yet |
| Deployment boundary | `.github/ci/deploy-policy-guard.sh`, `docs/ci-deployment.md`, `docs/governance/DEPLOYMENT.md` | `bash .github/ci/deploy-policy-guard.sh` | exit 0; `deployment_workflows=0` | Business repo has no inline deployment workflow and preserves SRE boundary | Real deployment, environment approval, runner/secrets success |
| Release trust package | `release/trust/index.json`, `release/trust/open-blockers.json`, `release/trust/projection-guard.json`, `release/trust/summary.json` | `jq '{summary,open_blockers,projection_guard,claim_policy,missing_sources}' release/trust/index.json` | summary matches fact layer; `missing_sources=[]`; `reason_present=true`; `audit_status_factory_grade_proof=false` | Trust package records projection guard and the no-overclaim policy | Public release/tag publication or external evidence closure |

## Current machine snapshot

Command:

```sh
jq '{total_modules,summary,non_green_release:[.modules|to_entries[]|select(.value.release==false)|.key],non_green_factory:[.modules|to_entries[]|select(.value.factory==false)|.key],factory_na:[.modules|to_entries[]|select(.value.factory=="N/A")|.key]}' .foundationx/status/index.json
```

Result:

- `total_modules`: 20
- `summary`: `spec_complete=20`, `impl_complete=20`, `release_published=15`, `live_integration=7`, `factory_grade=9`
- `release=false`: `xlib-harness`, `xlib-evidence`, `clickhousex`, `contracts`, `transportx`
- `factory=false`: `xlib-harness`, `xlib-evidence`, `natsx`, `postgresx`, `taosx`, `ossx`, `clickhousex`, `contracts`, `transportx`, `domainx`
- `factory=N/A`: `testkitx` (test-only; not a green claim)

## Remaining non-✅ dimensions

- Release remains non-✅ for `xlib-harness`, `xlib-evidence`, `clickhousex`, `contracts`, `transportx`.
- `domainx` public v1.0.1 GitHub Release/tag is observed and reconciled to local fact-layer/trust release=true; factory remains non-✅ until adoption/factory evidence is archived.
- Factory remains non-✅ for `xlib-harness`, `xlib-evidence`, `natsx`, `postgresx`, `taosx`, `ossx`, `clickhousex`, `contracts`, `transportx`, `domainx`.
- Strict spec lint is non-✅ because of pre-existing defects in `contracts`, `decimalx`, `domain-exchange`, `domain-macro`, `domain-market`, `kafkax`, `postgresx`, `xlib-evidence`, and `xlib-harness`, plus warnings in `backtestx` and `taosx`.
- Strict traceability is non-✅ because of pre-existing defects in `xlibgate`, `xlib-harness`, `xlib-evidence`, `natsx`, `contracts`, and `transportx`, plus unknown-module traceability warnings.
- Open blockers remain:
  - `BLK-001` `natsx` governance critical
  - `BLK-002` `natsx` security critical
  - `BLK-003` `clickhousex` release high
  - `BLK-006` `postgresx` quality medium
  - `BLK-007` `taosx` spec-quality medium
  - `BLK-008` `ossx` evidence medium

## Local fixable changes

- Add this evidence matrix so the current local proof boundary is reviewable and repeatable.
- Locally fix spec-lint issues in affected `module/*/SPEC.md` files without changing release/factory facts.
- Locally fix traceability metadata/FR/TC/status issues in affected `module/*/TRACEABILITY.md` and `module/*/SPEC.md` files without flipping blocked modules green.
- Add missing local evidence archives only when the evidence actually exists and is not a credentialed/external action.

## User-authorized external actions required before full ✅ can be honest

- Publish or verify public GitHub releases/tags/manifest evidence for `xlib-harness`, `xlib-evidence`, `clickhousex`, `contracts`, and `transportx` where appropriate.
- Keep `domainx` factory non-✅ until source/CI, adoption, and factory evidence are archived; release was reconciled from observed public v1.0.1 GitHub Release/tag.
- Resolve credentialed or remote CI evidence gaps; local checks cannot replace GitHub Actions or protected-environment results.
- Complete cross-repo PR/release alignment for `contracts` and `transportx`; keep any remaining `domainx` source/CI/adoption alignment outside release separate from factory-grade claims.
- For `natsx`, provide four-source arbiter archive and production TLS gate evidence before closing `BLK-001`/`BLK-002`.
- For `postgresx`, provide coverage and Docker integration evidence before closing `BLK-006`.
- For `taosx`, remediate SPEC/tasks quality evidence before closing `BLK-007`.
- For `ossx`, provide archived API docs, integration evidence, quickstart evidence, and release-manifest proof before closing `BLK-008`.

## Worker-1 public release evidence refresh — 2026-06-15T12:00Z

Scope: read-only public GitHub checks for `xlib-harness`, `xlib-evidence`, `clickhousex`, `contracts`, `transportx`, and `domainx`. This refresh preserves the existing local fact layer because no new public evidence proves the blocked release/factory dimensions green.

| Module | Public evidence refreshed | Decision |
| --- | --- | --- |
| `xlib-harness` | GitHub API `releases/latest` returned `404`, release list returned `[]`, tag list returned `[]`, and contents checks for `.repo-contract.yaml`, `.foundationx/repo-contract.json`, and `release/manifest/latest.json` returned `404` where reachable. `git ls-remote --tags --refs https://github.com/ZoneCNH/xlib-harness.git` also returned no tag rows. | Keep `release=false` / `factory=false`. |
| `xlib-evidence` | GitHub API `releases/latest` returned `404`, release list returned `[]`, tag list returned `[]`, and contents/raw checks for `.repo-contract.yaml`, `.foundationx/repo-contract.json`, and `release/manifest/latest.json` returned `404`. `git ls-remote --tags --refs https://github.com/ZoneCNH/xlib-evidence.git` returned no tag rows. | Keep `release=false` / `factory=false`. |
| `clickhousex` | GitHub API `releases/latest` returned `404`, release list returned `[]`, tag list returned `v1.0.1` at `47098ecdcb8ea2c105f5da362c4f2d6182d85964`, and public `.repo-contract.yaml` records `table_version: v1.0.1`, `latest_git_tag: v1.0.1`, `all_aligned: true`. Raw checks found no `.foundationx/repo-contract.json` or `release/manifest/latest.json`. | Keep `release=false` under open `BLK-003`; a tag/contract alone is not a public GitHub Release/manifest closure packet. |
| `contracts` | `git ls-remote --tags --refs https://github.com/ZoneCNH/contracts.git` returned `v1.0.1-spec` at `8c15f061e991ea372d6b831f3d572ee41b3d9323`. Public `.repo-contract.yaml` records `table_version: v1.0.1-spec`, `latest_git_tag: ""`, `all_aligned: false`; raw checks found no `.foundationx/repo-contract.json` or `release/manifest/latest.json`. | Keep `release=false` / `factory=false` until upstream source-repo release/tag/manifest alignment is proven. |
| `transportx` | `git ls-remote --tags --refs https://github.com/ZoneCNH/transportx.git` returned `v1.1.1-spec` at `bb61925161120da04bf8c8b36206275cfb74ba48`. Public `.repo-contract.yaml` records `table_version: v1.1.1-spec`, `latest_git_tag: ""`, `all_aligned: false`; raw checks found no `.foundationx/repo-contract.json` or `release/manifest/latest.json`. | Keep `release=false` / `factory=false` until upstream source-repo release/tag/manifest alignment is proven. |
| `domainx` | `git ls-remote --tags --refs https://github.com/ZoneCNH/domainx.git` returned `v0.1.0`, `v1.0.0`, and `v1.0.1`; public release HTML for `/releases` and `/releases/latest` contains `releases/tag/` and `v1.0.1`, with `/releases/latest` titled `Release domainx v1.0.1 · ZoneCNH/domainx · GitHub`. Raw checks did not find `.foundationx/repo-contract.json` or `release/manifest/latest.json`. | Preserve the separated current state: `release=true`, `factory=false`; do not infer factory/adoption proof from release page evidence. |

Evidence caveat: unauthenticated GitHub API quota was exhausted after the `clickhousex` probe, so later module API calls were supplemented with public `git ls-remote`, raw-file, and release-page checks. Generic GitHub release page titles without `releases/tag/` evidence were not treated as proof of a published release.
