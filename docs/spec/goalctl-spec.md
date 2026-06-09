# goalctl v1 Specification

Spec ID: `SPEC-goalctl-v1`
Owner: Goal System
Version: v1
Status: Draft for implementation
Quantified target: `goalctl` validates at least 95% trace coverage before a Done/Verified claim is accepted.

## 1. Purpose and authority

`goalctl` is a repository-local command surface for validating the Goal system without redefining it. The command reads authoritative docs and committed Registry files, reports drift, and emits deterministic machine-readable results.

Authority order:
1. `docs/goal/00-authority-map.md`
2. `docs/goal/02-goal-standard.md`
3. `docs/goal/03-pipeline.md`
4. `docs/goal/04-gates.md`
5. `docs/goal/13-runtime-engine.md`
6. `docs/goal/15-registry.md`
7. `.config/goal/README.md`
8. `.config/goal/schema/rules.yaml`
9. `docs/goal/20-metrics-evidence.md`
10. `docs/goal/24-standard-unification-analysis.md`

Reference consistency rule: every source path above must exist; projections in this spec are invalid if they conflict with the source map. This document does not edit `docs/goal`.

## 2. Commands

All commands support `--repo-root <path>` and `--json`.

- `goalctl status` summarizes Registry health, Pipeline state, Gate state, and evidence readiness.
- `goalctl validate` checks source references, Registry shape, Matrix edges, Gate/Pipeline semantics, and evidence links.
- `goalctl registry` validates the six-file Registry boundary.
- `goalctl matrix` checks trace links and renders Goal → Spec → Requirement → AC → Task → Prompt → Code → Test → Evidence.
- `goalctl gate` evaluates G0, G1, G2, G3, G4, G5, G6, G7, G8, G9, G10, G11.
- `goalctl pipeline` validates `pipeline_state`, `current_phase`, `phase_status`, and `workflow_step`.
- `goalctl evidence` checks `evidence_id`, `acceptance_criteria_id`, `test_id`, `task_id`, `spec_id`, `goal_id`, status, artifact path, command/log/result proof, risk note, rollback note, and reproducibility.
- `goalctl doctor` prints local remediation guidance.
- `goalctl report acceptance` emits an acceptance report with command, timestamp, source input, result, errors, warnings, and evidence references.

Unknown commands return non-zero and still use the JSON error envelope when `--json` is supplied.

## 3. Data contracts

Registry boundary: only goals.yaml, tasks.yaml, issues.yaml, releases.yaml, risks.yaml, and decisions.yaml are committed Registry authority under `.config/goal/registry/`. Matrix, Gate, Pipeline, Evidence, Prompt, cache, log, temp, lock, private, and sidecar files are not Registry authority. Committed config and evidence must reject credentials, credential keys, account IDs, private endpoints, trading config, and local personal paths.

Canonical aliases: use `goal_id` over `id`/`goalId`, `title` over `name`, `objective` over `north_star`, and `success_metrics` over `success_criteria` unless reading legacy inputs. Runtime state terms are distinct: `status` is record lifecycle, `pipeline_state` is global pipeline lifecycle, `current_phase` is active phase, `phase_status` is phase lifecycle, and `workflow_step` is a step within a phase.

Matrix edge fields: `source_id`, `target_id`, `relation`, `status`, `evidence_id`, `gate_id`, `owner`, `updated_at`. Legal statuses include Unmapped, Mapped, Linked, Verified, Dropped, Drifted, Stale, Blocked, and Changed.

Gate results: PASS, FAIL, PASS_WITH_RISK, BLOCKED. `WAIVED` is not a final compliant result; suggest PASS_WITH_RISK or BLOCKED.

JSON output shape: `{ "result": "pass|fail|warn", "errors": [], "warnings": [], "checks": [], "summary": {} }`. Every failed check includes `code`, `severity`, `message`, `source`, `expected`, `actual`, and `remediation` when known.

## 4. Error codes

- `GOALCTL-SSOT-001`: spec projection conflicts with authoritative source.
- `GOALCTL-REF-001`: source path or referenced line is missing or stale.
- `GOALCTL-ID-001`: identifier alias or format is invalid.
- `GOALCTL-REG-001`: Registry boundary or required file is invalid.
- `GOALCTL-MATRIX-001`: Matrix field, relation, status, or 95% coverage rule fails.
- `GOALCTL-GATE-001`: Gate result, ordering, or G2 completeness rule fails.
- `GOALCTL-PIPE-001`: Pipeline field semantics are missing or conflated.
- `GOALCTL-EVID-001`: evidence is missing for a Done/Verified claim.
- `GOALCTL-SECRET-001`: prohibited secret or local-only data appears in committed config/evidence.

## 5. Verification plan

Required local verification before implementation claims:
- `bash docs/goal/tools/lint-goal.sh docs/spec/goalctl-spec.md`
- `bash docs/goal/tools/self-test.sh`
- `python3 docs/goal/tools/goal-validate.py --root . --mode audit --format json`
- `python3 docs/goal/tools/rule-drift-check.py --root . --quiet`
- custom verifier for source references, command coverage, error codes, REQ/AC coverage, gates, traceability, and one-file scope.

## 6. Requirements and Acceptance Criteria / 验收标准

This criteria block covers normal, edge.case, 边界, 异常, and 错误处理 behavior.

