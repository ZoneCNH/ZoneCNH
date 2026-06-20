# xlib-standard production acceptance continuation audit — worker-3

Date: 2026-06-20  
Team: `xlib-standard-product-0d7965b6`  
Worker: `worker-3`  
Task: 3 — read-only acceptance/documentation/CI/coverage audit

## Scope and constraints

- Mandatory context read: `/home/ZoneCNH/.worktree/workspaces/xlib-standard/.omx/context/xlib-standard-20260619-192426.md`.
- Root documentation repo audited from `/home/ZoneCNH/.worktree/workspaces/xlib-standard`.
- Code worktree audited from `/home/xlib-standard/.worktree/workspaces/xlib-standard`.
- Shared code worktree was treated as read-only; this worker added only this audit artifact in its own generated team worktree.
- Production release remains blocked until the full required release gate set is proven from a clean code worktree and remote release/governance evidence is collected.

Subagent spawn evidence: 3, Socrates/docs 019ee25a-5fa8-7972-aa06-cb032eac1406; Curie/CI 019ee25a-60d8-7c11-baa5-1fe329c45a9f; Jason/coverage 019ee25a-6204-7e80-b3c6-3c73c92e96d0; findings integrated: docs authority/snapshot mismatch, CI/release governance gaps, missing executable coverage threshold versus score gate.

## Baseline

### Documentation repo

- Path: `/home/ZoneCNH/.worktree/workspaces/xlib-standard`
- Branch/context base: `xlib-standard`, mandatory context base `b54032e182be145dd59c95cffbe175fb46a9f819`.
- Key docs audited under `module/xlib-standard/`: `README.md`, `SPEC.md`, `TRACEABILITY.md`, `FEATURES.md`, `ACCEPTANCE.md`, `COVERAGE-MANIFEST.md`, `REMOTE-EVIDENCE.md`, `REVIEW-VERDICT.md`, and `ANALYSIS.md`.

### Code worktree

- Path: `/home/xlib-standard/.worktree/workspaces/xlib-standard`
- Branch: `xlib-standard`
- Audited short SHA: `26792dc`
- Pre-existing dirty files observed in the shared code worktree and not modified by worker-3:
  - `cmd/goalcli/main_test.go`
  - `internal/goalruntime/goalruntime_test.go`
  - `internal/releasequality/score_test.go`
  - `internal/xlibfacts/facts_test.go`
- Current manifest template version observed at `release/manifest/template.json:3`: `v1.0.1`. A patch release continuation would normally target `v1.0.2`, subject to remote tag confirmation.

## Findings

### 1. Documentation acceptance sync

**Observed evidence**

- `module/xlib-standard/COVERAGE-MANIFEST.md:1-11` defines a local analysis snapshot input list and explicitly does not make semantic validation claims.
- `module/xlib-standard/REMOTE-EVIDENCE.md:1-9` records a remote evidence boundary and requires remote API/artifact proof before claiming remote governance is enabled.
- `module/xlib-standard/REVIEW-VERDICT.md:1-12` frames the review as local snapshot evidence and says downstream adoption must be verified separately.
- `module/xlib-standard/ANALYSIS.md:1-31` states the analysis snapshot is not executable spec/status, and that upstream docs/harness remain the executable source of truth.

**Gaps**

- Documentation authority is split between snapshot-style review docs and acceptance/feature matrices. This makes it too easy to read historical local snapshots as release-ready acceptance.
- `FEATURES.md` and `ACCEPTANCE.md` imply closure through archived snapshot rows, while the conservative evidence docs still require remote/governance/downstream proof.
- `TRACEABILITY.md` uses a snapshot-oriented schema that does not fully align to feature, test, branch, and release evidence rows needed for release acceptance.
- `COVERAGE-MANIFEST.md` counts input files but does not map feature requirements, test cases, branch coverage, or release evidence.
- Gate-count/authority mismatch remains between historical SPEC wording and acceptance/Makefile release gates.

**Safe patches for the owning docs lane**

1. Add an explicit authority boundary table to `README.md` or `SPEC.md`: executable gates and current status come from the Makefile/harness plus latest release evidence, while snapshot docs are historical inputs.
2. Convert `FEATURES.md` and `ACCEPTANCE.md` rows to explicit `PASS`, `NOT RUN`, or `BLOCKED` states with command, artifact, timestamp, and code SHA.
3. Align `TRACEABILITY.md` around feature requirement, test case, branch/condition evidence, acceptance gate, and release artifact columns.
4. Expand `COVERAGE-MANIFEST.md` from file-count inventory into a semantic evidence manifest or rename/scope it clearly as inventory-only.
5. Keep `REMOTE-EVIDENCE.md` and `REVIEW-VERDICT.md` conservative until remote release, adoption, and governance evidence is proven.

### 2. CI/CD and release gates

**Observed evidence**

- `/home/xlib-standard/.worktree/workspaces/xlib-standard/Makefile:539-540` defines `ci` as a broad local gate including formatting, vet, lint, test, race, boundary, architecture, secret/security checks, contracts, governance, debt, score, and rule verification.
- `/home/xlib-standard/.worktree/workspaces/xlib-standard/Makefile:545-550` defines `release-check` with `require-gowork-off`, `ci`, integration, dependency, impact, docs, score, governance, p1/p2 runtime, debt evidence, fact audit, and evidence/hash/checks.
- `/home/xlib-standard/.worktree/workspaces/xlib-standard/Makefile:559-570` defines `release-final-check` and `release-preflight`.
- `.github/workflows/ci.yml:1-30` runs on PR/push main, installs pinned `golangci-lint`, and invokes `GOWORK=off XLIB_CONTEXT=ci_pull_request make ci`.
- `.github/workflows/release.yml:37-45` runs `GOWORK=off make release-final-check` before release creation.
- `.github/workflows/release.yml:71-109` creates/updates and verifies a GitHub release.
- `.github/workflows/release-auto-patch.yml:44-122` resolves the next patch tag and runs `GOWORK=off make release-final-check` before auto-patch release.
- `.github/workflows/goal-gates.yml:27-47` runs build, optional lint, tests, and an optional evidence check.
- `.github/workflows/worktree-guard.yml:24-29` blocks PR head refs named main/master.
- `.github/workflows/adoption-check.yml:20-25` skips source-repo adoption and otherwise runs `GOWORK=off make adoption-check`.

