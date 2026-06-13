# transportx Traceability Matrix

- Module: transportx
- Spec-Version: v1.0.1
- Last-Updated: 2026-06-14
- Source: `module/transportx/SPEC.md`

## Functional Traceability

| Requirement | Type | Source | Acceptance Criteria | Test Case | Status |
| --- | --- | --- | --- | --- | --- |
| FR-001 | Functional | SPEC §7 | AC-001 | TC-001 | Pending |
| FR-002 | Functional | SPEC §7 | AC-002 | TC-002 | Pending |
| FR-003 | Functional | SPEC §7 | AC-003 | TC-003 | Pending |
| FR-004 | Functional | SPEC §7 | AC-004 | TC-004 | Pending |
| FR-005 | Functional | SPEC §7 | AC-005 | TC-005 | Pending |
| FR-006 | Functional | SPEC §7 | AC-006 | TC-006 | Pending |
| FR-007 | Functional | SPEC §7 | AC-007 | TC-007 | Pending |
| FR-008 | Functional | SPEC §7 | AC-008 | TC-008 | Pending |
| FR-009 | Functional | SPEC §7 | AC-009 | TC-009 | Pending |
| FR-010 | Functional | SPEC §7 | AC-010 | TC-010 | Pending |
| FR-011 | Functional | SPEC §7 | AC-011 | TC-011 | Pending |
| FR-012 | Functional | SPEC §7 | AC-012 | TC-012 | Pending |
| FR-013 | Functional | SPEC §7 | AC-013 | TC-013 | Pending |
| FR-014 | Functional | SPEC §7 | AC-014 | TC-014 | Pending |
| FR-015 | Functional | SPEC §7 | AC-015 | TC-015 | Pending |
| FR-016 | Functional | SPEC §7 | AC-016 | TC-016 | Pending |

## Gate Traceability

| Gate | Covers | Evidence | Status |
| --- | --- | --- | --- |
| TX-GATE-001 | 23-section spec structure | `.github/ci/spec-lint.sh` | Pending |
| TX-GATE-002 | FR to AC/TC closure | `.github/ci/traceability-check.sh` | Pending |
| TX-GATE-003 | Foundation module count | `.github/ci/status-consistency-check.sh` | Pending |
| TX-GATE-004 | README, ARCHITECTURE, STATUS and module index drift | `.github/ci/spec-drift-guard.sh` | Pending |
| TX-GATE-005 | Envelope, Endpoint and Receipt conformance | transportx conformance report | Pending |
| TX-GATE-006 | lifecycle, drain and force-stop conformance | transportx conformance report | Pending |
| TX-GATE-007 | control-plane, authz and redaction-order conformance | transportx conformance report | Pending |
| TX-GATE-008 | v1.x compatibility | schema compatibility report | Pending |
| TX-GATE-009 | release evidence | tag, changelog, conformance output and drift output | Pending |

## Coverage Notes

- `transportx` is a Foundation transport-contract module, not a broker implementation.
- CI gates TX-GATE-001 through TX-GATE-004 are repository-documentation gates.
- CI gates TX-GATE-005 through TX-GATE-009 must be satisfied by the implementation repository before release.