- `REQ-SPEC-goalctl-v1-001`: Source map and authority hierarchy are validated. AC: `AC-REQ-SPEC-goalctl-v1-001-001` valid sources pass; `AC-REQ-SPEC-goalctl-v1-001-002` missing/stale sources emit `GOALCTL-REF-001`; `AC-REQ-SPEC-goalctl-v1-001-003` projection-only enums emit `GOALCTL-SSOT-001`.
- `REQ-SPEC-goalctl-v1-002`: CLI surface is complete and deterministic. AC: `AC-REQ-SPEC-goalctl-v1-002-001` help lists every command; `AC-REQ-SPEC-goalctl-v1-002-002` all commands support `--repo-root` and `--json`; `AC-REQ-SPEC-goalctl-v1-002-003` unknown commands return JSON errors.
- `REQ-SPEC-goalctl-v1-003`: `.config/goal` boundary is enforced. AC: `AC-REQ-SPEC-goalctl-v1-003-001` sidecars are rejected as Registry; `AC-REQ-SPEC-goalctl-v1-003-002` secrets/local data emit `GOALCTL-SECRET-001`; `AC-REQ-SPEC-goalctl-v1-003-003` cache/log/temp/lock files are not authority.
- `REQ-SPEC-goalctl-v1-004`: Pipeline and Gate semantics are separate. AC: `AC-REQ-SPEC-goalctl-v1-004-001` missing state fields emit `GOALCTL-PIPE-001`; `AC-REQ-SPEC-goalctl-v1-004-002` conflated `workflow_step`/`pipeline_state` emits `GOALCTL-PIPE-001`; `AC-REQ-SPEC-goalctl-v1-004-003` final `WAIVED` emits `GOALCTL-GATE-001`; `AC-REQ-SPEC-goalctl-v1-004-004` G2 checks completeness, testability, normal/error/boundary/security/performance/non-goal coverage.
- `REQ-SPEC-goalctl-v1-005`: Registry, Matrix, and Evidence checks are complete. AC: `AC-REQ-SPEC-goalctl-v1-005-001` six YAML files are required and match `.config/goal/schema/rules.yaml`; `AC-REQ-SPEC-goalctl-v1-005-002` Matrix validates fields/relation/status/evidence/owner/time and 95% coverage; `AC-REQ-SPEC-goalctl-v1-005-003` Evidence validates Evidence ID, Acceptance Criteria ID, Test ID, Task ID, Spec ID, Goal ID, status, reproducibility, command/log/result proof, risk note, rollback note, and artifact path; `AC-REQ-SPEC-goalctl-v1-005-004` Done/Verified without evidence emits `GOALCTL-EVID-001`.
- `REQ-SPEC-goalctl-v1-006`: JSON/error contract is stable. AC: `AC-REQ-SPEC-goalctl-v1-006-001` top-level output matches Section 3; `AC-REQ-SPEC-goalctl-v1-006-002` failed checks include required fields; `AC-REQ-SPEC-goalctl-v1-006-003` repeated invalid input produces the same code and exit status.
- `REQ-SPEC-goalctl-v1-007`: Traceability reporting is explicit. AC: `AC-REQ-SPEC-goalctl-v1-007-001` trace renders the full chain; `AC-REQ-SPEC-goalctl-v1-007-002` missing/stale/drifted/blocked/changed links are distinct; `AC-REQ-SPEC-goalctl-v1-007-003` acceptance reports include input, result, errors, warnings, and evidence references.
- `REQ-SPEC-goalctl-v1-008`: Worker output is scoped and verified. AC: `AC-REQ-SPEC-goalctl-v1-008-001` only `docs/spec/goalctl-spec.md` changes; `AC-REQ-SPEC-goalctl-v1-008-002` lint exits 0; `AC-REQ-SPEC-goalctl-v1-008-003` audit validator exits 0; `AC-REQ-SPEC-goalctl-v1-008-004` custom verifier confirms required references, commands, errors, states, gates, trace chain, and criteria terms.

## 7. Worker-3 review checklist

This section is a non-authoritative review addendum. If it conflicts with `docs/goal/` or `.config/goal/schema/rules.yaml`, the source documents win and this spec must be corrected.

Acceptance Criteria for final review:

- `AC-W3-REF`: every normative source file in Section 1 exists; any future `path:line` references must resolve to existing lines before merge.
- `AC-W3-REG`: Registry files are exactly `goals.yaml`, `tasks.yaml`, `issues.yaml`, `releases.yaml`, `risks.yaml`, and `decisions.yaml`; stale files such as `specs.yaml`, `features.yaml`, `agents.yaml`, or `maturity.yaml` are invalid as Registry authority.
- `AC-W3-EVIDENCE`: Evidence checks include Acceptance Criteria ID and Spec ID in addition to Evidence/Test/Task/Goal IDs, status, commands/logs/results, limitations, risks, and rollback.
- `AC-W3-SCOPE`: `docs/goal/` remains unchanged; this worker review only edits `docs/spec/goalctl-spec.md`.
- `AC-W3-VERIFY`: completion evidence includes PASS/FAIL output for lint, reference resolution, Registry consistency, typecheck/equivalent, regression checks, end-to-end gate/matrix checks, and whitespace checks.

Edge-case and error-handling rules:

- Missing or stale source files emit `GOALCTL-REF-001` and block acceptance.
- Registry drift from `.config/goal/schema/rules.yaml` emits `GOALCTL-REG-001` and block acceptance.
- Evidence that omits Acceptance Criteria ID or Spec ID emits `GOALCTL-EVID-001` and blocks Done/Verified claims.
- Any `docs/goal/` diff during this review is a scope violation and must be reverted before reporting completion.
