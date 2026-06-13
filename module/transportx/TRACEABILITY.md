# transportx Traceability Matrix

- Module: transportx
- Spec-Version: v1.1.0
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
| FR-017 | Functional | SPEC §7 | AC-017 | TC-017 | Pending |
| FR-018 | Functional | SPEC §7 | AC-018 | TC-018 | Pending |
| FR-019 | Functional | SPEC §7 | AC-019 | TC-019 | Pending |
| FR-020 | Functional | SPEC §7 | AC-020 | TC-020 | Pending |
| FR-021 | Functional | SPEC §7 | AC-021 | TC-021 | Pending |
| FR-022 | Functional | SPEC §7 | AC-022 | TC-022 | Pending |
| FR-023 | Functional | SPEC §7 | AC-023 | TC-023 | Pending |
| FR-024 | Functional | SPEC §7 | AC-024 | TC-024 | Pending |
| FR-025 | Functional | SPEC §7 | AC-025 | TC-025 | Pending |

## Business Rule Traceability

| Rule | Source | Verification | Status |
| --- | --- | --- | --- |
| BR-001 | SPEC §8 | Envelope payload absent from logs/metrics/audit/receipt | Pending |
| BR-002 | SPEC §8 | Middleware order: redaction before logging/tracing | Pending |
| BR-003 | SPEC §8 | Control command audit evidence and rollback token | Pending |
| BR-004 | SPEC §8 | Force-stop marks work abandoned with receipt | Pending |
| BR-005 | SPEC §8 | Mirror/canary preserve idempotency semantics | Pending |
| BR-006 | SPEC §8 | Adapter-specific fields in namespaced extension blocks | Pending |
| BR-007 | SPEC §8 | Envelope id and idempotency key stable across retries | Pending |
| BR-008 | SPEC §8 | Deadline uses monotonic clock + wall-clock skew guard | Pending |
| BR-009 | SPEC §8 | Authz failure exposes no endpoint secrets or payload | Pending |
| BR-010 | SPEC §8 | Dead-letter retains trace context and redacted metadata | Pending |
| BR-011 | SPEC §8 | Breaking schema change requires major version bump | Pending |
| BR-012 | SPEC §8 | Release evidence includes conformance + drift output | Pending |
| BR-013 | SPEC §8 | Order/fill/risk/settlement must not use REALTIME_BEST_EFFORT | Pending |
| BR-014 | SPEC §8 | COMMAND_IDEMPOTENT without key rejected before dispatch | Pending |
| BR-015 | SPEC §8 | Audit events must not be silently dropped | Pending |
| BR-016 | SPEC §8 | REPLAY/DRY_RUN prevent real order + external side effects | Pending |
| BR-017 | SPEC §8 | READ_ONLY auto-retry; IDEMPOTENT requires key; UNSAFE forbidden auto-retry | Pending |
| BR-018 | SPEC §8 | SECRET data absent from all telemetry, audit and receipt | Pending |

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
| TX-GATE-010 | QoS, Codec and Registry conformance | transportx conformance report | Pending |
| TX-GATE-011 | Execution Mode, Outbox/Inbox and Audit Plane conformance | transportx conformance report | Pending |
| TX-GATE-012 | Data Classification redaction and SchemaRegistry compatibility | transportx conformance report | Pending |

## Coverage Notes

- `transportx` is a Foundation transport-contract module, not a broker implementation.
- 25 FRs, 18 BRs, 25 ACs, 25 TCs, 12 CI gates.
- CI gates TX-GATE-001 through TX-GATE-004 are repository-documentation gates.
- CI gates TX-GATE-005 through TX-GATE-012 must be satisfied by the implementation repository before release.
