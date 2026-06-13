# transportx Traceability Matrix

- Module: transportx
- Spec-Version: v1.1.1
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

| Rule | Source | Verification | Error Code | Status |
| --- | --- | --- | --- | --- |
| BR-001 | SPEC §8 | Payload absent from logs/metrics/audit/receipt | `TX_REDACTION_FAILED` | Pending |
| BR-002 | SPEC §8 | Middleware order: redaction before logging | `TX_REDACTION_FAILED` | Pending |
| BR-003 | SPEC §8 | Control command audit + rollback token | `TX_AUDIT_MISSING` | Pending |
| BR-004 | SPEC §8 | Force-stop marks abandoned with receipt | receipt = `ABANDONED` | Pending |
| BR-005 | SPEC §8 | Mirror/canary preserve idempotency | `TX_MIRROR_IDEMPOTENCY_VIOLATION` | Pending |
| BR-006 | SPEC §8 | Adapter fields in namespaced extensions | `TX_SCHEMA_INCOMPATIBLE` | Pending |
| BR-007 | SPEC §8 | Envelope id + idempotency key stable | `TX_IDEMPOTENCY_CONFLICT` | Pending |
| BR-008 | SPEC §8 | Monotonic clock + wall-clock skew guard | `TX_CLOCK_SKEW` | Pending |
| BR-009 | SPEC §8 | Authz failure: no secret/payload leak | `TX_AUTHZ_DENIED` | Pending |
| BR-010 | SPEC §8 | DLQ retains trace context | `TX_DLQ_INCOMPLETE` | Pending |
| BR-011 | SPEC §8 | Breaking change → major version bump | `TX_SCHEMA_INCOMPATIBLE` | Pending |
| BR-012 | SPEC §8 | Release evidence: conformance + drift | CI gate TX-GATE-009 | Pending |
| BR-013 | SPEC §8 | Order/fill/risk/settlement ≠ REALTIME | `TX_QOS_VIOLATION` | Pending |
| BR-014 | SPEC §8 | COMMAND_IDEMPOTENT requires key | `TX_QOS_VIOLATION` | Pending |
| BR-015 | SPEC §8 | Audit events not silently dropped | `TX_AUDIT_DROPPED` | Pending |
| BR-016 | SPEC §8 | REPLAY/DRY_RUN prevent real order | `TX_MODE_VIOLATION` | Pending |
| BR-017 | SPEC §8 | Retry class enforcement | `TX_RETRY_UNSAFE` | Pending |
| BR-018 | SPEC §8 | SECRET absent from all telemetry | `TX_REDACTION_FAILED` | Pending |

## NFR Traceability

| NFR | Category | Verification | Status |
| --- | --- | --- | --- |
| NFR-001 | Security | TC-024: Data classification redaction | Pending |
| NFR-002 | Security | TC-014: Middleware redaction order | Pending |
| NFR-003 | Security | TC-008: Authz denial no leak | Pending |
| NFR-004 | Security | TC-021: Execution mode gate | Pending |
| NFR-005 | Observability | Bounded cardinality review | Pending |
| NFR-006 | Observability | TC-007: Identity trace fields | Pending |
| NFR-007 | Performance | Benchmark: envelope validation ≤ 1 ms | Pending |
| NFR-008 | Performance | Benchmark: middleware ≤ 2 ms | Pending |
| NFR-009 | Performance | Benchmark: JSON codec ≤ 5 ms | Pending |
| NFR-010 | Reliability | BR-015: Audit drop alert | Pending |
| NFR-011 | Reliability | TC-013: DLQ trace context | Pending |
| NFR-012 | Compatibility | TC-025: SchemaRegistry breaking change | Pending |

## Gate Traceability

| Gate | Covers | Evidence | Status |
| --- | --- | --- | --- |
| TX-GATE-001 | 23-section spec structure | `.github/ci/spec-lint.sh` | Pending |
| TX-GATE-002 | FR to AC/TC closure | `.github/ci/traceability-check.sh` | Pending |
| TX-GATE-003 | Foundation module count | `.github/ci/status-consistency-check.sh` | Pending |
| TX-GATE-004 | README/ARCHITECTURE/STATUS/module index drift | `.github/ci/spec-drift-guard.sh` | Pending |
| TX-GATE-005 | Envelope, Endpoint, Receipt conformance | conformance report | Pending |
| TX-GATE-006 | lifecycle, drain, force-stop conformance | conformance report | Pending |
| TX-GATE-007 | control-plane, authz, redaction-order conformance | conformance report | Pending |
| TX-GATE-008 | v1.x compatibility | schema compatibility report | Pending |
| TX-GATE-009 | release evidence | tag, changelog, conformance, drift | Pending |
| TX-GATE-010 | QoS, Codec, Registry conformance | conformance report | Pending |
| TX-GATE-011 | Execution Mode, Outbox/Inbox, Audit Plane conformance | conformance report | Pending |
| TX-GATE-012 | Data Classification, SchemaRegistry conformance | conformance report | Pending |

## Coverage Notes

- 25 FRs, 18 BRs (with error codes), 12 NFRs, 25 ACs (with verification commands), 25 TCs (with commands), 12 CI gates.
- All FR → AC → TC chains closed. All BRs have explicit violation error codes.
- `transportx` is a Foundation transport-contract module, not a broker implementation.
- CI gates TX-GATE-001 through TX-GATE-004 are repository-documentation gates.
- CI gates TX-GATE-005 through TX-GATE-012 must be satisfied by the implementation repository before release.
