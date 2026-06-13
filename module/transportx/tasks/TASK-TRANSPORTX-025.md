# TASK-TRANSPORTX-025: CI Gates + Release Evidence

- **Module**: transportx
- **Spec**: `module/transportx/SPEC.md` v1.1.1
- **FRs**: FR-016
- **ACs**: AC-016
- **TCs**: TC-016
- **Phase**: CI + Release (Phase 6)
- **Priority**: P2
- **Dependencies**: TASK-024 (Conformance Suite)
- **Status**: Pending

## Scope

Configure all 12 CI gates (TX-GATE-001 through TX-GATE-012). Ensure spec-lint.sh, traceability-check.sh, status-consistency-check.sh, spec-drift-guard.sh include transportx. Generate release evidence: changelog, tag, conformance report, drift output. Publish v1.1.1 tag.

## Non-Scope

Does NOT implement CI infrastructure for the documentation repo (TX-GATE-001~004 already configured). Implements only implementation-repo conformance gates. Does NOT implement broker clients, storage drivers, or CI/CD platform infrastructure beyond transportx conformance gates.

## Actions

- [ ] TX-GATE-001~004: documentation CI scripts include transportx (already configured in ZoneCNH/ZoneCNH)
- [ ] TX-GATE-005~012: implementation repo CI runs conformance suite
- [ ] Release tag: `v1.1.1`
- [ ] Changelog: FR/BR/NFR additions + scoring fixes
- [ ] Conformance report: 25 TCs pass + NFR verification evidence
- [ ] Drift check: no breaking schema drift
- [ ] Release notes reference all evidence artifacts

## Files (implementation repo)

- `.github/workflows/transportx-conformance.yml` — Conformance CI workflow
- `docs/release/v1.1.1.md` — Release notes
- `docs/conformance/v1.1.1-report.md` — Conformance report