**Gaps**

- `goal-gates.yml` does not consistently export `GOWORK=off`, treats lint as optional, and does not hard-fail missing/undefined evidence checks.
- `worktree-guard.yml` blocks only PR head refs and does not run the repository governance/worktree target on push or release paths.
- `adoption-check.yml` skips the source repository, leaving local source adoption semantics dependent on other gates.
- `release-auto-patch.yml` runs `release-final-check`, but the auto-tag path should make explicit whether governance, remote evidence, release preflight, and release artifact verification run before tag/release mutation.
- The version bump target is not documented in the acceptance docs as a proven `v1.0.1` → `v1.0.2` release path; remote tags still need confirmation before choosing the final patch version.

**Safe patches for the owning CI/release lane**

1. Harden `goal-gates.yml` to use `GOWORK=off`, fail missing lint tooling or install it consistently, and make evidence checks required.
2. Add a workflow job that runs the Makefile governance/worktree guard on PR and push, not only branch-name validation.
3. Replace the source-repo adoption skip with a source-appropriate adoption verification or document the delegated gate explicitly in acceptance evidence.
4. Make `release-auto-patch.yml` run or visibly depend on `release-preflight`, governance, and evidence verification before any tag/release mutation.
5. Record selected release version and tag-resolution evidence in release docs before merge to main.

### 3. Coverage and score gates

**Observed evidence**

- `/home/xlib-standard/.worktree/workspaces/xlib-standard/Makefile:257-264` defines `score` and `score-check` using `goalcli score --min 9.8`.
- Score gate passed during this audit, but it is a governance/release-quality score, not an executable coverage threshold.
- A coverage run produced a partial total of `84.8%` statements, then failed in `scripts` with `tar: .: file changed as we read it` during `TestRenderTemplateIncludesGoalcliControlPlane`.
- `pkg/templatex/metrics.go` functions `IncCounter`, `ObserveHistogram`, and `SetGauge` appeared at `0.0%` in the partial coverage function report.

**Gaps**

- There is no explicit `coverage` or `coverage-check` Makefile target that enforces a numeric threshold separate from the score gate.
- CI/release evidence can pass score while coverage remains below a production threshold or flaky under `-coverprofile`.
- The `scripts` coverage flake needs isolation because regular `go test ./...` passed immediately before the coverage run.
- Coverage artifacts are not yet tied into acceptance docs as reproducible release evidence.

**Safe patches for the owning coverage/test lane**

1. Add `coverage` and `coverage-check` targets that write a stable coverage artifact and enforce the agreed threshold.
2. Wire `coverage-check` into `ci` or `release-check` once the threshold and flaky script test are stabilized.
3. Fix or serialize the `scripts` render-template test so `go test ./... -coverprofile=...` is deterministic.
4. Add focused coverage for low-coverage metrics helpers or explicitly justify them as adapter/no-op functions if excluded.
5. Record coverage artifact path, command, total percentage, and code SHA in `ACCEPTANCE.md` before release.

## Verification evidence

Commands run in `/home/xlib-standard/.worktree/workspaces/xlib-standard` unless noted.

| Check | Result | Evidence |
| --- | --- | --- |
| `GOWORK=off make vet` | PASS | `go vet ./...` completed successfully. |
| `GOWORK=off go test ./...` | PASS | All packages completed; slow package observed: `internal/tools/releasemanifest` about 49.5s. |
| `GOWORK=off go test ./... -coverprofile=/tmp/xlib-standard-worker3-cover.out` | FAIL | `scripts` failed in `TestRenderTemplateIncludesGoalcliControlPlane`; error: `tar: .: file changed as we read it`. Partial total coverage: `84.8%`. |
| `GOWORK=off go run ./cmd/goalcli score --min 9.8` | PASS | Score/gov/release quality threshold passed. |
| `GOWORK=off make docs-check` | PASS | `docs-check passed`. |
| `GOWORK=off make lint` | PASS | `0 issues.` |

## Required release evidence not run by worker-3

The following remain required before production acceptance, but were not run by this read-only audit lane because the shared code worktree had active uncommitted changes owned by other lanes and several gates are release/remote mutation adjacent:

- `GOWORK=off make fmt`
- `GOWORK=off make race`
- `GOWORK=off make boundary`
- `GOWORK=off make security`
- `GOWORK=off make contracts`
- `GOWORK=off make integration`
- `CHECK_STATUS=passed GOWORK=off make evidence`
- `GOWORK=off make release-check`
- `XLIB_CONTEXT=release_verify GOWORK=off make release-final-check`
- `XLIB_CONTEXT=release_verify GOWORK=off make release-preflight VERSION=<version>`
- Remote GitHub release, adoption, and governance artifact verification

## Stop condition

Worker-3 completed the assigned read-only audit/report lane, identified concrete files and commands, integrated required subagent findings, and documented safe patch recommendations without editing the shared code worktree.
